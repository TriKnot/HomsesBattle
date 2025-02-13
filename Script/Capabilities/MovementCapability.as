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
        return !MoveComp.bIsLocked && !CapabilityComp.MovementInput.IsNearlyZero();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return MoveComp.bIsLocked || CapabilityComp.MovementInput.IsNearlyZero();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {      
        FRotator ControlRotation = HomseOwner.GetControlRotation();
        FVector Forward = ControlRotation.GetForwardVector();
        FVector Right = ControlRotation.GetRightVector();
        FVector2D MovementInput = CapabilityComp.MovementInput;

        MoveComp.AddMovementInput(Forward, MovementInput.Y, false);
        MoveComp.AddMovementInput(Right, MovementInput.X, false);
    }
};