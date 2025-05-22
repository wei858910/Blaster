// Fill out your copyright notice in the Description page of Project Settings.


#include "Menu.h"

#include "MultiplayerSessionSubsystem.h"
#include "OnlineSessionSettings.h"
#include "Components/Button.h"

void UMenu::UMenuSetup(const int32 NumOfPublicConnections, const FString& MatchOfType)
{
	NumPublicConnections = NumOfPublicConnections;
	MatchType = MatchOfType;
	AddToViewport();
	SetVisibility(ESlateVisibility::Visible);
	SetIsFocusable(true);

	if (const UWorld* World = GetWorld())
	{
		// 获取当前世界中的第一个玩家控制器
		// 玩家控制器负责处理玩家输入并控制玩家角色
		if (APlayerController* PlayerController = World->GetFirstPlayerController())
		{
			// 创建一个仅用于 UI 输入的输入模式对象
			// 该模式下，输入主要用于与 UI 元素交互
			FInputModeUIOnly InputModeData;
			// 设置要聚焦的 UI 控件为当前菜单的 Widget
			// 确保输入事件能正确传递到菜单上
			InputModeData.SetWidgetToFocus(TakeWidget());
			// 设置鼠标锁定行为为不锁定
			// 即鼠标可以自由移动出视口范围
			InputModeData.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
			// 使得玩家输入切换到仅与 UI 交互的模式
			PlayerController->SetInputMode(InputModeData);
			// 显示鼠标光标可以方便玩家与菜单 UI 进行交互操作。
			PlayerController->SetShowMouseCursor(true);
		}
	}

	if (const UGameInstance* GameInstance = GetGameInstance())
	{
		MultiplayerSessionSubsystem = GameInstance->GetSubsystem<UMultiplayerSessionSubsystem>();
	}
	if (MultiplayerSessionSubsystem)
	{
		MultiplayerSessionSubsystem->MultiplayerOnCreateSessionComplete.AddDynamic(this, &UMenu::OnCreateSession);
		MultiplayerSessionSubsystem->MultiplayerOnFindSessionsComplete.AddUObject(this, &UMenu::OnFindSessions);
		MultiplayerSessionSubsystem->MultiplayerOnJoinSessionComplete.AddUObject(this, &UMenu::OnJoinSession);
		MultiplayerSessionSubsystem->MultiplayerOnDestroySessionComplete.AddDynamic(this, &UMenu::OnDestroySession);
		MultiplayerSessionSubsystem->MultiplayerOnStartSessionComplete.AddDynamic(this, &UMenu::OnStartSession);
	}
}

bool UMenu::Initialize()
{
	// 调用父类的 Initialize 函数，确保父类的初始化逻辑正常执行
	// 如果父类的初始化失败，那么当前类的初始化也会失败
	if (!Super::Initialize())
	{
		// 父类初始化失败，返回 false 表示当前类初始化失败
		return false;
	}
	// 绑定按钮点击事件
	if (HostButton)
	{
		HostButton->OnClicked.AddDynamic(this, &UMenu::HostButtonClicked);
	}

	if (JoinButton)
	{
		JoinButton->OnClicked.AddDynamic(this, &UMenu::JoinButtonClicked);
	}

	// 父类初始化成功，返回 true 表示当前类初始化成功
	return true;
}

/**
 * @brief 当菜单对象被销毁时调用的方法。
 * 
 * 此方法在菜单对象生命周期结束、即将被销毁时触发。
 * 首先调用 `MenuTearDown` 方法移除菜单界面并恢复游戏输入模式，
 * 然后调用父类的 `NativeDestruct` 方法完成父类的销毁逻辑。
 */
void UMenu::NativeDestruct()
{
	MenuTearDown();
	Super::NativeDestruct();
}

void UMenu::OnCreateSession(bool bWasSuccessful)
{
	if (bWasSuccessful)
	{
		if (GEngine)
		{
			GEngine->AddOnScreenDebugMessage(-1, 5.f, FColor::Green, TEXT("Create session success!"));
		}
	}

	if (UWorld* World = GetWorld())
	{
		World->ServerTravel("/Game/Maps/Lobby?listen");
	}
}

