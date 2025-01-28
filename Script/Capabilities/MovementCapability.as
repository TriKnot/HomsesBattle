class UMovementCapability : UCapability
{
    default Priority = ECapabilityPriority::Movement; 
    UHomseMovementComponent MoveComp;
    UCapabilityComponent CapabilityComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(Owner);
        MoveComp = HomseOwner.HomseMovementComponent;
        CapabilityComp = HomseOwner.CapabilityComponent;
    }

    UFUNCTION(BlueprintOverride)
    void Teardown()
    {
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
        FVector MovementInput = FVector::ZeroVector;
        if(CapabilityComp.GetActionStatus(InputActions::MovementDown))
            MovementInput.Y -= 1.0f;
        if(CapabilityComp.GetActionStatus(InputActions::MovementLeft))
            MovementInput.X -= 1.0f;
        if(CapabilityComp.GetActionStatus(InputActions::MovementRight))
            MovementInput.X += 1.0f;
        if(CapabilityComp.GetActionStatus(InputActions::MovementUp))
            MovementInput.Y += 1.0f;
        
        Print("MovementInput: " + MovementInput.ToString());
        //MoveComp.AddMovementInput(MovementInput, 1, false);
    }
};