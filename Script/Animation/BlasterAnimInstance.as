class UBlasterAnimInstance : UAnimInstance
{
    UPROPERTY(NotEditable, BlueprintReadOnly)
    protected ABlasterCharacter BlasterCharacter;

    UPROPERTY(NotEditable, BlueprintReadOnly)
    protected float Speed;

    UPROPERTY(NotEditable, BlueprintReadOnly)
    protected bool bIsAccelerating;

    UPROPERTY(NotEditable, BlueprintReadOnly)
    protected bool bIsInAir;

    UPROPERTY(NotEditable, BlueprintReadOnly)
    protected bool bWeaponEquipped;

    UFUNCTION(BlueprintOverride)
    void BlueprintInitializeAnimation()
    {
        BlasterCharacter = Cast<ABlasterCharacter>(OwningActor);
    }

    UFUNCTION(BlueprintOverride)
    void BlueprintUpdateAnimation(float DeltaTimeX)
    {
        if (!IsValid(BlasterCharacter))
        {
            BlasterCharacter = Cast<ABlasterCharacter>(OwningActor);
        }
        if (!IsValid(BlasterCharacter))
            return;

        FVector Velocity = BlasterCharacter.GetVelocity();
        // 将速度向量的 Z 分量置为 0，忽略垂直方向的速度
        Velocity.Z = 0.0;
        // 计算水平方向的速度大小
        Speed = Velocity.Size();
        // 检查 BlasterCharacter 是否正在空中，即是否处于下落状态
        bIsInAir = BlasterCharacter.CharacterMovement.IsFalling();

        // 检查 BlasterCharacter 是否正在加速，通过判断当前加速度的大小是否大于 0
        bIsAccelerating = BlasterCharacter.CharacterMovement.GetCurrentAcceleration().Size() > 0.0 ? true : false;

        bWeaponEquipped = BlasterCharacter.IsWeaponEquipped();
    }
};