class UProjectileMeshData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    UStaticMesh ProjectileMesh;

    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    FVector Scale = FVector(1.0f, 1.0f, 1.0f);

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.SetMeshData(this);
    }
}