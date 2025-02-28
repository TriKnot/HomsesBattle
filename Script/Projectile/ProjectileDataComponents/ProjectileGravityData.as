class UProjectileGravityData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    float GravityEffectMultiplier = 1.0f;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.SetGravityData(this);
    }

}