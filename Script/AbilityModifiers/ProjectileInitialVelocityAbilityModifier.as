class UProjectileInitialVelocityAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    float VelocityMultiplier = 1000.0f;

    UFUNCTION(BlueprintOverride)
    void ModifyFire(UAbilityCapability Ability)
    {
        if(!IsValid(Ability))
            return;

        UProjectileAbilityContext AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));

        AbilityContext.InitialVelocity = Ability.HomseOwner.GetActorForwardVector() * VelocityMultiplier;      
    }

}
