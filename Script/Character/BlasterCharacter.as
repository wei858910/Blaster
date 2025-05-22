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

    UPROPERTY(DefaultComponent, Category = "Input")
    UEnhancedInputComponent InputComponent;

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

    UPROPERTY()
    float MoveSpeed = 100.0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {

        APlayerController PlayerController = Cast<APlayerController>(GetController());
        if (IsValid(PlayerController))
        {
            InputComponent = UEnhancedInputComponent::Create(PlayerController);
            PlayerController.PushInputComponent(InputComponent);
            UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(PlayerController);
            if (IsValid(EnhancedInputSubsystem))
            {
                EnhancedInputSubsystem.AddMappingContext(InputMappingContext, 0, FModifyContextOptions());
                InputComponent.BindAction(MoveAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"OnMove"));
                InputComponent.BindAction(LookAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"OnLook"));
                InputComponent.BindAction(JumpAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"OnJump"));
            }
        }
    }

    UFUNCTION()
    private void OnMove(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        FVector2D MovementVector = ActionValue.GetAxis2D();
        float     X = MovementVector.X;
        float     Y = MovementVector.Y;

        const FRotator YawRotation(0.0, Controller.GetControlRotation().Yaw, 0.0);

        float DeltaTime = Gameplay::GetWorldDeltaSeconds();

        if (X != 0.0)
        {
            AddMovementInput(YawRotation.RightVector, MoveSpeed * X * DeltaTime);
        }

        if (Y != 0.0)
        {
            AddMovementInput(YawRotation.ForwardVector, MoveSpeed * Y * DeltaTime);
        }
    }

    UFUNCTION()
    private void OnLook(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
    {
        FVector2D LookVector = ActionValue.GetAxis2D();
        float     X = LookVector.X;
        float     Y = LookVector.Y;

        if (X != 0.0)
        {
            AddControllerYawInput(X);
        }

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
};