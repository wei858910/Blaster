// Fill out your copyright notice in the Description page of Project Settings.


#include "MultiplayerSessionSubsystem.h"

#include "OnlineSessionSettings.h"
#include "OnlineSubsystem.h"
#include "Online/OnlineSessionNames.h"

UMultiplayerSessionSubsystem::UMultiplayerSessionSubsystem():
	CreateSessionCompleteDelegate(FOnCreateSessionCompleteDelegate::CreateUObject(this, &ThisClass::OnCreateSessionComplete)),
	FindSessionsCompleteDelegate(FOnFindSessionsCompleteDelegate::CreateUObject(this, &ThisClass::OnFindSessionsComplete)),
	JoinSessionCompleteDelegate(FOnJoinSessionCompleteDelegate::CreateUObject(this, &ThisClass::OnJoinSessionComplete)),
	DestroySessionCompleteDelegate(FOnDestroySessionCompleteDelegate::CreateUObject(this, &ThisClass::OnDestroySessionComplete)),
	StartSessionCompleteDelegate(FOnStartSessionCompleteDelegate::CreateUObject(this, &ThisClass::OnStartSessionComplete))
{
	// 获取默认的在线子系统实例指针。在线子系统负责管理游戏的网络相关功能，
	// 不同的平台（如 Steam、Epic Games 等）有不同的实现。
	if (const IOnlineSubsystem* Subsystem = IOnlineSubsystem::Get())
	{
		// 若成功获取在线子系统实例，则从该子系统中获取会话接口指针。
		// 会话接口提供了创建、查找、加入和销毁游戏会话等功能。
		SessionInterface = Subsystem->GetSessionInterface();
	}
}

/**
 * @brief 创建一个新的游戏会话。
 * 
 * 若存在同名会话，会先销毁该会话，再创建新会话。设置会话的相关参数，
 * 并尝试发起会话创建请求。
 * 
 * @param NumPublicConnections 会话允许的最大公共连接数。
 * @param MatchType 会话的匹配类型，用于区分不同类型的游戏模式。
 */
void UMultiplayerSessionSubsystem::CreateSession(const int32 NumPublicConnections, const FString& MatchType)
{
	// 检查会话接口是否有效，若无效则直接返回，避免后续操作出错
	if (!SessionInterface.IsValid()) return;

	// 检查是否已经存在名为 NAME_GameSession 的会话
	if (SessionInterface->GetNamedSession(NAME_GameSession))
	{
		bCreateSessionOnDestroy = true;
		LastNumPublicConnections = NumPublicConnections;
		LastMatchType = MatchType;
		
		DestroySession();
		return;
	}

	// 绑定会话创建完成时的委托，当会话创建操作完成后会调用 OnCreateSessionComplete 函数
	CreateSessionCompleteDelegateHandle = SessionInterface->AddOnCreateSessionCompleteDelegate_Handle(CreateSessionCompleteDelegate);

	// 创建新的会话设置对象，用于配置新会话的各项参数
	LastSessionSettings = MakeShareable(new FOnlineSessionSettings());
	// 根据在线子系统名称判断是否为局域网匹配，若子系统名为 "NULL" 则为局域网匹配
	LastSessionSettings->bIsLANMatch = IOnlineSubsystem::Get()->GetSubsystemName() == "NULL" ? true : false;
	// 设置会话允许的最大公共连接数
	LastSessionSettings->NumPublicConnections = NumPublicConnections;
	// 允许玩家在游戏进行中加入会话
	LastSessionSettings->bAllowJoinInProgress = true;
	// 允许玩家通过在线状态加入会话
	LastSessionSettings->bAllowJoinViaPresence = true;
	// 允许将会话信息进行广告宣传，让其他玩家可以发现该会话
	LastSessionSettings->bShouldAdvertise = true;
	// 启用在线状态功能，方便其他玩家通过在线状态了解会话信息
	LastSessionSettings->bUsesPresence = true;
	// 设置会话的匹配类型，并通过在线服务和网络延迟信息进行广告宣传
	LastSessionSettings->Set(FName("MatchType"), MatchType, EOnlineDataAdvertisementType::ViaOnlineServiceAndPing);
	// 设置会话的唯一构建 ID 为 1。该 ID 用于标识游戏的特定构建版本，
	// 在线子系统会根据此 ID 确保加入会话的玩家使用相同的游戏构建版本，避免兼容性问题。
	LastSessionSettings->BuildUniqueId = 1;
	// 若当前在线子系统支持游戏大厅功能，则使用游戏大厅来管理会话。
	// 游戏大厅能提供更丰富的交互功能，如玩家列表管理、聊天功能等，
	// 设置为 true 可让游戏在支持的情况下优先使用大厅机制。
	LastSessionSettings->bUseLobbiesIfAvailable = true;
	// 获取世界中的第一个本地玩家，后续创建会话需要使用该玩家的唯一网络 ID
	if (const ULocalPlayer* LocalPlayer = GetWorld()->GetFirstLocalPlayerFromController())
	{
		// 尝试使用本地玩家的唯一网络 ID、会话名称和会话设置创建新会话
		if (!SessionInterface->CreateSession(*LocalPlayer->GetPreferredUniqueNetId(), NAME_GameSession, *LastSessionSettings))
		{
			// 如果会话创建失败，清除之前绑定的会话创建完成委托
			SessionInterface->ClearOnCreateSessionCompleteDelegate_Handle(CreateSessionCompleteDelegateHandle);
			MultiplayerOnCreateSessionComplete.Broadcast(false);
		}
	}
}

