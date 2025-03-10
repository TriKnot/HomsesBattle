class ULockAbilityComponentModifier : UAbilityModifier
{
    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        Ability.AbilityComp.Lock(Ability);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityDeactivate(UAbilityCapability Ability)
    {
        Ability.AbilityComp.Unlock(Ability);
    }
}