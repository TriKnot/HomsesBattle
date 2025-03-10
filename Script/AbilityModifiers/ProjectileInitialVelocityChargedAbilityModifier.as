class UProjectileInitialVelocityChargedAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    float MinVelocityMultiplier = 1000.0f;

    UPROPERTY(EditAnywhere)
    float MaxVelocityMultiplier = 2000.0f;

    UFUNCTION(BlueprintOverride)
    void OnAbilityTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(Ability))
            return;

        UProjectileAbilityContext AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));
        UChargedAbilityContext ChargedAbilityContext = Cast<UChargedAbilityContext>(Ability.GetOrCreateAbilityContext(UChargedAbilityContext::StaticClass()));

        float ChargeRatio = ChargedAbilityContext.ChargeRatio;
        float VelocityMultiplier = Math::Lerp(MinVelocityMultiplier, MaxVelocityMultiplier, ChargeRatio);

        AbilityContext.InitialVelocity = Ability.HomseOwner.GetActorForwardVector() * VelocityMultiplier;      
    }
}