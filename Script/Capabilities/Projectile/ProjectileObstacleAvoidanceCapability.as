class UProjectileObstacleAvoidanceCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;
    UProjectileObstacleAvoidanceComponent AvoidanceComponent;

    TArray<AActor> IgnoredActors;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
        AvoidanceComponent = UProjectileObstacleAvoidanceComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return !ProjectileOwner.bActivated;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        IgnoredActors.Add(ProjectileOwner);        
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FVector AvoidanceVector = CalculateAvoidanceVector();

        if (AvoidanceVector.IsNearlyZero())
            return;

        FVector CurrentDir = MoveComponent.ProjectileVelocity.GetSafeNormal();
        FVector DesiredDir = (CurrentDir + AvoidanceVector).GetSafeNormal();

        float MaxAllowedAngleThisFrame = AvoidanceComponent.MaxAvoidanceAnglePerSecond * DeltaTime;
        
        FVector SmoothedDir = CurrentDir.RotateDirectionVectorTowards(DesiredDir, MaxAllowedAngleThisFrame);
        MoveComponent.ProjectileVelocity = SmoothedDir * MoveComponent.ProjectileVelocity.Size();
    }

    FVector CalculateAvoidanceVector() const
    {
        FVector Start = ProjectileOwner.GetActorLocation();
        FVector ForwardDir = MoveComponent.ProjectileVelocity.GetSafeNormal();
        FVector End = Start + (ForwardDir * AvoidanceComponent.DetectionDistance);

        FCollisionQueryParams Params;
        Params.AddIgnoredActor(ProjectileOwner);
        Params.bTraceComplex = false;

        FVector AvoidanceForce = FVector::ZeroVector;
        FHitResult Hit;

        

        if (System::SphereTraceSingle(
            Start,
            End,
            AvoidanceComponent.DetectionRadius,
            AvoidanceComponent.TraceChannel,
            false,
            IgnoredActors,
            EDrawDebugTrace::ForOneFrame,
            Hit,
            true,
            FLinearColor::Green,
            FLinearColor::Red
            )
            && Hit.bBlockingHit)
        {
            FVector ObstacleLocation = Hit.ImpactPoint;
            FVector AwayFromObstacle = (Start - ObstacleLocation).GetSafeNormal();

            // The closer the obstacle, the stronger the avoidance
            float DistanceToObstacle = Hit.Distance;
            float Strength = 1.f - (DistanceToObstacle / AvoidanceComponent.DetectionDistance);

            AvoidanceForce = AwayFromObstacle * Strength;
        }

        return AvoidanceForce;
    }

};
