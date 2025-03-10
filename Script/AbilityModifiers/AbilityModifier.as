UCLASS(Abstract, EditInlineNew)
class UAbilityModifier : UObject
{
    UFUNCTION(BlueprintEvent)
    void OnAbilityActivate(UAbilityCapability Ability){}

    UFUNCTION(BlueprintEvent)
    void OnAbilityDeactivate(UAbilityCapability Ability){}

    UFUNCTION(BlueprintEvent)
    void OnAbilityTick(UAbilityCapability Ability, float DeltaTime){}

    UFUNCTION(BlueprintEvent)
    void ModifyFire(UAbilityCapability Ability){}

    UFUNCTION(BlueprintEvent)
    void OnAbilityFire(UAbilityCapability Ability){}
}

enum EAbilityPhase
{
    None, 
    Activation,
    Deactivation,
    Tick,
    Fire
}