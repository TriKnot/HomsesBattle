class UChargeAbilityModifier : UAbilityModifier
{
    // The time it takes to charge the ability from 0 to 1.
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float ChargeTime = 1.0f;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        if (!IsValid(Ability))
            return;

        UChargedAbilityContext AbilityContext = Cast<UChargedAbilityContext>(Ability.GetOrCreateAbilityContext(UChargedAbilityContext::StaticClass()));
        AbilityContext.ChargeRatio = 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityTick(UAbilityCapability Ability, float DeltaTime)
    {
        if (!IsValid(Ability))
            return;

        UChargedAbilityContext AbilityContext = Cast<UChargedAbilityContext>(Ability.GetOrCreateAbilityContext(UChargedAbilityContext::StaticClass()));
        AbilityContext.ChargeRatio = Math::Clamp(AbilityContext.ChargeRatio + (DeltaTime / ChargeTime), 0.0f, 1.0f);
    }
}