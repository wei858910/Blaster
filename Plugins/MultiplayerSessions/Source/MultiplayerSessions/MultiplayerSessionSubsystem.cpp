// Fill out your copyright notice in the Description page of Project Settings.


#include "MultiplayerSessionSubsystem.h"

#include "OnlineSubsystem.h"

UMultiplayerSessionSubsystem::UMultiplayerSessionSubsystem()
{
	// 获取默认的在线子系统实例指针。在线子系统负责管理游戏的网络相关功能，
	// 不同的平台（如 Steam、Epic Games 等）有不同的实现。
	IOnlineSubsystem* Subsystem = IOnlineSubsystem::Get();
	if (Subsystem)
	{
		// 若成功获取在线子系统实例，则从该子系统中获取会话接口指针。
		// 会话接口提供了创建、查找、加入和销毁游戏会话等功能。
		SessionInterface = Subsystem->GetSessionInterface();
	}
}
