class UProjectileData : UDataAsset
{
    UPROPERTY(Category = "Movement")
    float InitialVelocityMultiplier = 1500.0f;

    UPROPERTY(Category = "Movement")
    float MaxVelocityMultiplier = 3000.0f;

    UPROPERTY(Category = "Movement")
    float MaxChargeTime = 1.0f;

    UPROPERTY(Category = "Movement")
    float GravityEffectMultiplier = 1.0f;

    UPROPERTY(Category = "Movement")
    float InitialZAngleMultiplier = 1.0f;

    UPROPERTY(Category = "Damage")
    float CooldownTime = 1.0f;

    UPROPERTY(Category = "Damage")
    bool AutoFireAtMaxCharge = false;

    UPROPERTY(Category = "Damage")
    float Damage = 10.0f;

    UPROPERTY(Category = "Visuals")
    UStaticMesh ProjectileMesh;

    UPROPERTY(Category = "Visuals")
    bool DisplayTrajectory = false;

    UPROPERTY(Category = "Transform")
    FVector Scale = FVector(1.0f, 1.0f, 1.0f);

} 