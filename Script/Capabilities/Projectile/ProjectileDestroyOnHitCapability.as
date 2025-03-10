class UProjectileDestroyOnHitCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    AProjectileActor ProjectileOwner;
    UProjectileDamageComponent DamageComponent;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
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
        ProjectileOwner.DestroyActor();
    }

};