class UProjectileDestroyOnHitCapability : UCapability
{
    default Priority = ECapabilityPriority::MAX;

    AProjectileActor ProjectileOwner;
    UProjectileCollisionComponent CollisionComponent;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        CollisionComponent = UProjectileCollisionComponent::GetOrCreate(ProjectileOwner);
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
        ProjectileOwner.DestroyActor();
    }
};