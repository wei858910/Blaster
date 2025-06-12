class ABlasterCharacter : ACharacter
{
    default Mesh.SetSkeletalMeshAsset(Cast<USkeletalMesh>(LoadObject(nullptr, "/Game/Assets/LearningKit_Games/Assets/Characters/Character/Mesh/SK_EpicCharacter.SK_EpicCharacter")));
    default Mesh.SetRelativeLocation(FVector(0.0, 0.0, -88.0));
    default Mesh.SetRelativeRotation(FRotator(0.0, -90.0, 0.0));
    default Mesh.SetAnimationMode(EAnimationMode::AnimationBlueprint);
    default Mesh.SetAnimInstanceClass(Cast<UClass>(LoadObject(nullptr, "/Game/Blueprints/Character/Animation/BP_BlasterAnim.BP_BlasterAnim_C")));

    UPROPERTY(DefaultComponent, Category = "Camera")
    USpringArmComponent CameraBoom;
    default CameraBoom.AttachTo(Mesh);
    default CameraBoom.TargetArmLength = 600.0;
    default CameraBoom.bUsePawnControlRotation = true;
    default CameraBoom.SetRelativeLocation(FVector(0.0, 0.0, 100.0));

    UPROPERTY(DefaultComponent, Attach = CameraBoom, Category = "Camera")
    UCameraComponent FollowCamera;
    default FollowCamera.bUsePawnControlRotation = false;

    UPROPERTY(DefaultComponent)
    UWidgetComponent OverheadWidget;
    default OverheadWidget.WidgetClass = Cast<UClass>(LoadObject(nullptr, "/Game/Blueprints/HUD/WBP_Overhead.WBP_Overhead_C"));
    default OverheadWidget.AttachTo(Mesh);
    default OverheadWidget.SetRelativeLocation(FVector(0.0, 0.0, CapsuleComponent.CapsuleHalfHeight * 2.0 + 50.0));
    default OverheadWidget.Space = EWidgetSpace::Screen;
    default OverheadWidget.bDrawAtDesiredSize = true;

    UPROPERTY(Replicated, ReplicatedUsing = OnRep_OverlappingWeapon, ReplicationCondition = OwnerOnly)
    AWeapon OverlappingWeapon; // 用于存储重叠的武器

    UPROPERTY(DefaultComponent, Category = "Input")
    UEnhancedInputComponent InputComponent;

    UPROPERTY(DefaultComponent)
    UCombatComponent Combat;
    default Combat.SetIsReplicated(true);

    default CharacterMovement.NavAgentProps.bCanCrouch = true;

    UPROPERTY(Category = "Input")
    UInputMappingContext InputMappingContext;
    default InputMappingContext = Cast<UInputMappingContext>(LoadObject(nullptr, "/Game/Input/IMC_Blaster.IMC_Blaster"));

    UPROPERTY(Category = "Input")
    UInputAction MoveAction;
    default MoveAction = Cast<UInputAction>(LoadObject(nullptr, "/Game/Input/IA_Move.IA_Move"));

    UPROPERTY(Category = "Input")
    UInputAction LookAction;
    default LookAction = Cast<UInputAction>(LoadObject(nullptr, "/Game/Input/IA_Look.IA_Look"));

    UPROPERTY(Category = "Input")
    UInputAction JumpAction;
    default JumpAction = Cast<UInputAction>(LoadObject(nullptr, "/Game/Input/IA_Jump.IA_Jump"));

    UPROPERTY(Category = "Input")
    UInputAction EquipAction;
    default EquipAction = Cast<UInputAction>(LoadObject(nullptr, "/Game/Input/IA_Equip.IA_Equip"));

    UPROPERTY(Category = "Input")
    UInputAction CrouchAction = Cast<UInputAction>(LoadObject(nullptr, "/Game/Input/IA_Crouch.IA_Crouch"));

    UPROPERTY(Category = "Input")
    UInputAction AimAction = Cast<UInputAction>(LoadObject(nullptr, "/Game/Input/IA_Aim.IA_Aim"));

    UPROPERTY()
    float MoveSpeed = 100.0;

    // 禁用控制器偏航旋转，使角色不会随控制器旋转而旋转
    default bUseControllerRotationYaw = false;
    // 启用角色朝向移动方向，使角色自动转向移动方向
    default CharacterMovement.bOrientRotationToMovement = true;

    default CharacterMovement.JumpZVelocity = 1600.0;
    default CharacterMovement.GravityScale = 3.0;
    default CharacterMovement.MaxWalkSpeedCrouched = 350.0;

    private float AO_Yaw; // 用于存储 Aiming Offset 的 Yaw 角度，用于控制角色的瞄准偏移
    private float AO_Pitch; // 用于存储 Aiming Offset 的 Pitch 角度，用于控制角色的瞄准偏移

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        UOverheadWidget OverWidget = Cast<UOverheadWidget>(OverheadWidget.GetUserWidgetObject());
        if (IsValid(OverWidget))
        {
            OverWidget.ShowPlayerNetRole(this);
        }

        // 尝试将控制器转换为玩家控制器
        APlayerController PlayerController = Cast<APlayerController>(GetController());
        // 检查玩家控制器是否有效
        if (IsValid(PlayerController))
        {
            // 为玩家控制器创建一个增强输入组件
            InputComponent = UEnhancedInputComponent::Create(PlayerController);
            // 将新创建的输入组件推送到玩家控制器的输入栈中
            PlayerController.PushInputComponent(InputComponent);
            // 获取玩家控制器的增强输入子系统
            UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(PlayerController);
            // 检查增强输入子系统是否有效
            if (IsValid(EnhancedInputSubsystem))
            {
                // 为增强输入子系统添加输入映射上下文
                EnhancedInputSubsystem.AddMappingContext(InputMappingContext, 0, FModifyContextOptions());
                // 将移动动作绑定到 OnMove 函数，当动作触发时调用
                InputComponent.BindAction(MoveAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"OnMove"));
                // 将查看动作绑定到 OnLook 函数，当动作触发时调用
                InputComponent.BindAction(LookAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"OnLook"));
                // 将跳跃动作绑定到 OnJump 函数，当动作开始时调用
                InputComponent.BindAction(JumpAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"OnJump"));
                InputComponent.BindAction(EquipAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"OnEquip"));
                InputComponent.BindAction(CrouchAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"OnCrouch"));
                InputComponent.BindAction(CrouchAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"OnCrouch"));
                InputComponent.BindAction(AimAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"OnAim"));
                InputComponent.BindAction(AimAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"OnAim"));
            }
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        AimOffset(DeltaSeconds);
    }

    UFUNCTION()
    private void OnMove(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        // 获取输入操作的二维轴值（对应移动方向的XY分量）
        FVector2D MovementVector = ActionValue.GetAxis2D();
        float     X = MovementVector.X; // 水平方向输入值（左负右正）
        float     Y = MovementVector.Y; // 垂直方向输入值（后负前正）

        // 基于控制器的偏航旋转创建方向旋转（仅保留Yaw轴）
        const FRotator YawRotation(0.0, Controller.GetControlRotation().Yaw, 0.0);

        // 获取世界时间增量（用于平滑移动计算）
        float DeltaTime = Gameplay::GetWorldDeltaSeconds();

        // 处理水平方向移动（左右）
        if (X != 0.0)
        {
            // 向角色右方向添加移动输入（速度 = 基础速度 * 输入值 * 时间增量）
            AddMovementInput(YawRotation.RightVector, MoveSpeed * X * DeltaTime);
        }

        // 处理垂直方向移动（前后）
        if (Y != 0.0)
        {
            // 向角色前方向添加移动输入（速度 = 基础速度 * 输入值 * 时间增量）
            AddMovementInput(YawRotation.ForwardVector, MoveSpeed * Y * DeltaTime);
        }
    }

    /**
     * @brief 处理视角移动输入的函数
     * @param ActionValue 输入动作的值，包含视角移动的方向和幅度
     * @param ElapsedTime 从输入开始到现在经过的总时间
     * @param TriggeredTime 输入动作触发的时间
     * @param SourceAction 触发此输入的输入动作对象
     */
    UFUNCTION()
    private void OnLook(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        // 从输入动作值中获取二维视角移动向量
        FVector2D LookVector = ActionValue.GetAxis2D();
        // 获取水平方向的视角移动值
        float X = LookVector.X;
        // 获取垂直方向的视角移动值
        float Y = LookVector.Y;

        // 如果水平方向有输入，则添加控制器的偏航（左右）旋转输入
        if (X != 0.0)
        {
            AddControllerYawInput(X);
        }

        // 如果垂直方向有输入，则添加控制器的俯仰（上下）旋转输入，取反是为了符合常规操作习惯
        if (Y != 0.0)
        {
            AddControllerPitchInput(-Y);
        }
    }

    UFUNCTION()
    private void OnJump(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        Jump();
    }

    UFUNCTION()
    private void OnEquip(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        if (IsValid(Combat))
        {
            HasAuthority() ? Combat.EquipWeapon(OverlappingWeapon) : ServerEquipWeapon();
        }
    }

    UFUNCTION()
    private void OnCrouch(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        ActionValue.Get() ? Crouch() : UnCrouch();
    }

    UFUNCTION()
    private void OnAim(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        if (IsValid(Combat))
        {
            Combat.SetAiming(ActionValue.Get());
        }
    }

    FRotator StartingAimRotation; // 用于存储初始瞄准旋转

    float CalculateSpeed()
    {
        FVector CurrentVelocity = GetVelocity();
        CurrentVelocity.Z = 0.0;
        return CurrentVelocity.Size();
    }

    protected void AimOffset(float DeltaTime)
    {
        if (Combat != nullptr && Combat.EquippedWeapon == nullptr)
            return;

        float Speed = CalculateSpeed();
        bool  bIsInAir = CharacterMovement.IsFalling();

        if (Speed == 0.0 && !bIsInAir)
        {
            // 计算自开始瞄准以来的Yaw（水平旋转）变化量。
            FRotator CurrentAimRotation = FRotator(0.0, GetBaseAimRotation().Yaw, 0.0);
            FRotator DeltaAimRotation = (CurrentAimRotation - StartingAimRotation).Normalized;
            AO_Yaw = DeltaAimRotation.Yaw;
            bUseControllerRotationYaw = false; // 禁用控制器偏航旋转
        }

        /**
         * 如果角色正在移动或处于空中，则更新 StartingAimRotation。
         *
         * 当角色速度大于零或处于空中（bIsInAir 为 true）时，
         * 将 StartingAimRotation 设置为当前基础瞄准旋转的 Yaw，Pitch 和 Roll 为零的新 FRotator。
         * 这通常用于在角色移动或跳跃时追踪角色的瞄准方向。
         */
        if (Speed > 0 || bIsInAir)
        {
            StartingAimRotation = FRotator(0.0, GetBaseAimRotation().Yaw, 0.0);
            AO_Yaw = 0.0;
            bUseControllerRotationYaw = true; // 启用控制器偏航旋转
        }
        CaculateAO_Pitch();
    }

    void CaculateAO_Pitch()
    {
        /**
         * 根据角色的基础瞄准旋转更新瞄准偏移的俯仰角（AO_Pitch）。
         * 如果俯仰角大于90度且角色不是本地控制，则将俯仰角从[270, 360]范围映射到[-90, 0]范围。
         * 这样可以确保网络同步时远程角色的俯仰角不会出现异常（因为Pitch角度会环绕）。
         */
        AO_Pitch = GetBaseAimRotation().Pitch;
        if (AO_Pitch > 90.0 && !IsLocallyControlled())
        {
            FVector2D InRange(270.0, 360.0);
            FVector2D OutRange(-90.0, 0.0);
            AO_Pitch = Math::GetMappedRangeValueClamped(InRange, OutRange, AO_Pitch);
        }
    }

    float GetAOYaw() const
    {
        return AO_Yaw;
    }

    float GetAOPitch() const
    {
        return AO_Pitch;
    }

    void SetOverlappingWeapon(AWeapon Weapon)
    {
        if (IsValid(OverlappingWeapon))
        {
            OverlappingWeapon.ShowPickupWidget(false);
        }

        OverlappingWeapon = Weapon;

        // 检查当前角色是否是本地控制的，非 network controller 控制的
        if (IsLocallyControlled())
        {
            if (IsValid(OverlappingWeapon))
            {
                OverlappingWeapon.ShowPickupWidget(true);
            }
        }
    }

    UFUNCTION()
    void OnRep_OverlappingWeapon(AWeapon LastWeapon)
    {
        if (IsValid(LastWeapon))
        {
            LastWeapon.ShowPickupWidget(false);
        }
        if (IsValid(OverlappingWeapon))
        {
            OverlappingWeapon.ShowPickupWidget(true);
        }
    }

    UFUNCTION(Server)
    void ServerEquipWeapon()
    {
        if (IsValid(OverlappingWeapon) && IsValid(Combat))
        {
            Combat.EquipWeapon(OverlappingWeapon);
        }
    }

    bool IsWeaponEquipped()
    {
        return (IsValid(Combat) && IsValid(Combat.EquippedWeapon));
    }

    bool IsAiming()
    {
        return (IsValid(Combat) && Combat.bAiming);
    }
};