/**
 * @brief 查找可用的多人游戏会话。
 * 
 * 此函数会依据指定的条件尝试查找现有的多人游戏会话。
 * 首先检查会话接口是否有效，若有效则绑定一个委托来处理会话查找完成事件，
 * 配置查找参数并发起查找操作。
 * 
 * @param MaxSearchResults 最大查找结果数量。
 */
void UMultiplayerSessionSubsystem::FindSessions(int32 MaxSearchResults)
{
	// 检查会话接口是否有效，若无效则直接返回，避免后续操作出错
	if (!SessionInterface.IsValid()) return;

	// 绑定会话查找完成时的委托，当会话查找操作完成后会调用 OnFindSessionsComplete 函数
	FindSessionsCompleteDelegateHandle = SessionInterface->AddOnFindSessionsCompleteDelegate_Handle(FindSessionsCompleteDelegate);
	
	// 创建一个新的会话搜索对象，用于存储会话查找的相关参数
	LastSessionSearch = MakeShareable(new FOnlineSessionSearch());
	
	// 设置最大查找结果数量
	LastSessionSearch->MaxSearchResults = MaxSearchResults;
	
	// 根据在线子系统名称判断是否为局域网查询，若子系统名为 "NULL" 则为局域网查询
	LastSessionSearch->bIsLanQuery = IOnlineSubsystem::Get()->GetSubsystemName() == "NULL" ? true : false;
	
	// 设置查询条件，搜索具备在线状态的会话
	// 注意："PRESENCESEARCH" 已被弃用，后续需要替换为新的搜索键
	LastSessionSearch->QuerySettings.Set(FName(TEXT("PRESENCESEARCH")), true, EOnlineComparisonOp::Equals);
	
	// 获取世界中的第一个本地玩家
	if (const ULocalPlayer* LocalPlayer = GetWorld()->GetFirstLocalPlayerFromController())
	{
		// 尝试使用本地玩家的唯一网络 ID 和会话搜索参数进行会话查找
		if (!SessionInterface->FindSessions(*LocalPlayer->GetPreferredUniqueNetId(), LastSessionSearch.ToSharedRef()))
		{
			// 如果会话查找失败，清除之前绑定的会话查找完成委托
			SessionInterface->ClearOnFindSessionsCompleteDelegate_Handle(FindSessionsCompleteDelegateHandle);
			// 广播自定义的会话查找完成事件，传递空的会话搜索结果数组和查找失败标志
			MultiplayerOnFindSessionsComplete.Broadcast(TArray<FOnlineSessionSearchResult>{}, false);
		}
	}
}


/**
 * @brief 尝试加入指定的多人游戏会话。
 * 
 * 此函数会检查会话接口的有效性，若有效则绑定加入会话完成的委托，
 * 并使用本地玩家的唯一网络 ID 尝试加入指定的会话。
 * 根据操作结果，会广播自定义的加入会话完成事件。
 * 
 * @param SessionResult 要加入的游戏会话的搜索结果，包含会话的相关信息。
 */
