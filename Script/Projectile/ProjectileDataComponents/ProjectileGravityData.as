class UProjectileGravityData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    float GravityEffectMultiplier = 1.0f;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        UProjectileMoveComponent::GetOrCreate(Projectile).GravityData = this;
        Projectile.CapabilityComponent.AddCapability(UProjectileGravityEffectCapability::StaticClass());
    }

}