class UHomseMovementComponent : ULockableComponent
{
    UPROPERTY()
    float WalkSpeed = 300.0f;

    UPROPERTY()
    float RunSpeed = 600.0f;

    UPROPERTY()
    float SprintSpeed = 900.0f;

    UPROPERTY()
    UCharacterMovementComponent CharacterMovement;

    UPROPERTY()
    bool bMovementLocked = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(GetOwner());
        CharacterMovement = HomseOwner.CharacterMovement;
    }

    UFUNCTION(BlueprintCallable)
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

    UFUNCTION(BlueprintCallable)
    void AddMovementInput(FVector WorldDirection, float ScaleValue, bool bForce)
    {
        if(bMovementLocked)
        {
            return;
        }
        CharacterMovement.AddInputVector(WorldDirection * ScaleValue, bForce);
    }

    UFUNCTION(BlueprintCallable)
    void SetVelocity(FVector NewVelocity)
    {
        CharacterMovement.Velocity = NewVelocity;
    }

    UFUNCTION(BlueprintCallable)
    FVector GetVelocity() property
    {
        return CharacterMovement.Velocity;
    }

}