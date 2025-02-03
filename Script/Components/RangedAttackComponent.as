class URangedAttackComponent : UActorComponent
{
    UPROPERTY()
    UProjectileData ProjectileData;

    UPROPERTY()
    FVector ProjectileSpawnOffset = FVector(150.0f, 0.0f, -25.0f);

    // Trajectory visualization
    UPROPERTY(Category = "Trajectory")
    UStaticMesh TrajectoryMesh;

    UPROPERTY(Category = "Trajectory")
    UMaterialInstance TrajectoryMaterial;

    USplineComponent TrajectorySpline;

    TArray<USplineMeshComponent> SplineMeshes;

    bool bIsCharging = false;
    FVector ProjectilSpawnLocation;
    FVector InitialVelocity;


    FVector CalculateSpawnLocation()
    {
        return Owner.GetActorLocation() 
            + Owner.GetActorForwardVector() * ProjectileSpawnOffset.X
            + Owner.GetActorRightVector() * ProjectileSpawnOffset.Y
            + Owner.GetActorUpVector() * ProjectileSpawnOffset.Z;
    }
};