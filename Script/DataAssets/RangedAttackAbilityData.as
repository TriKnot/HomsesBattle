class URangedAttackData : UAbilityData
{
    // Projectile settings
    UPROPERTY()
    UProjectileData ProjectileData;

    // Charge settings
    UPROPERTY()
    float MaxChargeTime = 2.0f;

    UPROPERTY()
    float InitialVelocityMultiplier = 1.0f;

    UPROPERTY()
    float MaxVelocityMultiplier = 2.5f;

    UPROPERTY()
    float InitialZAngleMultiplier = 1.0f;

    UPROPERTY()
    bool UseControllerZ = false;

    UPROPERTY()
    bool ChargedShot = false;

    UPROPERTY()
    FName Socket = n"AttackSocket";

    UPROPERTY(Category = "Trajectory")
    bool DisplayTrajectory = false;

    UPROPERTY(Category = "Trajectory")
    UStaticMesh TrajectoryMesh;

    UPROPERTY(Category = "Trajectory")
    UMaterialInstance TrajectoryMaterial;
};
