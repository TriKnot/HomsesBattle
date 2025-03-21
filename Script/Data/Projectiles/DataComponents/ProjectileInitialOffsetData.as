class UProjectileInitialOffsetData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, Category = "Offset")
    FVector InitialOffset;

    UPROPERTY(EditAnywhere, Category = "Offset", meta = (ClampMin = "0.001"))
    float OffsetLerpTime;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileOffsetOnSpawnCapability::StaticClass());

        UProjectileMoveComponent OffsetComp = UProjectileMoveComponent::GetOrCreate(Projectile);

        OffsetComp.InitialOffset = InitialOffset;
        OffsetComp.OffsetLerpTime = OffsetLerpTime;
    }
};