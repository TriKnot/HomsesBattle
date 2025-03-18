class UCooldownAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float CooldownDuration; 

    UFUNCTION(BlueprintOverride)
    void SetupModifier(UAbilityCapability Ability)
    {
        Super::SetupModifier(Ability);
        Ability.CooldownDuration = CooldownDuration;
    }

};