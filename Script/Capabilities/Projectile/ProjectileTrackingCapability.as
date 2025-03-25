class UProjectileTrackingCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;
    UProjectileTrackingComponent TrackingComponent;

    AActor TargetActor;
    FTimer TargetSearchTimer;
    UActorTrackingPredictor TrackingPredictor;

    FVector CurrentAimLocation;
    float MaxPredictionAngleDot; // The max angle between the predicted and actual target

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
        TrackingComponent = UProjectileTrackingComponent::GetOrCreate(ProjectileOwner);

        TrackingPredictor = Cast<UActorTrackingPredictor>(NewObject(this, UActorTrackingPredictor::StaticClass()));
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated 
            && !MoveComponent.ProjectileVelocity.IsNearlyZero();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return !ProjectileOwner.bActivated;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        MaxPredictionAngleDot = Math::Cos(Math::DegreesToRadians(TrackingComponent.MaxPredictionAngle));
        if(TrackingComponent.TrackPredictedTargetLocation)
            TrackingPredictor.Init(TrackingComponent.PositionRecordInterval, TrackingComponent.MaxPositionHistory, TrackingComponent.WeightDecayFactor, TrackingComponent.SmoothingFactor);

        TargetSearchTimer.SetDuration(TrackingComponent.TargetSearchInterval);
        FindTarget();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        TargetSearchTimer.Tick(DeltaTime);
        TrackingPredictor.Tick(DeltaTime);

        if (TargetSearchTimer.IsFinished()) // Find a target every interval
        {
            FindTarget();
            TargetSearchTimer.Reset();
            TargetSearchTimer.Start();        
        }

        if (!IsValid(TargetActor))
            return;

        FVector ProjectileLocation = ProjectileOwner.GetActorLocation();
        float ProjectileSpeed = MoveComponent.ProjectileVelocity.Size();

        FVector AimLocation = TargetActor.GetActorLocation();
        FVector PredictedAimLocation;

        // Calculate and set the aim location if it's valid
        if(CalculateLeadPrediction(ProjectileLocation, ProjectileSpeed, PredictedAimLocation))
            AimLocation = PredictedAimLocation;

        // Find the new direction to aim towards using the blended degree tracking
        FVector TargetOffset = AimLocation - ProjectileLocation;
        FVector NewDirection = ApplyBlendedTracking(MoveComponent.ProjectileVelocity, TargetOffset, DeltaTime);

        MoveComponent.ProjectileVelocity = NewDirection * ProjectileSpeed;
        
        System::DrawDebugBox(AimLocation, FVector(25.f), FLinearColor::Blue);
        System::DrawDebugLine(ProjectileLocation, AimLocation, FLinearColor::Blue);
    }

    bool CalculateLeadPrediction( const FVector& ProjectileLoc, float ProjectileSpeed, FVector& OutAimLoc)
    {
        if (!IsValid(TargetActor))
            return false;

        FVector TargetLoc = TargetActor.GetActorLocation();
        FVector TargetVel = TargetActor.GetVelocity();

        float OutPredictionTime = 0.f;
        if (GetLeadPredictionTime(ProjectileLoc, ProjectileSpeed, TargetLoc, TargetVel, OutPredictionTime)) // If we get a valid prediction time
        {
            FVector PredictedLoc = TrackingPredictor.GetPredictedLocation(OutPredictionTime); // Get the predicted location at that time
            if (IsPredictedLocationValid(ProjectileLoc, PredictedLoc)) // Not moving away from the target and prediction is not too far
            {
                OutAimLoc = PredictedLoc;
                return true;
            }        
        }

        OutAimLoc = TargetLoc; // No prediction
        return false;
    }

    bool IsPredictedLocationValid(const FVector& ProjectileLoc, const FVector& AimLoc) const
    {
        FVector PredictedDir = (AimLoc - ProjectileLoc).GetSafeNormal();
        FVector ToTargetDir = (TargetActor.GetActorLocation() - ProjectileLoc).GetSafeNormal();
        FVector CurrentDir = MoveComponent.ProjectileVelocity.GetSafeNormal();

        bool bMovingAwayFromTarget = CurrentDir.DotProduct(ToTargetDir) < 0.f;
        bool bPredictionFurtherFromTarget = AimLoc.DistSquared(TargetActor.GetActorLocation()) > ProjectileLoc.DistSquared(TargetActor.GetActorLocation());

        if(bMovingAwayFromTarget && bPredictionFurtherFromTarget) // Moving away and prediction is further from target
            return false;

        return PredictedDir.DotProduct(ToTargetDir) >= MaxPredictionAngleDot; // Angle between predicted and actual target is not too large
    }

    FVector ApplyBlendedTracking( const FVector& CurrentVelocity, const FVector& TargetOffset, float DeltaTime)
    {
        FVector CurrentDir = CurrentVelocity.GetSafeNormal();
        FVector TargetDir = TargetOffset.GetSafeNormal();
        float DistSquaredToTarget = TargetOffset.SizeSquared();

        float CombinedTurnRate = 0.f;
        float TotalWeight = 0.f;

        for (const FTrackingData& Data : TrackingComponent.TrackingData)
        {
            float MaxDistSquared = Math::Square(Data.MaxActivationDistance);
            if (DistSquaredToTarget > MaxDistSquared)
                continue;

            float Weight = 1.f - (DistSquaredToTarget / MaxDistSquared); // Weight based on distance to target compared to current tracking data max distance
            CombinedTurnRate += Data.TurnRateDegrees * Weight;
            TotalWeight += Weight;
        }

        if (TotalWeight <= 0.f)
            return CurrentDir;

        float AvgTurnRate = CombinedTurnRate / TotalWeight;
        float MaxTurnThisFrame = AvgTurnRate * DeltaTime;

        return RotateDirectionTowards(CurrentDir, TargetDir, MaxTurnThisFrame);
    }

    void FindTarget()
    {
        float LargestTrackingRadius = 0.f;
        for (const FTrackingData& Data : TrackingComponent.TrackingData)
        {
            LargestTrackingRadius = Math::Max(LargestTrackingRadius, Data.MaxActivationDistance);
        }

        TargetActor = UEntityRegistrySubsystem::Get()
                        .GetClosestHomseTo(ProjectileOwner, LargestTrackingRadius, TrackingComponent.IgnoredActors);

        TrackingPredictor.SetTarget(TargetActor);
    }

    FVector RotateDirectionTowards( const FVector& FromDir, const FVector& ToDir, float MaxDegrees) const
    {
        float AngleBetween = FromDir.AngularDistance(ToDir);
        if (AngleBetween < KINDA_SMALL_NUMBER)
            return ToDir;

        float RotationAngle = Math::Min(AngleBetween, MaxDegrees);
        FVector RotationAxis = FromDir.CrossProduct(ToDir).GetSafeNormal();
        FQuat RotationQuat(RotationAxis, Math::DegreesToRadians(RotationAngle));

        return RotationQuat.RotateVector(FromDir).GetSafeNormal();
    }

    bool GetLeadPredictionTime( const FVector& ProjectileLocation, float ProjectileSpeed, const FVector& TargetLocation,
        const FVector& TargetVelocity, float& OutPredictionTime)
    {
        FVector ToTarget = TargetLocation - ProjectileLocation;

        float a = TargetVelocity.SizeSquared() - ProjectileSpeed * ProjectileSpeed; // Squared difference in speed between the projectile and target
        float b = 2.f * ToTarget.DotProduct(TargetVelocity); // How quickly the distance between the projectile and target changes
        float c = ToTarget.SizeSquared(); // Squared distance between the projectile and target

        float Discriminant = b * b - 4.f * a * c; // Quadratic formula

        if (Math::Abs(a) < KINDA_SMALL_NUMBER) // If close to or below zero it's a linear equation
        {
            if (Math::Abs(b) < KINDA_SMALL_NUMBER) // Invalid equation
            {
                OutPredictionTime = 0.f;
                return false;
            }

            OutPredictionTime = -c / b; // Linear equation
            return OutPredictionTime > 0.f;
        }

        if (Discriminant < 0.f)
            return false; // Can't reach the target

        // Calculate the two possible times
        float SqrtDiscriminant = Math::Sqrt(Discriminant);
        float Time1 = (-b + SqrtDiscriminant) / (2.f * a);
        float Time2 = (-b - SqrtDiscriminant) / (2.f * a);

        // Select the smallest positive time if it's valid (greater than zero)
        OutPredictionTime = Math::Min(Time1, Time2);
        if (OutPredictionTime < KINDA_SMALL_NUMBER)
            OutPredictionTime = Math::Max(Time1, Time2);

        return OutPredictionTime > KINDA_SMALL_NUMBER;
    }

}