class UHomseMovementComponent : ULockableComponent
{
    UPROPERTY()
    float WalkSpeed = 300.0f;

    UPROPERTY()
    float RunSpeed = 600.0f;

    UPROPERTY()
    float SprintSpeed = 900.0f;

    UPROPERTY()
    float JumpForce = 650.0f;

    UPROPERTY()
    bool bIsJumping = false;

    UPROPERTY()
    bool bIsDashing = false;

    UPROPERTY()
    UCharacterMovementComponent CharacterMovement;

    UPROPERTY()
    UCurveFloat DashCurve;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(GetOwner());
        CharacterMovement = HomseOwner.CharacterMovement;
        CharacterMovement.bOrientRotationToMovement = true;
        CharacterMovement.bUseControllerDesiredRotation = false;
    }

    void SetMovementSpeed(EMovementSpeed Speed)
    {
        switch (Speed)
        {
            case EMovementSpeed::EMS_Walk:
                CharacterMovement.MaxWalkSpeed = WalkSpeed;
                break;
            case EMovementSpeed::EMS_Run:
                CharacterMovement.MaxWalkSpeed = RunSpeed;
                break;
            case EMovementSpeed::EMS_Sprint:
                CharacterMovement.MaxWalkSpeed = SprintSpeed;
                break;
            default:
                break;
        }
    }

    void AddMovementInput(FVector WorldDirection, float ScaleValue, bool bForce)
    {
        CharacterMovement.AddInputVector(WorldDirection * ScaleValue, bForce);
    }

    void SetVelocity(FVector NewVelocity)
    {
        CharacterMovement.Velocity = NewVelocity;
    }

    void AddVelocity(FVector AddVelocity)
    {
        CharacterMovement.Velocity += AddVelocity;
    }

    FVector GetVelocity() property
    {
        return CharacterMovement.Velocity;
    }

    void SetMovementMode(EMovementMode NewMovementMode) 
    {
        CharacterMovement.MovementMode = NewMovementMode;
    }

    EMovementMode GetMovementMode() property
    {
        return CharacterMovement.MovementMode;
    }


    UFUNCTION(BlueprintCallable)
    bool GetIsGrounded() const property
    {
        return CharacterMovement.IsMovingOnGround();
    }

    void SetOrientToMovement(bool bOrientToMovement)
    {
        CharacterMovement.bOrientRotationToMovement = bOrientToMovement;
        CharacterMovement.bUseControllerDesiredRotation = !bOrientToMovement;
    }

}