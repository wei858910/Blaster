class ABlasterCharacter : ACharacter
{
    default Mesh.SetSkeletalMeshAsset(Cast<USkeletalMesh>(LoadObject(nullptr, "/Game/Assets/LearningKit_Games/Assets/Characters/Character/Mesh/SK_EpicCharacter.SK_EpicCharacter")));
    default Mesh.SetRelativeLocation(FVector(0.0, 0.0, -88.0));
    default Mesh.SetRelativeRotation(FRotator(0.0, -90.0, 0.0));

    UPROPERTY(DefaultComponent, Category = "Camera")
    USpringArmComponent CameraBoom;
    default CameraBoom.AttachTo(Mesh);
    default CameraBoom.TargetArmLength = 600.0;
    default CameraBoom.bUsePawnControlRotation = true;
    default CameraBoom.SetRelativeLocation(FVector(0.0, 0.0, 100.0));

    UPROPERTY(DefaultComponent, Attach = CameraBoom, Category = "Camera")
    UCameraComponent FollowCamera;
    default FollowCamera.bUsePawnControlRotation = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
    }
};