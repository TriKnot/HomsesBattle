class UProjectileDisplayTrajectoryAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    FName LaunchSocketName;

    UPROPERTY(EditAnywhere, Category="Visual")
    UStaticMesh TrajectoryMesh;

    UPROPERTY(EditAnywhere, Category="Visual")
    UMaterialInterface TrajectoryMaterial;

    UPROPERTY(EditDefaultsOnly, Category="Simulation")
    float DesiredStepsPerSec = 10.0f; 

    UPROPERTY(EditAnywhere, Category="Visual")
    float MeshSegmentLength = 250.0f;
        
    UPROPERTY(EditAnywhere, Category="Visual")
    float GapLengthBetweenMeshSegements = 0.0f;

    UTrajectoryVisualization TrajectoryVisualization;
    UProjectileAbilityContext AbilityContext;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));
        float GravityEffectMultiplier = GetGravityData(AbilityContext.ProjectileData);
        TrajectoryVisualization = Cast<UTrajectoryVisualization>(NewObject(this, UTrajectoryVisualization::StaticClass()));
        
        if (IsValid(TrajectoryVisualization))
        {
            TrajectoryVisualization.Init(Ability.Owner, TrajectoryMesh, TrajectoryMaterial, GravityEffectMultiplier, 
                DesiredStepsPerSec, MeshSegmentLength, GapLengthBetweenMeshSegements);
        }
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityDeactivate(UAbilityCapability Ability)
    {
        TrajectoryVisualization.Clear();
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityWarmUpTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(Ability))
            return;

        DisplayTrajectory(Ability);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityActiveTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(Ability))
            return;

        DisplayTrajectory(Ability);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityFire(UAbilityCapability Ability)
    {
        TrajectoryVisualization.Clear();
    }

    void DisplayTrajectory(UAbilityCapability Ability)
    {
        FVector SocketLocation = Ability.HomseOwner.Mesh.GetSocketLocation(LaunchSocketName);
        TrajectoryVisualization.Simulate(SocketLocation, AbilityContext.InitialVelocity);
    }

    float GetGravityData(UProjectileData Data)
    {
        if(!IsValid(Data))
            return 1.0f;

        for(UProjectileDataComponent DataComp : Data.Components)
        {
            if(DataComp.IsA(UProjectileGravityData::StaticClass()))
            {
                return Cast<UProjectileGravityData>(DataComp).GravityEffectMultiplier;
                
            }
        }
        return 0.0f;
    }

}