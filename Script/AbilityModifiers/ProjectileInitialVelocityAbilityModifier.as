class UProjectileInitialVelocityAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    bool bCharged = true;

    UPROPERTY(EditAnywhere)
    float MinVelocityMultiplier = 1000.0f;

    UPROPERTY(EditAnywhere, meta=(EditCondition="bCharged"))
    float MaxVelocityMultiplier = 2000.0f;

    UFUNCTION(BlueprintOverride)
    void OnAbilityWarmUpTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(Ability))
            return;

        UProjectileAbilityContext AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));
        UChargedAbilityContext ChargedAbilityContext = Cast<UChargedAbilityContext>(Ability.GetOrCreateAbilityContext(UChargedAbilityContext::StaticClass()));

        if(!bCharged)
        {
            AbilityContext.InitialVelocity = Ability.HomseOwner.GetActorForwardVector() * MinVelocityMultiplier;
            return;
        }

        float ChargeRatio = ChargedAbilityContext.ChargeRatio;
        float VelocityMultiplier = Math::Lerp(MinVelocityMultiplier, MaxVelocityMultiplier, ChargeRatio);

        AbilityContext.InitialVelocity = Ability.HomseOwner.GetActorForwardVector() * VelocityMultiplier;      
    }
}