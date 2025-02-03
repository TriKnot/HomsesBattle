class URangedAttackComponent : UActorComponent
{
    UPROPERTY()
    TSubclassOf<AProjectileActorBase> ProjectileClass;

    UPROPERTY()
    UMaterialInstance SimulatedProjectileTrajectoryMaterial;

    UPROPERTY()
    FVector ProjectileSpawnOffset = FVector(150.0f, 0.0f, -25.0f);

    UPROPERTY()
    USplineComponent SimulatedProjectileTrajectorySpline;

    UPROPERTY()
    USplineMeshComponent SimulatedProjectileTrajectoryMesh;

    float Gravity = 9810.0f;
};