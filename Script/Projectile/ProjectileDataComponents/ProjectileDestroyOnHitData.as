class UProjectileDestroyOnHitData : UProjectileDataComponent
{
    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileDestroyOnHitCapability::StaticClass());
    }
}