/**
 * @brief 处理会话查找结果，尝试加入匹配类型相符的会话。
 * 
 * 此函数在会话查找完成后被调用，遍历所有查找到的会话结果，
 * 检查每个会话的匹配类型是否与预设的匹配类型一致，若一致则尝试加入该会话。
 * 
 * @param SessionResults 包含所有查找到的会话信息的数组。
 * @param bWasSuccessful 指示会话查找操作是否成功。`true` 表示成功，`false` 表示失败。
 */
void UMenu::OnFindSessions(const TArray<FOnlineSessionSearchResult>& SessionResults, bool bWasSuccessful)
{
	// 检查多人游戏会话子系统是否有效，若无效则直接返回，避免后续操作出错
	if (MultiplayerSessionSubsystem == nullptr) return;

	// 遍历所有查找到的会话结果
	for (auto Result : SessionResults)
	{
		// 用于存储从会话设置中获取的匹配类型值
		FString SettingsValue;
		// 从会话设置中获取名为 "MatchType" 的值
		Result.Session.SessionSettings.Get(FName("MatchType"), SettingsValue);
		// 检查获取到的匹配类型是否与预设的匹配类型一致
		if (SettingsValue == MatchType)
		{
			// 若匹配类型一致，则调用多人游戏会话子系统的 JoinSession 函数尝试加入该会话
			MultiplayerSessionSubsystem->JoinSession(Result);
			// 找到匹配的会话并尝试加入后，退出函数
			return;
		}
	}
}

/**
 * @brief 处理加入会话完成后的操作。
 * 
 * 此函数在加入会话操作完成后被调用，根据会话接口获取解析后的连接字符串，
 * 并使用该字符串让本地玩家控制器连接到目标会话。
 * 
 * @param Result 加入会话操作的结果枚举类型，指示加入操作是否成功以及具体的状态。
 */
void UMenu::OnJoinSession(EOnJoinSessionCompleteResult::Type Result)
{
	// 获取当前的在线子系统实例
	if (const IOnlineSubsystem* Subsystem = IOnlineSubsystem::Get())
	{
		// 从在线子系统中获取会话接口
		const IOnlineSessionPtr SessionInterface = Subsystem->GetSessionInterface();
		// 检查会话接口是否有效
		if (SessionInterface.IsValid())
		{
			// 用于存储解析后的连接字符串
			FString Address;
			// 从会话接口中获取名为 "GameSession" 的会话的解析连接字符串
			SessionInterface->GetResolvedConnectString(NAME_GameSession, Address);
			// 获取游戏实例中的第一个本地玩家控制器
			if (APlayerController* PlayerController = GetGameInstance()->GetFirstLocalPlayerController())
			{
				// 使用获取到的连接字符串让玩家控制器连接到目标会话
				// ETravelType::TRAVEL_Absolute 表示绝对路径旅行
				PlayerController->ClientTravel(Address, ETravelType::TRAVEL_Absolute);
			}
		}
	}
}


void UMenu::OnDestroySession(bool bWasSuccessful)
{
}

void UMenu::OnStartSession(bool bWasSuccessful)
{
}

void UMenu::HostButtonClicked()
{
	if (IsValid(MultiplayerSessionSubsystem))
	{
		MultiplayerSessionSubsystem->CreateSession(NumPublicConnections, MatchType);
	}
}

void UMenu::JoinButtonClicked()
{
	if (IsValid(MultiplayerSessionSubsystem))
	{
		MultiplayerSessionSubsystem->FindSessions(10000);
	}
}

/**
 * @brief 移除菜单界面，恢复游戏输入模式。
 * 
 * 该函数将菜单从其父级组件中移除，并将玩家的输入模式从 UI 模式切换回游戏模式，
 * 同时隐藏鼠标光标，让玩家可以正常进行游戏操作。
 */
void UMenu::MenuTearDown()
{
	// 将菜单从其父级组件中移除，使其不再显示在视口上
	RemoveFromParent();
	// 获取当前所在的世界对象
	if (const UWorld* World = GetWorld())
	{
		// 获取当前世界中的第一个玩家控制器
		if (APlayerController* PlayerController = World->GetFirstPlayerController())
		{
			// 创建一个仅用于游戏输入的输入模式对象
			// 该模式下，输入主要用于控制游戏角色和操作
			const FInputModeGameOnly InputModeData;
			// 使得玩家输入切换到仅与游戏交互的模式
			PlayerController->SetInputMode(InputModeData);
			// 隐藏鼠标光标，避免影响游戏操作
			PlayerController->SetShowMouseCursor(false);
		}
	}
}
