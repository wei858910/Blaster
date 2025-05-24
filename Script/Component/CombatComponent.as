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

    UFUNCTION(Server)
    void SetAiming(bool bIsAiming)
    {
        bAiming = bIsAiming;
    }
};