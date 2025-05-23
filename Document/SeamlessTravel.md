# 虚幻引擎中 Non-Seamless Travel 与 Seamless Travel 的区别

| **特性**                | **Non-Seamless Travel**               | **Seamless Travel**                   |
|-------------------------|---------------------------------------|---------------------------------------|
| **连接状态**            | 断开连接后重新加载并重连服务器        | 保持连接，服务器直接切换关卡          |
| **阻塞性**              | 阻塞式（Blocking）                    | 非阻塞式（Non-blocking）              |
| **用户体验**            | 明显卡顿/黑屏                         | 流畅过渡                              |
| **适用场景**            | - 首次加载地图<br>- 首次连接服务器<br>- 多人游戏回合结束 | - 多人游戏动态关卡切换（如开放世界区域切换）<br>- 需要保留玩家数据的场景 |
| **数据保留**            | 默认不保留玩家状态                    | 可保留玩家/actor状态（需手动配置）    |
| **实现复杂度**          | 简单                                  | 需处理异步加载和资源管理              |
| **典型API**             | `UWorld::ServerTravel()`              | `UGameInstance::StartSeamlessTravel()`|

## 关键差异说明
1. **性能影响**  
   - Non-Seamless：强制GC垃圾回收，清理所有资源  
   - Seamless：后台异步加载新关卡，保留部分资源

2. **多人游戏兼容性**  
   - Non-Seamless：所有客户端会经历断开-重连过程  
   - Seamless：服务器协调所有客户端同步切换

3. **资源管理**  
   - Seamless需特别注意：  
     - 使用`FGCObject`防止资源被GC  
     - 管理`Level Streaming`  
     - 处理PendingKill的Actor