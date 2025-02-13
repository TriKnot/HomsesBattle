class UProjectileData : UDataAsset
{
    UPROPERTY(Category = "Movement")
    float GravityEffectMultiplier = 1.0f;

    UPROPERTY(Category = "Damage")
    float Damage = 10.0f;

    UPROPERTY(Category = "Visuals")
    UStaticMesh ProjectileMesh;

    UPROPERTY(Category = "Transform")
    FVector Scale = FVector(1.0f, 1.0f, 1.0f);

} 