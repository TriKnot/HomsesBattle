class UChargeAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float ChargeTime = 1.0f;

    UFUNCTION(BlueprintOverride)
    void SetupModifier(UAbilityCapability Ability)
    {
        Super::SetupModifier(Ability);
        Ability.WarmUpDuration = ChargeTime;
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        if (!IsValid(Ability))
            return;

        UChargedAbilityContext AbilityContext = Cast<UChargedAbilityContext>(Ability.GetOrCreateAbilityContext(UChargedAbilityContext::StaticClass()));
        AbilityContext.ChargeRatio = 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityWarmUpTick(UAbilityCapability Ability, float DeltaTime)
    {
        if (!IsValid(Ability))
            return;

        UChargedAbilityContext AbilityContext = Cast<UChargedAbilityContext>(Ability.GetOrCreateAbilityContext(UChargedAbilityContext::StaticClass()));
        AbilityContext.ChargeRatio = Math::Clamp(AbilityContext.ChargeRatio + (DeltaTime / ChargeTime), 0.0f, 1.0f);
    }
}