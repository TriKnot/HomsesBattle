class UComponentLockedCondition : UAbilityCondition
{
    UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category="Condition")
    TSubclassOf<ULockableComponent> ComponentClass;

    UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category="Condition")
    bool bIgnoreLockedByThisAbility = false;

    UFUNCTION(BlueprintOverride, Category="Condition")
    bool IsConditionMet(const UAbilityCapability Ability) const
    {
        if(!Super::IsConditionMet(Ability))
            return false;

        ULockableComponent Component = Cast<ULockableComponent>(Ability.Owner.GetComponentByClass(ComponentClass));
        if (!IsValid(Component))
            return false;

        return bIgnoreLockedByThisAbility ? Component.IsLocked(Ability) : Component.IsLocked();
    }
}