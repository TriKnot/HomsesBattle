class UProjectileData : UDataAsset
{

    UPROPERTY(EditAnywhere, Instanced, BlueprintReadOnly, Category = "Projectile Data")
    TArray<UProjectileDataComponent> Components;
    
};
