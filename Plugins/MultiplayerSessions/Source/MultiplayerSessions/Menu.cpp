// Fill out your copyright notice in the Description page of Project Settings.


#include "Menu.h"

#include "MultiplayerSessionSubsystem.h"
#include "Components/Button.h"

void UMenu::UMenuSetup()
{
	AddToViewport();
	SetVisibility(ESlateVisibility::Visible);
	SetIsFocusable(true);

	UWorld* World = GetWorld();
	if (World)
	{
		// 获取当前世界中的第一个玩家控制器
		// 玩家控制器负责处理玩家输入并控制玩家角色
		APlayerController* PlayerController = World->GetFirstPlayerController();
		if (PlayerController)
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

	UGameInstance* GameInstance = GetGameInstance();
	if (GameInstance)
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

void UMenu::HostButtonClicked()
{
	if (GEngine)
	{
		GEngine->AddOnScreenDebugMessage(-1, 5.f, FColor::Green, TEXT("Host button clicked!"));
	}

	if (IsValid(MultiplayerSessionSubsystem))
	{
		MultiplayerSessionSubsystem->CreateSession(4, FString("FreeForAll"));
	}
}

void UMenu::JoinButtonClicked()
{
	if (GEngine)
	{
		GEngine->AddOnScreenDebugMessage(-1, 5.f, FColor::Green, TEXT("Join button clicked!"));
	}
}
