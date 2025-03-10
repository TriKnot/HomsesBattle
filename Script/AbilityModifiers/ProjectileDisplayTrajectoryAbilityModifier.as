class UProjectileDisplayTrajectoryAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    FName LaunchSocketName;

    UPROPERTY(EditAnywhere)
    UStaticMesh TrajectoryMesh;

    UPROPERTY(EditAnywhere)
    UMaterialInterface TrajectoryMaterial;

    UTrajectoryVisualization TrajectoryVisualization;
    float GravityEffectMultiplier;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        UProjectileAbilityContext AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));
        GravityEffectMultiplier = GetGravityData(AbilityContext.ProjectileData);

        TrajectoryVisualization = Cast<UTrajectoryVisualization>(NewObject(this, UTrajectoryVisualization::StaticClass()));
        
        if (IsValid(TrajectoryVisualization))
        {
            TrajectoryVisualization.Init(Ability.Owner, TrajectoryMesh, TrajectoryMaterial, GravityEffectMultiplier);
        }
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(Ability))
            return;

        UProjectileAbilityContext AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));

        TrajectoryVisualization.ClearSimulatedTrajectory();
        FVector SocketLocation = Ability.HomseOwner.Mesh.GetSocketLocation(LaunchSocketName);
        TrajectoryVisualization.Simulate(SocketLocation, AbilityContext.InitialVelocity);

    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityFire(UAbilityCapability Ability)
    {
        TrajectoryVisualization.ClearSimulatedTrajectory();
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