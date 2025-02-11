class UAbilityComponent : UActorComponent
{
    UPROPERTY()
    UObject AbilityData;

    UPROPERTY()
    FName AttackSocket = n"AttackSocket";

    AHomseCharacterBase HomseOwner;

    // Optional Trajectory visualization
    USplineComponent TrajectorySpline;
    TArray<USplineMeshComponent> SplineMeshes;

    // Ability state tracking
    bool bIsCharging = false;
    FVector InitialVelocity;

    // Temporary fields ---------------------------------------------------------------------------------------------
    UPROPERTY()
    UProjectileData ProjectileData;

    UPROPERTY(Category = "Trajectory")
    UStaticMesh TrajectoryMesh;

    UPROPERTY(Category = "Trajectory")
    UMaterialInstance TrajectoryMaterial;
    // ----------------------------------------------------------------------------------------------------------------
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        HomseOwner = Cast<AHomseCharacterBase>(GetOwner());
        
        if (!IsValid(HomseOwner))
            PrintError("UAbilityComponent: Owner is not AHomseCharacterBase");
    }

    FVector GetAttackSocketLocation() property
    {
        return HomseOwner.Mesh.GetSocketLocation(AttackSocket);
    }

    // Template function to retrieve ability data cast to the correct type
    UObject GetAbilityData() 
    {
        return AbilityData;
    }
};
