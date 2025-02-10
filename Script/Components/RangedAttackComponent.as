class URangedAttackComponent : UActorComponent
{
    UPROPERTY()
    UProjectileData ProjectileData;

    UPROPERTY()
    FVector ProjectileSpawnOffset = FVector(150.0f, 0.0f, -25.0f);

    UPROPERTY()
    FName AttackSocket = n"AttackSocket";

    // Trajectory visualization
    UPROPERTY(Category = "Trajectory")
    UStaticMesh TrajectoryMesh;

    UPROPERTY(Category = "Trajectory")
    UMaterialInstance TrajectoryMaterial;

    AHomseCharacterBase HomseOwner;

    // Trajectory visualization
    USplineComponent TrajectorySpline;
    TArray<USplineMeshComponent> SplineMeshes;
    bool bIsCharging = false;
    FVector InitialVelocity;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        HomseOwner = Cast<AHomseCharacterBase>(GetOwner());
        
        if(!IsValid(HomseOwner))
            PrintError("URangedAttackComponent: Owner is not AHomseCharacterBase");
    }

    FVector GetAttackSocketLocation() property
    {
        return HomseOwner.Mesh.GetSocketLocation(AttackSocket);
    }

};