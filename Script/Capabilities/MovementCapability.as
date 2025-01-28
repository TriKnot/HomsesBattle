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
        return !MoveComp.bIsBlocked;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return MoveComp.bIsBlocked;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        float X = 0.0f;
        float Y = 0.0f;

        if(CapabilityComp.GetActionStatus(InputActions::MovementDown))
            Y -= 1.0f;
        if(CapabilityComp.GetActionStatus(InputActions::MovementUp))
            Y += 1.0f;

        if(CapabilityComp.GetActionStatus(InputActions::MovementLeft))
            X -= 1.0f;
        if(CapabilityComp.GetActionStatus(InputActions::MovementRight))
            X += 1.0f;
        
        FRotator ControlRotation = HomseOwner.GetControlRotation();
        FVector Forward = ControlRotation.GetForwardVector();
        FVector Right = ControlRotation.GetRightVector();

        MoveComp.AddMovementInput(Forward, Y, false);
        MoveComp.AddMovementInput(Right, X, false);
    }
};