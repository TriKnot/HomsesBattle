class UProjectileInitialZVelocityAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    bool bUseControllerZAngle = false;

    UFUNCTION(BlueprintOverride)
    void OnAbilityWarmUpTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(Ability))
            return;

        UProjectileAbilityContext AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));
        if (!IsValid(AbilityContext))
            return;

        float VelocityMagnitude = AbilityContext.InitialVelocity.Size();
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

        float HorizontalMagnitude = FVector(NewInitialVelocity.X, NewInitialVelocity.Y, 0.0f).Size();
        float AdditionalZ = HorizontalMagnitude;
        NewInitialVelocity.Z += AdditionalZ;

        NewInitialVelocity *= VelocityMagnitude;
        AbilityContext.InitialVelocity = NewInitialVelocity;
    }
}