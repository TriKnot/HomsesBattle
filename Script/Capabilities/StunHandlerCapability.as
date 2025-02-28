class UStunHandlerCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    UHomseMovementComponent MoveComp;
    UAbilityComponent AbilityComp;
    UHealthComponent HealthComp;

    float CurrentStunDuration;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(Owner);
        MoveComp = HomseOwner.HomseMovementComponent;
        AbilityComp = HomseOwner.AbilityComponent;
        HealthComp = HomseOwner.HealthComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return HealthComp.DamageInstances.Num() > 0;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return CurrentStunDuration <= 0;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        for(FDamageData DamageInstance : HealthComp.DamageInstances)
        {
            for(UOnHitEffectData OnHitEffect : DamageInstance.OnHitEffects)
            {
                UStunEffectData StunEffect = Cast<UStunEffectData>(OnHitEffect);
                if(IsValid(StunEffect))
                {
                    if(StunEffect.bAdditiveStun)
                    {
                        CurrentStunDuration += StunEffect.StunDuration;
                    } 
                    else if(StunEffect.StunDuration > CurrentStunDuration)
                    {
                        CurrentStunDuration = StunEffect.StunDuration;
                    }
                }
            }
        }

        if(CurrentStunDuration > 0)
        {
            MoveComp.Lock(this);
            AbilityComp.Lock(this);
        }
    }
    
    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        MoveComp.Unlock(this);
        AbilityComp.Unlock(this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        CurrentStunDuration -= DeltaTime;
    }
};