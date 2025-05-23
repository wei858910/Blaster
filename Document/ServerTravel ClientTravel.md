# UWorld::ServerTravel 与 APlayerController::ClientTravel 的区别

| **特性**                | **UWorld::ServerTravel**               | **APlayerController::ClientTravel**      |
|-------------------------|---------------------------------------|------------------------------------------|
| **调用权限**            | 仅服务器可调用                        | 客户端和服务器均可调用                   |
| **执行主体**            | 服务器控制全局关卡切换                | 客户端或服务器控制单个客户端的关卡切换   |
| **连接行为**            | 所有客户端跟随服务器切换              | 客户端可切换到新服务器或同一服务器的新地图 |
| **适用场景**            | 多人游戏全局地图切换（如回合结束）    | 客户端单独转移（如进入副本）             |
| **无缝切换支持**        | 支持（需配置`bUseSeamlessTravel`）     | 支持（需服务器协调）                     |
| **典型用例**            | `GetWorld()->ServerTravel("/Game/Maps/Level2")` | `PlayerController->ClientTravel("/Game/Maps/Level2", TRAVEL_Absolute)` |

## 关键差异说明

1. **执行流程差异**  
   - `ServerTravel`：服务器调用后，会自动为所有连接的客户端触发`ClientTravel`  
   - `ClientTravel`：若从客户端调用，会强制断开当前连接（非无缝模式下）

2. **多人游戏协作**  
   - `ServerTravel`是多人游戏地图切换的标准方式，服务器作为协调者
   - `ClientTravel`可用于特殊场景（如玩家单独传送到副本），但需自行处理同步逻辑

3. **参数差异**  
   - `ServerTravel`接受地图路径（如`/Game/Maps/Lobby`）  
   - `ClientTravel`额外需要指定`TravelType`（如`TRAVEL_Relative`/`TRAVEL_Absolute`） 

## 使用建议
- **优先使用`ServerTravel`**：确保所有客户端同步切换 
- **谨慎使用客户端`ClientTravel`**：可能导致意外断开连接
- **无缝切换需配置**：两者均需设置`TransitionMap`和`bUseSeamlessTravel`