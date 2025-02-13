class UTrajectoryVisualization : UObject
{
    URangedAttackData AttackData;
    USplineComponent TrajectorySpline;
    TArray<USplineMeshComponent> SplineMeshes;
    AActor Owner;

    void Init(URangedAttackData Data, AActor OwningActor)
    {
        AttackData = Data;
        Owner = OwningActor;
        TrajectorySpline = USplineComponent::Create(Owner);
        TrajectorySpline.AttachToComponent(Owner.RootComponent);
        TrajectorySpline.SetMobility(EComponentMobility::Movable);
        TrajectorySpline.SetSimulatePhysics(false);
        TrajectorySpline.SetCollisionEnabled(ECollisionEnabled::NoCollision);
    }

    void Clear()
    {
        TrajectorySpline.DestroyComponent(TrajectorySpline);
        for (USplineMeshComponent Mesh : SplineMeshes)
        {
            Mesh.DestroyComponent(Mesh);
        }
        SplineMeshes.Empty();
    }

    void ClearSimulatedTrajectory()
    {
        TrajectorySpline.ClearSplinePoints();
        for (USplineMeshComponent Mesh : SplineMeshes)
        {
            Mesh.DestroyComponent(Mesh);
        }
        SplineMeshes.Empty();
    }

    void Simulate(FVector StartLocation, FVector InitialVelocity)
    {
        TArray<FVector> Points = GetSimulatedTrajectoryPoints(
            StartLocation, 
            InitialVelocity, 
            AttackData.ProjectileData.GravityEffectMultiplier,
            1.0f, 
            0.01f);
        DrawSimulatedTrajectory(Points, AttackData.ProjectileData);
    }


    TArray<FVector> GetSimulatedTrajectoryPoints(const FVector& InitialPosition, const FVector& InitialVelocity, float GravityEffectMultiplier, float SimulationTime, float TimeStep)
    {
        FVector Position = InitialPosition;
        FVector Velocity = InitialVelocity;
        TArray<FVector> Points;
        Points.Add(Position);

        for (float t = 0; t <= SimulationTime; t += TimeStep)
        {
            Velocity.Z -= PhysicStatics::Gravity * GravityEffectMultiplier * TimeStep;
            Position += Velocity * TimeStep;
            Points.Add(Position);
        }

        return Points;
    }

    void DrawSimulatedTrajectory(const TArray<FVector>& Points, UProjectileData Data)
    {
        USplineComponent Spline = TrajectorySpline;
        Spline.ClearSplinePoints();
        ClearSimulatedTrajectory();

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
            SplineMesh.SetStaticMesh(AttackData.TrajectoryMesh);
            SplineMesh.SetMaterial(0, AttackData.TrajectoryMaterial);

            FVector StartPos, StartTangent, EndPos, EndTangent;
            Spline.GetLocationAndTangentAtSplinePoint(i, StartPos, StartTangent, ESplineCoordinateSpace::Local);
            Spline.GetLocationAndTangentAtSplinePoint(i + 1, EndPos, EndTangent, ESplineCoordinateSpace::Local);

            SplineMesh.SetStartAndEnd(StartPos, StartTangent, EndPos, EndTangent);

            SplineMeshes.Add(SplineMesh);
        }
    }


}