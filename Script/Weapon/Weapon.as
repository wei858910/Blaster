
enum EWeaponType
{
    EWT_Initial,
    EWT_Equipped,
    EWT_Dropped,
    EWT_MAX
}

class AWeapon : AActor
{
    default bReplicates = true; // 启用网络同步，使该类的实例可以在网络上进行同步和更新。

    UPROPERTY(DefaultComponent, RootComponent, Category = "Weapon Properties")
    USkeletalMeshComponent WeaponMesh;
    // 将武器网格体对所有碰撞通道的响应设置为阻挡
    default WeaponMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
    // 将武器网格体对玩家角色碰撞通道的响应设置为忽略
    default WeaponMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);
    // 禁用武器网格体的碰撞检测
    default WeaponMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    UPROPERTY(DefaultComponent, Category = "Weapon Properties")
    USphereComponent AreaSphere;
    default AreaSphere.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
    default AreaSphere.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Weapon Properties")
    protected EWeaponType WeaponState; // 武器类型，枚举类型，用于标识武器的状态。

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // 检查当前角色是否具有服务器权限。
        if (HasAuthority())
        {
            // 启用 AreaSphere 的碰撞检测，允许物理模拟和查询检测。
            AreaSphere.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
            // 设置 AreaSphere 对玩家角色碰撞通道的响应为重叠，当玩家进入该区域时触发重叠事件。
            AreaSphere.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);
        }
    }
};