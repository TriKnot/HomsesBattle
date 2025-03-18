class UJumpAbilityModifier : UAbilityModifier
{
    UPROPERTY()
    float JumpForce;;

    UHomseMovementComponent MoveComp;

    UFUNCTION(BlueprintOverride)
    void SetupModifier(UAbilityCapability Ability)
    {
        MoveComp = UHomseMovementComponent::Get(Ability.Owner);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        MoveComp.bIsJumping = true;

        FVector NewVelocity = MoveComp.Velocity;
        NewVelocity.Z = JumpForce;
        MoveComp.SetVelocity(NewVelocity);
        MoveComp.SetMovementMode(EMovementMode::MOVE_Falling);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(MoveComp.IsGrounded)
        {
            MoveComp.SetMovementMode(EMovementMode::MOVE_Walking);
            MoveComp.bIsJumping = false;
        }
    }

}