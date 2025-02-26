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
    private UCharacterMovementComponent CharacterMovementComponent;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(GetOwner());
        CharacterMovementComponent = HomseOwner.CharacterMovement;
        CharacterMovementComponent.bOrientRotationToMovement = true;
        CharacterMovementComponent.bUseControllerDesiredRotation = false;
    }

    void SetMovementSpeed(EMovementSpeed Speed)
    {
        switch (Speed)
        {
            case EMovementSpeed::EMS_Walk:
                CharacterMovementComponent.MaxWalkSpeed = WalkSpeed;
                break;
            case EMovementSpeed::EMS_Run:
                CharacterMovementComponent.MaxWalkSpeed = RunSpeed;
                break;
            case EMovementSpeed::EMS_Sprint:
                CharacterMovementComponent.MaxWalkSpeed = SprintSpeed;
                break;
            default:
                break;
        }
    }

    void AddMovementInput(FVector WorldDirection, float ScaleValue, bool bForce)
    {
        CharacterMovementComponent.AddInputVector(WorldDirection * ScaleValue, bForce);
    }

    void SetVelocity(FVector NewVelocity)
    {
        CharacterMovementComponent.Velocity = NewVelocity;
    }

    void AddVelocity(FVector AddVelocity)
    {
        CharacterMovementComponent.Velocity += AddVelocity;
    }

    void SetMovementMode(EMovementMode NewMovementMode) 
    {
        CharacterMovementComponent.MovementMode = NewMovementMode;
    }

    FVector GetVelocity() const property
    {
        return CharacterMovementComponent.Velocity;
    }

    EMovementMode GetMovementMode() const property
    {
        return CharacterMovementComponent.MovementMode;
    }

    UCharacterMovementComponent GetCharacterMovement() const property
    {
        return CharacterMovementComponent;
    }

    UFUNCTION(BlueprintCallable)
    bool GetIsGrounded() const property
    {
        return CharacterMovementComponent.IsMovingOnGround();
    }

    void SetOrientToMovement(bool bOrientToMovement)
    {
        CharacterMovementComponent.bOrientRotationToMovement = bOrientToMovement;
        CharacterMovementComponent.bUseControllerDesiredRotation = !bOrientToMovement;
    }

}