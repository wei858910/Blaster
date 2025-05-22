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
        Velocity.Z = 0.0;
        Speed = Velocity.Size();

        bIsInAir = BlasterCharacter.CharacterMovement.IsFalling();

        bIsAccelerating = BlasterCharacter.CharacterMovement.GetCurrentAcceleration().Size() > 0.0 ? true : false;
    }
};