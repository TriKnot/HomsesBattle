class UTrajectoryVisualization : UObject
{
    AActor Owner;
    UStaticMesh TrajectoryMesh;
    UMaterialInterface TrajectoryMaterial;
    float GravityMult;
    float DesiredMeshSegmentLength = 20.0f;
    float GapBetweenSegments = 20.0f;

    // Simulation Parameters
    float DesiredStepsPerSec;
    // Spline and Trace data
    USplineComponent TrajectorySpline;
    TArray<USplineMeshComponent> SplineMeshes;
    TArray<AActor> ActorsToIgnore;
    TArray<EObjectTypeQuery> ObjectTypes;
    default ObjectTypes.Add(UCollisionProfile::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));
    default ObjectTypes.Add(UCollisionProfile::ConvertToObjectType(ECollisionChannel::ECC_WorldDynamic));

    /* --------------------------------------------------
       Public Interface
    ----------------------------------------------------- */

    // Initialize the trajectory visualization
    void Init(AActor OwningActor, UStaticMesh Mesh, UMaterialInterface Material, float InGravityMultiplier,
              float InDesiredStepsPerSec, float InDesiredMeshSegmentLength = 1.0f, float InGapBetweenSegments = 0.0f)
    {
        Owner = OwningActor;
        TrajectoryMesh = Mesh;
        TrajectoryMaterial = Material;
        GravityMult = InGravityMultiplier;
        DesiredStepsPerSec = InDesiredStepsPerSec;
        DesiredMeshSegmentLength = InDesiredMeshSegmentLength;
        GapBetweenSegments = InGapBetweenSegments;

        // Create the spline component and attach to owner
        TrajectorySpline = USplineComponent::Create(Owner);
        TrajectorySpline.AttachToComponent(Owner.RootComponent);
        TrajectorySpline.SetMobility(EComponentMobility::Movable);
        TrajectorySpline.SetSimulatePhysics(false);
        TrajectorySpline.SetCollisionEnabled(ECollisionEnabled::NoCollision);
    }

    // Simulate the trajectory

    void Simulate(FVector StartLocation, FVector InitialVelocity)
    {
        if(Math::IsNearlyZero(InitialVelocity.Size()))
            return;

        HideSimulatedTrajectory();

        TArray<FVector> Points = GetSimulatedTrajectoryPoints(
            StartLocation, 
            InitialVelocity, 
            GravityMult * PhysicStatics::Gravity,
            1.5f);
        DrawSimulatedTrajectory(Points);
    }

    // Clear the simulated trajectory
    void Clear()
    {
        if(IsValid(TrajectorySpline))
        {
            TrajectorySpline.DestroyComponent(TrajectorySpline);
            TrajectorySpline = nullptr;
        }

        for (USplineMeshComponent Mesh : SplineMeshes)
        {
            if(IsValid(Mesh))
                Mesh.DestroyComponent(Mesh);
        }
        SplineMeshes.Empty();
    }

    /* --------------------------------------------------
        Private Implementation
    ----------------------------------------------------- */

    // Clear the simulated trajectory
    private void HideSimulatedTrajectory()
    {
        for (USplineMeshComponent SplineMesh : SplineMeshes)
        {
            if (IsValid(SplineMesh))
            {
                SplineMesh.SetVisibility(false);
            }
        }
    }

    // Compute the trajectory points
    private TArray<FVector> GetSimulatedTrajectoryPoints(const FVector& InitialPosition, const FVector& InitialVelocity, float Gravity, float ExtendedSimulationTime)
    {
        TArray<FVector> Points;
        Points.Add(InitialPosition);
        FHitResult Hit;
        float TotalTime;

        if (Math::IsNearlyZero(Gravity))
        {
            TotalTime = ExtendedSimulationTime; 
        }
        else
        {
            float BaseFlightTime = (InitialVelocity.Z > 0) ? (2 * InitialVelocity.Z / Gravity) : 1.0f;
            TotalTime = (ExtendedSimulationTime > BaseFlightTime) ? ExtendedSimulationTime : BaseFlightTime;
        }

        float dt = 1.0f / DesiredStepsPerSec;
        FVector Position = InitialPosition;
        FVector OldPosition = InitialPosition;

        for (float t = dt; t < TotalTime; t += dt)
        {
            OldPosition = Position;

            Position.X = InitialPosition.X + InitialVelocity.X * t;
            Position.Y = InitialPosition.Y + InitialVelocity.Y * t;
            Position.Z = InitialPosition.Z + InitialVelocity.Z * t - 0.5f * Gravity * t * t;

            if (System::LineTraceSingleForObjects(OldPosition, Position, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true))
            {
                Points.Add(Hit.Location);
                break;
            }

            Points.Add(Position);
        }
        return Points;
    }

    // Draw the simulated trajectory
    private void DrawSimulatedTrajectory(const TArray<FVector>& Points)
    {
        if (!IsValid(TrajectorySpline))
            return;

        TrajectorySpline.ClearSplinePoints();

        for (int i = 0; i < Points.Num(); ++i)
        {
            TrajectorySpline.AddSplinePoint(Points[i], ESplineCoordinateSpace::World, false);
        }

        TrajectorySpline.UpdateSpline();

        if (Points.Num() > 1)
        {
            FVector Delta = Points.Last() - Points[Points.Num() - 2];
            FVector FinalTangent = Delta.GetSafeNormal();
            
            float SegmentLength = Delta.Size();
            FinalTangent *= SegmentLength * 0.5f;
            
            TrajectorySpline.SetTangentAtSplinePoint(Points.Num() - 1, FinalTangent, ESplineCoordinateSpace::World);
        }
        TrajectorySpline.SetSplinePointType(Points.Num() - 1, ESplinePointType::CurveCustomTangent, true);


        float TotalLength = TrajectorySpline.GetSplineLength();
        float StepLength = DesiredMeshSegmentLength + GapBetweenSegments;
        int NumSegments = Math::CeilToInt(TotalLength / StepLength);


        for (int i = 0; i < NumSegments; ++i)
        {
            float StartDistance = i * StepLength;
            if (StartDistance >= TotalLength)
                break;
            float EndDistance = Math::Min(StartDistance + DesiredMeshSegmentLength, TotalLength);

            USplineMeshComponent SplineMesh = GetOrCreateSplineMeshComponent(i);
            if(!IsValid(SplineMesh))
                continue;

            FVector StartPos = TrajectorySpline.GetLocationAtDistanceAlongSpline(StartDistance, ESplineCoordinateSpace::Local);
            FVector StartTangent = TrajectorySpline.GetTangentAtDistanceAlongSpline(StartDistance, ESplineCoordinateSpace::Local);
            FVector EndPos = TrajectorySpline.GetLocationAtDistanceAlongSpline(EndDistance, ESplineCoordinateSpace::Local);
            FVector EndTangent = TrajectorySpline.GetTangentAtDistanceAlongSpline(EndDistance, ESplineCoordinateSpace::Local);

            SplineMesh.AttachToComponent(TrajectorySpline);
            SplineMesh.SetMobility(EComponentMobility::Movable);
            SplineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            SplineMesh.SetStartScale(FVector2D(0.1f, 0.1f));
            SplineMesh.SetEndScale(FVector2D(0.1f, 0.1f));
            SplineMesh.SetStaticMesh(TrajectoryMesh);
            SplineMesh.SetMaterial(0, TrajectoryMaterial);
            SplineMesh.SetStartAndEnd(StartPos, StartTangent, EndPos, EndTangent);
        }
    }

    // Get or create a spline mesh component
    private USplineMeshComponent GetOrCreateSplineMeshComponent(int Index)
    {
        USplineMeshComponent SplineMesh = nullptr;
        if (Index < SplineMeshes.Num())
        {
            SplineMesh = SplineMeshes[Index];
        }
        else
        {
            SplineMesh = USplineMeshComponent::Create(Owner);
            if (IsValid(SplineMesh))
            {
                SplineMeshes.Add(SplineMesh);
            }
        }
        SplineMesh.SetVisibility(true);
        return SplineMesh;
    }

}