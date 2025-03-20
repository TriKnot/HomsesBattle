class UProjectileSpawnActorOnDestroyCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    AProjectileActor ProjectileOwner;
    UProjectileCollisionComponent CollisionComponent;
    UProjectileSpawnActorComponent EffectComponent;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        CollisionComponent = UProjectileCollisionComponent::GetOrCreate(ProjectileOwner);
        EffectComponent = UProjectileSpawnActorComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated 
            && CollisionComponent.MovementHitResult.bBlockingHit
            && CollisionComponent.bAllowDestroy; 
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return true; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        SpawnEffect();
    }

    void SpawnEffect()
    {
        if (!IsValid(EffectComponent.EffectActorClass))
            return;

        FHitResult& Hit = CollisionComponent.MovementHitResult;

        // Spawn effect at hit location and orientation
        FTransform SpawnTransform;
        SpawnTransform.Location = Hit.ImpactPoint;
        SpawnTransform.Rotation = Hit.ImpactNormal.Rotation().Quaternion();

        SpawnActor(EffectComponent.EffectActorClass, SpawnTransform.Location, SpawnTransform.Rotation.Rotator());
    }
};
