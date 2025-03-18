class UInputActiveAbilityCondition : UAbilityCondition
{
    UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category="Condition")
    FName InputActionName;

    UFUNCTION(BlueprintOverride, Category="Condition")
    bool IsConditionMet(const UAbilityCapability Ability) const
    {
        if(!Super::IsConditionMet(Ability))
            return false;

        UCapabilityComponent CapComp = UCapabilityComponent::Get(Ability.Owner);

        if(!IsValid(CapComp))
            return false;
        

        return CapComp.GetActionStatus(InputActionName);
    }
}