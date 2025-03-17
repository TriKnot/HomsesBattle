UCLASS(Abstract, Blueprintable)
class UAbilityContext : UObject
{
    UFUNCTION(BlueprintEvent)
    void Reset(){}
}

class UProjectileAbilityContext : UAbilityContext
{
    int ProjectileCount = 1;
    FVector InitialVelocity = FVector::ZeroVector;
    float SpreadAngle = 0.0f;
    float ChargeRatio = 0.0f;
    UProjectileData ProjectileData;
    TArray<AProjectileActor> Projectiles;

    UFUNCTION(BlueprintOverride)
    void Reset()
    {
        ProjectileCount = 1;
        InitialVelocity = FVector::ZeroVector;
        SpreadAngle = 0.0f;
        ChargeRatio = 0.0f;
        ClearAndDestroyProjectiles();
    }

    void ClearAndDestroyProjectiles()
    {
        for (AProjectileActor Projectile : Projectiles)
        {
            if (!IsValid(Projectile))
                continue;

            Projectile.DestroyActor();
        }

        Projectiles.Empty();
    }
}

class UChargedAbilityContext : UAbilityContext
{
    float ChargeRatio = 0.0f;

    UFUNCTION(BlueprintOverride)
    void Reset()
    {
        ChargeRatio = 0.0f;
    }
}

class UHitContext : UAbilityContext
{
    TArray<FHitResult> HitResults;

    UFUNCTION(BlueprintOverride)
    void Reset()
    {
        HitResults.Empty();
    }
}