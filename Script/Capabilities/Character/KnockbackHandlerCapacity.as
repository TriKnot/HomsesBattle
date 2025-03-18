class UKnockbackHandlerCapacity : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    UHomseMovementComponent MoveComp;
    UHealthComponent HealthComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(Owner);
        MoveComp = HomseOwner.HomseMovementComponent;
        HealthComp = HomseOwner.HealthComponent;
    }

    UFUNCTION(BlueprintOverride)
    void Teardown()
    {
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return HealthComp.DamageInstances.Num() > 0;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        for(FDamageData DamageInstance : HealthComp.DamageInstances)
        {
            for(UOnHitEffectData OnHitEffect : DamageInstance.OnHitEffects)
            {
                UKnockbackEffectData KnockbackEffect = Cast<UKnockbackEffectData>(OnHitEffect);
                if(IsValid(KnockbackEffect))
                {
                    HandleKnockback(KnockbackEffect, DamageInstance.DamageDirection);
                }
            }
        }
    }

    void HandleKnockback(UKnockbackEffectData Data, const FVector& Direction)
    {
        UAsyncRootMovement AsyncRootMove = UAsyncRootMovement::ApplyConstantForce
        (
            MoveComp.CharacterMovement, 
            Direction, 
            Data.KnockbackForce, 
            Data.KnockbackDuration, 
            true, 
            nullptr,
            true, 
            ERootMotionFinishVelocityMode::MaintainLastRootMotionVelocity
        );
    }

};