void UMultiplayerSessionSubsystem::JoinSession(const FOnlineSessionSearchResult& SessionResult)
{
	// 检查会话接口是否有效，若无效则广播未知错误并返回，避免后续操作出错
	if (!SessionInterface.IsValid())
	{
		// 广播自定义的加入会话完成事件，传递未知错误标志
		MultiplayerOnJoinSessionComplete.Broadcast(EOnJoinSessionCompleteResult::UnknownError);
		return;
	}

	// 绑定加入会话完成时的委托，当加入会话操作完成后会调用 OnJoinSessionComplete 函数
	JoinSessionCompleteDelegateHandle = SessionInterface->AddOnJoinSessionCompleteDelegate_Handle(JoinSessionCompleteDelegate);

	// 获取世界中的第一个本地玩家
	if (const ULocalPlayer* LocalPlayer = GetWorld()->GetFirstLocalPlayerFromController())
	{
		// 尝试使用本地玩家的唯一网络 ID、会话名称和会话搜索结果加入指定会话
		if (!SessionInterface->JoinSession(*LocalPlayer->GetPreferredUniqueNetId(), NAME_GameSession, SessionResult))
		{
			// 如果加入会话失败，清除之前绑定的加入会话完成委托
			SessionInterface->ClearOnJoinSessionCompleteDelegate_Handle(JoinSessionCompleteDelegateHandle);
			// 广播自定义的加入会话完成事件，传递未知错误标志
			MultiplayerOnJoinSessionComplete.Broadcast(EOnJoinSessionCompleteResult::UnknownError);
		}
	}
}


/**
 * @brief 尝试销毁名为 NAME_GameSession 的多人游戏会话。
 * 
 * 此函数首先检查会话接口是否有效，若无效则直接广播会话销毁失败的事件。
 * 若会话接口有效，则绑定销毁会话完成的委托，然后尝试销毁指定名称的会话。
 * 根据操作结果，会广播自定义的销毁会话完成事件。
 */
void UMultiplayerSessionSubsystem::DestroySession()
{
	// 检查会话接口是否有效，若无效则广播会话销毁失败的事件并返回
	if (!SessionInterface.IsValid())
	{
		// 广播自定义的销毁会话完成事件，传递销毁失败标志
		MultiplayerOnDestroySessionComplete.Broadcast(false);
		return;
	}
	// 绑定销毁会话完成时的委托，当销毁会话操作完成后会调用 OnDestroySessionComplete 函数
	DestroySessionCompleteDelegateHandle = SessionInterface->AddOnDestroySessionCompleteDelegate_Handle(DestroySessionCompleteDelegate);
	// 获取世界中的第一个本地玩家
	if (const ULocalPlayer* LocalPlayer = GetWorld()->GetFirstLocalPlayerFromController())
	{
		// 尝试销毁名为 NAME_GameSession 的会话
		if (!SessionInterface->DestroySession(NAME_GameSession))
		{
			// 如果销毁会话失败，清除之前绑定的销毁会话完成委托
			SessionInterface->ClearOnDestroySessionCompleteDelegate_Handle(DestroySessionCompleteDelegateHandle);
			// 广播自定义的销毁会话完成事件，传递销毁失败标志
			MultiplayerOnDestroySessionComplete.Broadcast(false);
		}
	}
}


void UMultiplayerSessionSubsystem::StartSession()
{
}

void UMultiplayerSessionSubsystem::OnCreateSessionComplete(FName SessionName, bool bWasSuccessful)
{
	// 检查会话接口是否有效。会话接口负责处理游戏会话的创建、查找、加入等操作。
	if (SessionInterface)
	{
		// 若会话接口有效，清除之前添加的会话创建完成委托句柄。
		// 这一步是为了避免在后续会话创建操作中重复触发委托，确保委托只在当前操作中生效。
		SessionInterface->ClearOnCreateSessionCompleteDelegate_Handle(CreateSessionCompleteDelegateHandle);
	}
	// 广播多人会话创建完成的事件，将会话创建操作的结果（成功或失败）传递给所有绑定的函数。
	// 其他模块可以通过绑定到 MultiplayerOnCreateSessionComplete 委托来监听会话创建完成事件。
	MultiplayerOnCreateSessionComplete.Broadcast(bWasSuccessful);
}

