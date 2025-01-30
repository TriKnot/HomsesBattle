class UJumpCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    AHomseCharacterBase HomseOwner;
    UHomseMovementComponent MoveComp;
    UCapabilityComponent CapabilityComp;

    bool bJumpHasStarted = false;

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
        if (MoveComp.bIsBlocked)
            return false;

        if(!MoveComp.IsGrounded)
            return false;

        if(CapabilityComp.GetActionStatus(InputActions::Jump))
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return bJumpHasStarted && MoveComp.IsGrounded;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        MoveComp.bIsJumping = true;

        // Apply upward force for jumping
        FVector NewVelocity = MoveComp.Velocity;
        NewVelocity.Z = MoveComp.JumpForce;
        MoveComp.SetVelocity(NewVelocity);
        MoveComp.SetMovementMode(EMovementMode::MOVE_Falling);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        MoveComp.bIsJumping = false;
        bJumpHasStarted = false;
        MoveComp.SetMovementMode(EMovementMode::MOVE_Walking);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!MoveComp.IsGrounded)
            bJumpHasStarted = true;
    }

};
