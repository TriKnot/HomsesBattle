class UTestAbilityData : UAbilityData
{
    default AbilityCapabilityClass = UAbilityCapability::StaticClass();

    UPROPERTY(EditDefaultsOnly, Instanced, BlueprintReadWrite, Category="Ability")
    UAbilityTriggerModeModifier TriggerModeModifier;

    UPROPERTY(EditDefaultsOnly, Instanced, BlueprintReadWrite, Category="Ability")
    TArray<UAbilityModifier> Modifiers;
}