/**
 * @brief 处理会话查找完成的回调函数。
 * 
 * 当通过 `FindSessions` 函数发起的会话查找操作完成时，该函数会被调用。
 * 它会清除会话查找完成的委托句柄，根据查找结果的数量，广播自定义的会话查找完成事件。
 * 
 * @param bWasSuccessful 指示会话查找操作是否成功。`true` 表示查找操作正常完成，`false` 表示查找过程中出现错误。
 */
void UMultiplayerSessionSubsystem::OnFindSessionsComplete(bool bWasSuccessful)
{
	// 检查会话接口是否有效，若有效则清除之前添加的会话查找完成委托句柄
	// 这样做是为了避免该委托在后续的会话查找操作中被重复调用
	if (SessionInterface)
	{
		SessionInterface->ClearOnFindSessionsCompleteDelegate_Handle(FindSessionsCompleteDelegateHandle);
	}
	// 检查查找结果的数量是否小于等于 0，即是否没有找到任何会话
	if (LastSessionSearch->SearchResults.Num() <= 0)
	{
		// 若没有找到会话，广播自定义的会话查找完成事件
		// 传递空的会话搜索结果数组和查找失败标志（false）
		MultiplayerOnFindSessionsComplete.Broadcast(TArray<FOnlineSessionSearchResult>{}, false);
		return;
	}
	// 若找到了会话，广播自定义的会话查找完成事件
	// 传递实际的会话搜索结果数组和会话查找操作的成功状态
	MultiplayerOnFindSessionsComplete.Broadcast(LastSessionSearch->SearchResults, bWasSuccessful);
}


/**
 * @brief 处理加入会话完成的回调函数。
 * 
 * 当加入会话操作完成时，该函数会被调用。它会清除加入会话完成的委托句柄，
 * 并广播自定义的加入会话完成事件，将加入会话的结果传递出去。
 * 
 * @param SessionName 加入的会话名称。
 * @param Result 加入会话操作的结果枚举类型，指示加入操作是否成功以及具体的状态。
 */
void UMultiplayerSessionSubsystem::OnJoinSessionComplete(FName SessionName, EOnJoinSessionCompleteResult::Type Result)
{
	// 检查会话接口是否有效，若有效则清除之前添加的加入会话完成委托句柄
	// 避免该委托在后续的加入会话操作中被重复调用
	if (SessionInterface)
	{
		SessionInterface->ClearOnJoinSessionCompleteDelegate_Handle(JoinSessionCompleteDelegateHandle);
	}
	// 广播自定义的加入会话完成事件，将加入会话的结果传递给所有绑定的函数
	MultiplayerOnJoinSessionComplete.Broadcast(Result);
}


/**
 * @brief 处理会话销毁完成的回调函数。
 * 
 * 当会话销毁操作完成时，该函数会被调用。它会清除销毁会话完成的委托句柄，
 * 根据销毁操作的结果和 `bCreateSessionOnDestroy` 标志，决定是否创建新的会话，
 * 最后广播自定义的会话销毁完成事件。
 * 
 * @param SessionName 被销毁的会话名称。
 * @param bWasSuccessful 指示会话销毁操作是否成功。`true` 表示销毁成功，`false` 表示销毁失败。
 */
void UMultiplayerSessionSubsystem::OnDestroySessionComplete(FName SessionName, bool bWasSuccessful)
{
	// 检查会话接口是否有效，若有效则清除之前添加的销毁会话完成委托句柄
	// 避免该委托在后续的销毁会话操作中被重复调用
	if (SessionInterface)
	{
		SessionInterface->ClearOnDestroySessionCompleteDelegate_Handle(DestroySessionCompleteDelegateHandle);
	}
	// 检查会话是否销毁成功，并且 bCreateSessionOnDestroy 标志为 true
	// 若满足条件，则在销毁会话后创建一个新的会话
	if (bWasSuccessful && bCreateSessionOnDestroy)
	{
		// 重置 bCreateSessionOnDestroy 标志，避免重复创建会话
		bCreateSessionOnDestroy = false;
		// 使用上次创建会话时的公共连接数和匹配类型创建新的会话
		CreateSession(LastNumPublicConnections, LastMatchType);
	}
	// 广播自定义的会话销毁完成事件，将会话销毁操作的结果传递给所有绑定的函数
	MultiplayerOnDestroySessionComplete.Broadcast(bWasSuccessful);
}


void UMultiplayerSessionSubsystem::OnStartSessionComplete(FName SessionName, bool bWasSuccessful)
{
}
