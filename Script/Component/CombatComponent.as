class UCombatComponent : UActorComponent
{
    ABlasterCharacter BlasterCharacter;

    UPROPERTY(Replicated)
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
};