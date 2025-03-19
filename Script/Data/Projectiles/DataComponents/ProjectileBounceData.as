class UProjectileBounceData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Bounce Settings", meta = (ClampMin = 1))
    int MaxBounces = 1;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Bounce Settings", meta = (ClampMin = 0, ClampMax = 1))
    float BounceEnergyLoss = 0.5f;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileBounceCapability::StaticClass());

        UProjectileDamageComponent::GetOrCreate(Projectile).bAllowDestroy = false;
        UProjectileMoveComponent MoveComp = UProjectileMoveComponent::GetOrCreate(Projectile);
        MoveComp.MaxBounces = MaxBounces;
        MoveComp.BounceEnergyLoss = BounceEnergyLoss;
    }
};
