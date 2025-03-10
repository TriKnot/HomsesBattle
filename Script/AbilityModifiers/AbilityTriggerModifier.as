UCLASS(Abstract, EditInlineNew)
class UAbilityTriggerModeModifier : UObject
{

    // Called when the trigger button is pressed.
    UFUNCTION(BlueprintEvent)
    void OnAbilityStart(UAbilityCapability Ability){}

    UFUNCTION(BlueprintEvent)
    void OnAbilityReleased(UAbilityCapability Ability){}

    void TriggerAbility(UAbilityCapability Ability)
    {
        if (!IsValid(Ability))
            return;

        Ability.bShouldFire = true;
    }
}

UCLASS()
class UOnAbilityStartTriggerModeAbilityModifier : UAbilityTriggerModeModifier
{
    UFUNCTION(BlueprintOverride)
    void OnAbilityStart(UAbilityCapability Ability)
    {
        TriggerAbility(Ability);
    }
}

UCLASS()
class UOnAbilityReleasedTriggerModeAbilityModifier : UAbilityTriggerModeModifier
{
    UFUNCTION(BlueprintOverride)
    void OnAbilityReleased(UAbilityCapability Ability)
    {
        TriggerAbility(Ability);
    }
}