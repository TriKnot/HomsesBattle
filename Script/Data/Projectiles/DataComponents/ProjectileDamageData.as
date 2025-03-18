class UProjectileDamageData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    FDamageData DamageData;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileDamageCapability::StaticClass());
        UProjectileDamageComponent::GetOrCreate(Projectile).DamageDataAsset = this;
    }
}