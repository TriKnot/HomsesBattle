class UProjectileDamageCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;
    UProjectileDamageComponent DamageComponent;
    TArray<AActor> DamagedActors;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
        DamageComponent = UProjectileDamageComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated && DamageComponent.MovementHitResult.bBlockingHit;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        OnHit(DamageComponent.MovementHitResult.GetActor());
    }
    

    UFUNCTION(BlueprintEvent)
    void OnHit(AActor HitActor) 
    {
        if(DamageComponent.IgnoredActors.Contains(HitActor)
        || DamagedActors.Contains(HitActor))
            return;

        TryDealDamage(HitActor);
    };


    void TryDealDamage(AActor HitActor)
    {
        UHealthComponent HealthComp = Cast<UHealthComponent>(HitActor.GetComponentByClass(UHealthComponent::StaticClass()));
        if(HealthComp != nullptr)
        {
            FDamageData DamageInstance = DamageComponent.DamageDataAsset.DamageData;
            DamageInstance.SetSourceActor(Owner);
            DamageInstance.SetDamageLocation(HitActor.ActorLocation);

            HealthComp.AddDamageInstanceData(DamageInstance);
            DamagedActors.AddUnique(HitActor);
        }
    }
}