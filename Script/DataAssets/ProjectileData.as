class UProjectileData : UDataAsset
{
    UPROPERTY()
    float GravityEffectMultiplier = 1.0f;

    UPROPERTY()
    FDamageData DamageData;

    UPROPERTY()
    UStaticMesh ProjectileMesh;

    UPROPERTY()
    FVector Scale = FVector(1.0f, 1.0f, 1.0f);
} 