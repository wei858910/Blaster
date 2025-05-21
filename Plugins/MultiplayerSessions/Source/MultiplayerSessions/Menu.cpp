// Fill out your copyright notice in the Description page of Project Settings.


#include "Menu.h"

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
}
