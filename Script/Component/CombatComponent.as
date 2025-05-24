class UCombatComponent : UActorComponent
{
    ABlasterCharacter BlasterCharacter;

    UPROPERTY(Replicated, ReplicatedUsing = OnRep_EquippedWeapon)
    AWeapon EquippedWeapon;

    UPROPERTY(Replicated)
    bool bAiming = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BlasterCharacter = Cast<ABlasterCharacter>(GetOwner());
    }

    void EquipWeapon(AWeapon WeaponToEquip)
    {
        if (IsValid(WeaponToEquip) && IsValid(BlasterCharacter))
        {
            EquippedWeapon = WeaponToEquip;
            EquippedWeapon.SetOwner(BlasterCharacter);
            EquippedWeapon.SetWeaponState(EWeaponType::EWT_Equipped);
            EquippedWeapon.AttachToComponent(BlasterCharacter.Mesh, n"RightHandSocket", EAttachmentRule::SnapToTarget);
        }
        // 禁用角色移动时自动朝向移动方向
        BlasterCharacter.CharacterMovement.bOrientRotationToMovement = false;
        // 启用使用控制器的 Yaw 旋转来控制角色朝向
        BlasterCharacter.bUseControllerRotationYaw = true;
    }

    void SetAiming(bool bIsAiming)
    {
        bAiming = bIsAiming;
        ServerSetAiming(bIsAiming);
    }

    UFUNCTION(Server)
    void ServerSetAiming(bool bIsAiming)
    {
        bAiming = bIsAiming;
    }

    UFUNCTION()
    void OnRep_EquippedWeapon()
    {
        if (IsValid(EquippedWeapon) && IsValid(BlasterCharacter))
        {
            BlasterCharacter.CharacterMovement.bOrientRotationToMovement = false;
            BlasterCharacter.bUseControllerRotationYaw = true;
        }
    }
};