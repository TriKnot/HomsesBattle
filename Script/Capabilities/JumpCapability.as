class UJumpCapability : UAbilityCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    UJumpAbilityData JumpAbilityData;
    UHomseMovementComponent MoveComp;
    bool bJumpHasStarted = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Super::Setup();
        MoveComp = UHomseMovementComponent::Get(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        if (MoveComp.IsLocked())
            return false;

        if(!MoveComp.IsGrounded)
            return false;

        if(AbilityComp.IsAbilityActive(this))
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
        Super::OnActivate();
        MoveComp.bIsJumping = true;
        JumpAbilityData = Cast<UJumpAbilityData>(AbilityComp.GetAbilityData(this));

        // Apply upward force for jumping
        FVector NewVelocity = MoveComp.Velocity;
        NewVelocity.Z = JumpAbilityData.JumpForce;
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
