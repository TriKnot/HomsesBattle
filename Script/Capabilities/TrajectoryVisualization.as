class UTrajectoryVisualization : UObject
{
    float GravityMult;
    USplineComponent TrajectorySpline;
    TArray<USplineMeshComponent> SplineMeshes;
    UStaticMesh TrajectoryMesh;
    UMaterialInterface TrajectoryMaterial;
    AActor Owner;

    // Trace data
    TArray<AActor> ActorsToIgnore;
    TArray<EObjectTypeQuery> ObjectTypes;
    default ObjectTypes.Add(UCollisionProfile::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));
    default ObjectTypes.Add(UCollisionProfile::ConvertToObjectType(ECollisionChannel::ECC_WorldDynamic));

    float DesiredResolution = 100.0f; 

    void Init(URangedAttackData Data, AActor OwningActor)
    {
        TrajectoryMesh = Data.TrajectoryMesh;
        TrajectoryMaterial = Data.TrajectoryMaterial;
        GravityMult = GetGravityData(Data);
        Owner = OwningActor;
        TrajectorySpline = USplineComponent::Create(Owner);
        TrajectorySpline.AttachToComponent(Owner.RootComponent);
        TrajectorySpline.SetMobility(EComponentMobility::Movable);
        TrajectorySpline.SetSimulatePhysics(false);
        TrajectorySpline.SetCollisionEnabled(ECollisionEnabled::NoCollision);
        ActorsToIgnore.AddUnique(Owner);
    }

    void Init(AActor OwningActor, UStaticMesh Mesh, UMaterialInterface Material, float GravityMultiplier)
    {
        TrajectoryMesh = Mesh;
        TrajectoryMaterial = Material;
        GravityMult = GravityMultiplier;
        Owner = OwningActor;
        TrajectorySpline = USplineComponent::Create(Owner);
        TrajectorySpline.AttachToComponent(Owner.RootComponent);
        TrajectorySpline.SetMobility(EComponentMobility::Movable);
        TrajectorySpline.SetSimulatePhysics(false);
        TrajectorySpline.SetCollisionEnabled(ECollisionEnabled::NoCollision);
    }

    void Clear()
    {
        if(IsValid(TrajectorySpline))
            TrajectorySpline.DestroyComponent(TrajectorySpline);

        for (USplineMeshComponent Mesh : SplineMeshes)
        {
            Mesh.DestroyComponent(Mesh);
        }
        SplineMeshes.Empty();
    }

    float ComputeDynamicMaxSimulationTime(const FVector& InitialVelocity)
    {
        float Gravity = PhysicStatics::Gravity * GravityMult;
        if (InitialVelocity.Z > 0)
        {
            return (2 * InitialVelocity.Z) / Gravity;
        }

        return 1.0f;
    }

    float ComputeTimeStep(const FVector& InitialVelocity)
    {
        float Speed = InitialVelocity.Size();
        float TimeStep = DesiredResolution / Speed;

        return Math::Clamp(TimeStep, 0.005f, 0.05f);
    }

    void ClearSimulatedTrajectory()
    {
        if(IsValid(TrajectorySpline))
            TrajectorySpline.ClearSplinePoints();

        for (USplineMeshComponent Mesh : SplineMeshes)
        {
            if(IsValid(Mesh))
                Mesh.DestroyComponent(Mesh);
        }
        SplineMeshes.Empty();
    }

    void Simulate(FVector StartLocation, FVector InitialVelocity)
    {
        TArray<FVector> Points = GetSimulatedTrajectoryPoints(
            StartLocation, 
            InitialVelocity, 
            GravityMult);
        DrawSimulatedTrajectory(Points);
    }


    TArray<FVector> GetSimulatedTrajectoryPoints(const FVector& InitialPosition, const FVector& InitialVelocity, float GravityEffectMultiplier)
    {
        float MaxSimulationTime = ComputeDynamicMaxSimulationTime(InitialVelocity);
        float TimeStep = ComputeTimeStep(InitialVelocity);

        FVector Position = InitialPosition;
        FVector Velocity = InitialVelocity;
        TArray<FVector> Points;
        Points.Add(Position);

        float TotalSquaredDistance = 0.0f;
        float MaxDistance = 10000.0f;
        float MaxDistanceSquared = MaxDistance * MaxDistance;

        for (float t = 0; t <= MaxSimulationTime; t += TimeStep)
        {
            FVector OldPosition = Position;

            Velocity.Z -= PhysicStatics::Gravity * GravityEffectMultiplier * TimeStep;
            Position += Velocity * TimeStep;
            TotalSquaredDistance += OldPosition.DistSquared(Position);

            if (TotalSquaredDistance > MaxDistanceSquared)
            {
                Points.Add(Position);
                break;
            }

            FHitResult Hit;
            System::LineTraceSingleForObjects(
                OldPosition,
                Position,
                ObjectTypes,
                false,
                ActorsToIgnore,
                EDrawDebugTrace::None, 
                Hit,
                true
            );          
            if(Hit.bBlockingHit)      
            {
                Points.Add(Hit.Location);
                //System::DrawDebugBox(Hit.Location, FVector(2.0f, 2.0f, 2.0f), FLinearColor::Red);
                break;
            }

            Points.Add(Position);
        }

        return Points;
    }

    void DrawSimulatedTrajectory(const TArray<FVector>& Points)
    {
        if (!IsValid(TrajectorySpline))
            return;

        TrajectorySpline.ClearSplinePoints();
        ClearSimulatedTrajectory();

        for (int i = 0; i < Points.Num(); ++i)
        {
            TrajectorySpline.AddSplinePoint(Points[i], ESplineCoordinateSpace::World, false);
        }

        if (Points.Num() > 1)
        {
            FVector Delta = Points.Last() - Points[Points.Num() - 2];
            FVector FinalTangent = Delta.GetSafeNormal();
            
            float SegmentLength = Delta.Size();
            FinalTangent *= SegmentLength * 0.5f;
            
            TrajectorySpline.SetTangentAtSplinePoint(Points.Num() - 1, FinalTangent, ESplineCoordinateSpace::World);
        }

        TrajectorySpline.SetSplinePointType(Points.Num() - 1, ESplinePointType::CurveCustomTangent, true);

        for (int i = 0; i < Points.Num() - 1; ++i)
        {
            USplineMeshComponent SplineMesh = USplineMeshComponent::Create(Owner);
            SplineMesh.AttachToComponent(TrajectorySpline);
            SplineMesh.SetMobility(EComponentMobility::Movable);
            SplineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            SplineMesh.SetStartScale(FVector2D(0.1f, 0.1f));
            SplineMesh.SetEndScale(FVector2D(0.1f, 0.1f));
            SplineMesh.SetStaticMesh(TrajectoryMesh);
            SplineMesh.SetMaterial(0, TrajectoryMaterial);

            FVector StartPos, StartTangent, EndPos, EndTangent;
            TrajectorySpline.GetLocationAndTangentAtSplinePoint(i, StartPos, StartTangent, ESplineCoordinateSpace::Local);
            TrajectorySpline.GetLocationAndTangentAtSplinePoint(i + 1, EndPos, EndTangent, ESplineCoordinateSpace::Local);
            SplineMesh.SetStartAndEnd(StartPos, StartTangent, EndPos, EndTangent);
            
            SplineMeshes.Add(SplineMesh);
        }
    }

    float GetGravityData(URangedAttackData Data)
    {
        for(UProjectileDataComponent DataComp : Data.ProjectileData.Components)
        {
            if(DataComp.IsA(UProjectileGravityData::StaticClass()))
            {
                return Cast<UProjectileGravityData>(DataComp).GravityEffectMultiplier;
                
            }
        }
        return 1.0f;
    }


}