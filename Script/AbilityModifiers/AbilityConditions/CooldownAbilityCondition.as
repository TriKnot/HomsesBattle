class UCooldownOverAbilityCondition : UAbilityCondition
{
    UFUNCTION(BlueprintOverride, Category="Condition")
    bool IsConditionMet(const UAbilityCapability Ability) const
    {
        if(!Super::IsConditionMet(Ability))
            return false;

        EActiveAbilityState AbilityActiveState = Ability.AbilityState;

        if(AbilityActiveState != EActiveAbilityState::Cooldown)
            return false;

        return Ability.StateTimer.IsFinished();
    }
}