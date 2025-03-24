class UProjectileOscillationData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere)
    TArray<FOscillationData> OscillationDatas;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileOscillationCapability::StaticClass());

        UProjectileMoveComponent MoveComp = UProjectileMoveComponent::GetOrCreate(Projectile);
        MoveComp.OscillationDatas = OscillationDatas;
    }
};
