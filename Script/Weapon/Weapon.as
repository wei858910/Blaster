
enum EWeaponState
{
    EWT_Initial,
    EWT_Equipped,
    EWT_Dropped,
    EWT_MAX
}

class AWeapon : AActor
{
    default bReplicates = true; // 启用网络同步，使该类的实例可以在网络上进行同步和更新。
    default SetActorTickEnabled(false);

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

    UPROPERTY(Replicated, ReplicatedUsing = OnRep_WeaponState, VisibleAnywhere, BlueprintReadOnly, Category = "Weapon Properties")
    protected EWeaponState WeaponState; // 武器类型，枚举类型，用于标识武器的状态。

    UPROPERTY(DefaultComponent, Category = "Weapon Properties")
    UWidgetComponent PickupWidget; // 拾取小部件，用于显示拾取提示。
    default PickupWidget.WidgetClass = Cast<UClass>(LoadObject(nullptr, "/Game/Blueprints/HUD/WBP_Pickup.WBP_Pickup_C"));
    default PickupWidget.bDrawAtDesiredSize = true;
    default PickupWidget.Space = EWidgetSpace::Screen;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (IsValid(PickupWidget))
        {
            PickupWidget.SetVisibility(false);
        }

        // 检查当前角色是否具有服务器权限。
        if (HasAuthority())
        {
            // 启用 AreaSphere 的碰撞检测，允许物理模拟和查询检测。
            AreaSphere.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
            // 设置 AreaSphere 对玩家角色碰撞通道的响应为重叠，当玩家进入该区域时触发重叠事件。
            AreaSphere.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);
            // 绑定 AreaSphere 的 OnComponentBeginOverlap 事件到 OnSphereOverlap 函数，当有组件与 AreaSphere 发生重叠时调用该函数。
            AreaSphere.OnComponentBeginOverlap.AddUFunction(this, n"OnSphereOverlap");
            // 绑定 AreaSphere 的 OnComponentEndOverlap 事件到 OnSphereEndOverlap 函数，当有组件与 AreaSphere 结束重叠时调用该函数。
            AreaSphere.OnComponentEndOverlap.AddUFunction(this, n"OnSphereEndOverlap");
        }
    }

    UFUNCTION()
    private void OnSphereOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
    {
        ABlasterCharacter BlasterCharacter = Cast<ABlasterCharacter>(OtherActor);
        if (IsValid(BlasterCharacter))
        {
            BlasterCharacter.SetOverlappingWeapon(this);
        }
    }

    UFUNCTION()
    private void OnSphereEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
    {
        ABlasterCharacter BlasterCharacter = Cast<ABlasterCharacter>(OtherActor);
        if (IsValid(BlasterCharacter))
        {
            BlasterCharacter.SetOverlappingWeapon(nullptr);
        }
    }

    void ShowPickupWidget(bool bShowWidget)
    {
        if (IsValid(PickupWidget))
        {
            PickupWidget.SetVisibility(bShowWidget);
        }
    }

    void SetWeaponState(EWeaponState State)
    {
        WeaponState = State;
        switch (WeaponState)
        {
            case EWeaponState::EWT_Equipped:
            {
                ShowPickupWidget(false);
                AreaSphere.SetCollisionEnabled(ECollisionEnabled::NoCollision);
                break;
            }
        }
    }

    UFUNCTION()
    void OnRep_WeaponState()
    {
        switch (WeaponState)
        {
            case EWeaponState::EWT_Equipped:
            {
                ShowPickupWidget(false);
                AreaSphere.SetCollisionEnabled(ECollisionEnabled::NoCollision);
                break;
            }
        }
    }

    USkeletalMeshComponent GetWeaponMesh() const
    {
        return WeaponMesh;
    }
};