class UProjectileDamageData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    FDamageData DamageData;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.SetDamageData(this);
    }
}