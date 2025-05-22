// Fill out your copyright notice in the Description page of Project Settings.


#include "Menu.h"

#include "MultiplayerSessionSubsystem.h"
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

void UMenu::HostButtonClicked()
{
	if (GEngine)
	{
		GEngine->AddOnScreenDebugMessage(-1, 5.f, FColor::Green, TEXT("Host button clicked!"));
	}

	if (IsValid(MultiplayerSessionSubsystem))
	{
		if (MultiplayerSessionSubsystem->CreateSession(NumPublicConnections, MatchType))
		{
			if (UWorld* World = GetWorld())
			{
				World->ServerTravel("/Game/Maps/Lobby?listen");
			}
		}
	}
}

void UMenu::JoinButtonClicked()
{
	if (GEngine)
	{
		GEngine->AddOnScreenDebugMessage(-1, 5.f, FColor::Green, TEXT("Join button clicked!"));
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
