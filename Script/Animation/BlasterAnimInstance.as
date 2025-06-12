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

    AWeapon EquippedWeapon;

    UPROPERTY(NotEditable, BlueprintReadOnly)
    protected bool bIsCrouched;

    UPROPERTY(NotEditable, BlueprintReadOnly)
    protected bool bAiming;

    UPROPERTY(NotEditable, BlueprintReadOnly)
    float YawOffset; // 用于存储 Yaw 偏移量的变量，用于控制角色的朝向

    UPROPERTY(NotEditable, BlueprintReadOnly)
    float Lean; // 用于存储 Lean（leaning）的变量，用于控制角色的侧倾角度

    UPROPERTY(NotEditable, BlueprintReadOnly)
    float AO_Yaw; // 用于存储 Aiming Offset 的 Yaw 角度，用于控制角色的瞄准偏移

    UPROPERTY(NotEditable, BlueprintReadOnly)
    float AO_Pitch; // 用于存储 Aiming Offset 的 Pitch 角度，用于控制角色的瞄准偏移

    UPROPERTY(NotEditable, BlueprintReadOnly)
    FTransform LeftHandTransform;

    FRotator CharacterRotationLastFrame; // 用于存储上一帧的角色旋转器，用于计算 Lean（leaning）的变化量
    FRotator CharacterRotation;          // 用于存储当前帧的角色旋转器，用于计算 Lean（leaning）的变化量
    FRotator DeltaRotation;

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

        EquippedWeapon = BlasterCharacter.GetEquippedWeapon();

        bIsCrouched = BlasterCharacter.bIsCrouched;

        bAiming = BlasterCharacter.IsAiming();

        // 计算 Yaw 偏移量，用于控制角色的朝向
        FRotator AimRotation = BlasterCharacter.GetBaseAimRotation();
        FRotator MovementRotation = FRotator::MakeFromX(BlasterCharacter.GetVelocity()); // 从速度向量创建旋转器，用于获取角色的移动方向
        FRotator DeltaRot = MovementRotation - AimRotation;                              // 计算移动方向和瞄准方向之间的差异
        DeltaRot.Normalize();
        DeltaRotation = Math::RInterpTo(DeltaRotation, DeltaRot, DeltaTimeX, 15.0);
        YawOffset = DeltaRotation.Yaw; // 计算 Yaw 偏移量，用于控制角色的朝向

        // 计算 Lean（leaning）的角度，用于控制角色的侧倾角度
        CharacterRotationLastFrame = CharacterRotation;            // 保存上一帧的角色旋转器
        CharacterRotation = BlasterCharacter.GetActorRotation();   // 获取当前帧的角色旋转
        DeltaRot = CharacterRotation - CharacterRotationLastFrame; // 计算角色旋转器的变化量
        if (DeltaTimeX != 0.0)
        {
            const float Target = DeltaRot.Yaw / DeltaTimeX;                      // 计算目标 Lean（leaning）的角度
            const float Interp = Math::FInterpTo(Lean, Target, DeltaTimeX, 6.0); // 使用插值函数平滑过渡 Lean（leaning）的角度
            Lean = Math::Clamp(Interp, -90.0, 90.0);                             // 限制 Lean（leaning）的角度在 -90 到 90 度之间
        }

        AO_Yaw = BlasterCharacter.GetAOYaw();     // 获取 Aiming Offset 的 Yaw 角度，用于控制角色的瞄准偏移
        AO_Pitch = BlasterCharacter.GetAOPitch(); // 获取 Aiming Offset 的 Pitch 角度，用于控制角色的瞄准偏移

        if (bWeaponEquipped && IsValid(EquippedWeapon) && IsValid(EquippedWeapon.GetWeaponMesh()) && IsValid(BlasterCharacter.Mesh))
        {
            LeftHandTransform = EquippedWeapon.GetWeaponMesh().GetSocketTransform(n"LeftHandSocket");
            FVector  OutPosition;
            FRotator OutRotation;
            BlasterCharacter.Mesh.TransformToBoneSpace(n"hand_r", LeftHandTransform.GetLocation(), FRotator::ZeroRotator, OutPosition, OutRotation);
            LeftHandTransform.SetLocation(OutPosition);
            LeftHandTransform.SetRotation(FQuat(OutRotation));
        }
    }
};