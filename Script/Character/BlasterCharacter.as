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

    UPROPERTY()
    float MoveSpeed = 100.0;

    // 禁用控制器偏航旋转，使角色不会随控制器旋转而旋转
    default bUseControllerRotationYaw = false;
    // 启用角色朝向移动方向，使角色自动转向移动方向
    default CharacterMovement.bOrientRotationToMovement = true;

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
            }
        }
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
        if (IsValid(Combat) && HasAuthority())
        {
            Combat.EquipWeapon(OverlappingWeapon);
        }
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
};