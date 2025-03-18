class UDamageHandlerCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    UHealthComponent HealthComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(Owner);
        HealthComp = HomseOwner.HealthComponent;
    }

    UFUNCTION(BlueprintOverride)
    void Teardown()
    {
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return HealthComp.CurrentHealth > 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return HealthComp.CurrentHealth <= 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(HealthComp.bIsInvulnerable)
            return;

        while(!HealthComp.DamageInstances.IsEmpty())
        {
            FDamageData DamageInstance = HealthComp.DamageInstances[0];
            HealthComp.RemoveDamageInstance(DamageInstance);

            HealthComp.CurrentHealth -= DamageInstance.DamageAmount;
            if(HealthComp.CurrentHealth <= 0.0f)
            {
                HealthComp.CurrentHealth = 0.0f;
                break;
            }
        }
    }
};