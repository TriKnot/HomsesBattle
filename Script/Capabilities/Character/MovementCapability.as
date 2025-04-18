class UMovementCapability : UCapability
{
    default Priority = ECapabilityPriority::Movement; 

    AHomseCharacterBase HomseOwner;
    UHomseMovementComponent MoveComp;
    UCapabilityComponent CapabilityComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        MoveComp = HomseOwner.HomseMovementComponent;
        CapabilityComp = HomseOwner.CapabilityComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return !MoveComp.IsLocked() && !CapabilityComp.MovementInput.IsNearlyZero();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return MoveComp.IsLocked() || CapabilityComp.MovementInput.IsNearlyZero();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {      
        FRotator ControlRotation = HomseOwner.GetControlRotation();
        FVector Forward = ControlRotation.GetForwardVector();
        FVector Right = ControlRotation.GetRightVector();
        Forward.Z = 0.0f;
        Right.Z = 0.0f;
        Forward.Normalize();
        Right.Normalize();
        FVector2D MovementInput = CapabilityComp.MovementInput;

        MoveComp.AddMovementInput(Forward, MovementInput.Y, false);
        MoveComp.AddMovementInput(Right, MovementInput.X, false);
    }
};