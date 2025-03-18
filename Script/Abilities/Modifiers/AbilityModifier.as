UCLASS(Abstract, EditInlineNew)
class UAbilityModifier : UObject
{
    UFUNCTION(BlueprintEvent)
    void SetupModifier(UAbilityCapability Ability){}

    UFUNCTION(BlueprintEvent)
    void TeardownModifier(UAbilityCapability Ability){}

    UFUNCTION(BlueprintEvent)
    void OnAbilityActivate(UAbilityCapability Ability){}

    UFUNCTION(BlueprintEvent)
    void OnAbilityDeactivate(UAbilityCapability Ability){}

    UFUNCTION(BlueprintEvent)
    void OnAbilityWarmUpTick(UAbilityCapability Ability, float DeltaTime){}

    UFUNCTION(BlueprintEvent)
    void OnAbilityActiveTick(UAbilityCapability Ability, float DeltaTime){}

    UFUNCTION(BlueprintEvent)
    void OnAbilityCooldownTick(UAbilityCapability Ability, float DeltaTime){}

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
    WarmUp,
    Active,
    Cooldown,
    Fire
}