class UProjectileDamageCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    AProjectileActor ProjectileOwner;
    UProjectileDamageComponent DamageComponent;
    UProjectileCollisionComponent CollisionComponent;
    TArray<AActor> DamagedActors;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        DamageComponent = UProjectileDamageComponent::GetOrCreate(ProjectileOwner);
        CollisionComponent = UProjectileCollisionComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated 
            && CollisionComponent.MovementHitResult.bBlockingHit;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        OnHit(CollisionComponent.MovementHitResult.GetActor());
    }
    

    UFUNCTION(BlueprintEvent)
    void OnHit(AActor HitActor) 
    {
        if(CollisionComponent.IgnoredActors.Contains(HitActor)
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