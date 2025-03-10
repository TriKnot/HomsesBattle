class UProjectileInitialZVelocityChargedAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    bool bUseControllerZAngle = false;

    UFUNCTION(BlueprintOverride)
    void OnAbilityTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(Ability))
            return;

        UProjectileAbilityContext AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));
        UChargedAbilityContext ChargedAbilityContext = Cast<UChargedAbilityContext>(Ability.GetOrCreateAbilityContext(UChargedAbilityContext::StaticClass()));

        float VelocityMagnitude = AbilityContext.InitialVelocity.Size();
        float ChargeRatio = ChargedAbilityContext.ChargeRatio;
        FVector NewInitialVelocity = AbilityContext.InitialVelocity.GetSafeNormal();

        if(bUseControllerZAngle)
        {
            AController Controller = Ability.HomseOwner.GetController();
            if(IsValid(Controller))
            {
                FVector ControllerRotation = Controller.GetControlRotation().Vector();
                NewInitialVelocity.Z = ControllerRotation.Z;
            }
        }

        NewInitialVelocity.Z += ChargeRatio;
        NewInitialVelocity *= VelocityMagnitude;

        AbilityContext.InitialVelocity = NewInitialVelocity;
    }
}