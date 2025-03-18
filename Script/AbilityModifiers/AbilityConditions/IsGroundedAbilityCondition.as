class UIsGroundedAbilityCondition : UAbilityCondition
{
    UFUNCTION(BlueprintOverride, Category="Condition")
    bool IsConditionMet(const UAbilityCapability Ability) const
    {
        if(!Super::IsConditionMet(Ability))
            return false;

        UHomseMovementComponent MovementComponent = Cast<UHomseMovementComponent>(UHomseMovementComponent::Get(Ability.Owner));
        if (!IsValid(MovementComponent))
            return false;

        return MovementComponent.IsGrounded;
    }
}