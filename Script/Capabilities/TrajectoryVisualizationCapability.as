class UTrajectoryVisualizationCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;
    
    UCapabilityComponent CapComp;
    UAbilityComponent AbilityComp;
    UProjectileData ProjectileData;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(Owner);
        AbilityComp = HomseOwner.AbilityComponent;
        CapComp = HomseOwner.CapabilityComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return AbilityComp.bIsCharging && AbilityComp.ProjectileData.DisplayTrajectory;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return !AbilityComp.bIsCharging;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        ProjectileData = AbilityComp.ProjectileData;
        AbilityComp.TrajectorySpline = USplineComponent::Create(Owner);
        AbilityComp.TrajectorySpline.AttachToComponent(Owner.RootComponent);
        AbilityComp.TrajectorySpline.SetMobility(EComponentMobility::Movable);
        AbilityComp.TrajectorySpline.SetSimulatePhysics(false);
        AbilityComp.TrajectorySpline.SetCollisionEnabled(ECollisionEnabled::NoCollision);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        ClearSimulatedTrajectory(AbilityComp.TrajectorySpline, AbilityComp.SplineMeshes);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        TArray<FVector> Points = SimulateProjectileTrajectory(
            AbilityComp.AttackSocketLocation, 
            AbilityComp.InitialVelocity, 
            1.0f, 
            0.01f);
        DrawSimulatedTrajectory(Points, ProjectileData);
    }

    TArray<FVector> SimulateProjectileTrajectory(const FVector& InitialPosition, const FVector& InitialVelocity, float SimulationTime, float TimeStep)
    {
        FVector Position = InitialPosition;
        FVector Velocity = InitialVelocity;
        TArray<FVector> Points;
        Points.Add(Position);

        for (float t = 0; t <= SimulationTime; t += TimeStep)
        {
            Velocity.Z -= PhysicStatics::Gravity * ProjectileData.GravityEffectMultiplier * TimeStep;
            Position += Velocity * TimeStep;
            Points.Add(Position);
        }

        return Points;
    }

    void DrawSimulatedTrajectory(const TArray<FVector>& Points, UProjectileData Data)
    {
        USplineComponent Spline = AbilityComp.TrajectorySpline;
        Spline.ClearSplinePoints();
        ClearSimulatedTrajectory(AbilityComp.TrajectorySpline, AbilityComp.SplineMeshes);

        for (int i = 0; i < Points.Num(); ++i)
        {
            Spline.AddSplinePoint(Points[i], ESplineCoordinateSpace::World, false);
        }
        Spline.SetSplinePointType(Points.Num() - 1, ESplinePointType::CurveClamped, true);

        for (int i = 0; i < Points.Num() - 1; ++i)
        {
            USplineMeshComponent SplineMesh = USplineMeshComponent::Create(Owner);
            SplineMesh.AttachToComponent(Spline);
            SplineMesh.SetMobility(EComponentMobility::Movable);
            SplineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            SplineMesh.SetStartScale(FVector2D(0.1f, 0.1f));
            SplineMesh.SetEndScale(FVector2D(0.1f, 0.1f));
            SplineMesh.SetStaticMesh(AbilityComp.TrajectoryMesh);
            SplineMesh.SetMaterial(0, AbilityComp.TrajectoryMaterial);

            FVector StartPos, StartTangent, EndPos, EndTangent;
            Spline.GetLocationAndTangentAtSplinePoint(i, StartPos, StartTangent, ESplineCoordinateSpace::Local);
            Spline.GetLocationAndTangentAtSplinePoint(i + 1, EndPos, EndTangent, ESplineCoordinateSpace::Local);

            SplineMesh.SetStartAndEnd(StartPos, StartTangent, EndPos, EndTangent);

            AbilityComp.SplineMeshes.Add(SplineMesh);
        }
    }

    void ClearSimulatedTrajectory(USplineComponent Spline, TArray<USplineMeshComponent>&in SplineMeshes)
    {
        Spline.ClearSplinePoints();
        for (USplineMeshComponent Mesh : SplineMeshes)
        {
            Mesh.DestroyComponent(Mesh);
        }
        SplineMeshes.Empty();
    }
}