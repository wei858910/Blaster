// Fill out your copyright notice in the Description page of Project Settings.


#include "MultiplayerSessionSubsystem.h"

#include "OnlineSessionSettings.h"
#include "OnlineSubsystem.h"

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
		// 如果存在同名会话，先销毁该会话，确保能创建新的会话
		SessionInterface->DestroySession(NAME_GameSession);
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

void UMultiplayerSessionSubsystem::FindSessions(int32 MaxSearchResults)
{
}

void UMultiplayerSessionSubsystem::JoinSession(const FOnlineSessionSearchResult& SessionResult)
{
}

void UMultiplayerSessionSubsystem::DestroySession()
{
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

void UMultiplayerSessionSubsystem::OnFindSessionsComplete(bool bWasSuccessful)
{
}

void UMultiplayerSessionSubsystem::OnJoinSessionComplete(FName SessionName, EOnJoinSessionCompleteResult::Type Result)
{
}

void UMultiplayerSessionSubsystem::OnDestroySessionComplete(FName SessionName, bool bWasSuccessful)
{
}

void UMultiplayerSessionSubsystem::OnStartSessionComplete(FName SessionName, bool bWasSuccessful)
{
}
