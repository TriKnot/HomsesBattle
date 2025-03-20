class UProjectileBounceData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Bounce Settings", meta = (ClampMin = 1))
    int MaxBounces = 1;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Bounce Settings", meta = (ClampMin = 0))
    float EnergyOnBounceMultiplier = 1.0f;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileBounceCapability::StaticClass());

        UProjectileCollisionComponent::GetOrCreate(Projectile).bAllowDestroy = false;
        UProjectileBounceComponent MoveComp = UProjectileBounceComponent::GetOrCreate(Projectile);
        MoveComp.MaxBounces = MaxBounces;
        MoveComp.EnergyOnBounceMultiplier = EnergyOnBounceMultiplier;
    }
};
