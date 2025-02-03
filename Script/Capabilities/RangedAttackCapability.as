class URangedAttackCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    UCapabilityComponent CapComp;
    URangedAttackComponent RangedAttackComp;
    USplineComponent Spline;
    TArray<USplineMeshComponent> SplineMeshes;

    float ChargeTime = 0.0f;
    float CooldownTimer = 0.0f;
    bool OnCooldown = false;
    float ChargeRatio;
    float VelocityMultiplier;
    FVector InitialVelocity;
    FVector SpawnLocation;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(Owner);
        CapComp = HomseOwner.CapabilityComponent;
        RangedAttackComp = HomseOwner.RangedAttackComponent;

        if(IsValid(RangedAttackComp.ProjectileClass)
            && RangedAttackComp.ProjectileClass.GetDefaultObject().DisplaySimulatedTrajectory
            && RangedAttackComp.SimulatedProjectileTrajectorySpline == nullptr)
        {
            RangedAttackComp.SimulatedProjectileTrajectorySpline = USplineComponent::Create(Owner);
            Spline = RangedAttackComp.SimulatedProjectileTrajectorySpline;
            Spline.AttachToComponent(Owner.RootComponent);
            Spline.SetMobility(EComponentMobility::Movable);
            Spline.SetSimulatePhysics(false);
            Spline.SetCollisionEnabled(ECollisionEnabled::NoCollision);
        }
    }

    UFUNCTION(BlueprintOverride)
    void Teardown()
    {
        Super::Teardown();
        if(IsValid(RangedAttackComp.SimulatedProjectileTrajectorySpline))
        {
            RangedAttackComp.SimulatedProjectileTrajectorySpline.DestroyComponent(RangedAttackComp.SimulatedProjectileTrajectorySpline);
        }
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return IsValid(RangedAttackComp.ProjectileClass) && CapComp.GetActionStatus(InputActions::SecondaryAttack); 
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() 
    { 
        return CooldownTimer <= 0.0f; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        ChargeTime = 0.0f;
        OnCooldown = false;
        CooldownTimer = RangedAttackComp.ProjectileClass.GetDefaultObject().CooldownTime;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (OnCooldown)
        {
            if (CooldownTimer > 0.0f)
            {
                CooldownTimer -= DeltaTime;
                return;
            }
            return;
        }

        AProjectileActorBase Projectile = RangedAttackComp.ProjectileClass.GetDefaultObject();
        SpawnLocation = CalculateSpawnLocation();

        if (CapComp.GetActionStatus(InputActions::SecondaryAttack))
        {

            ChargeRatio = HandleCharging(DeltaTime, Projectile);
            
            if(Projectile.DisplaySimulatedTrajectory)
            {
                TArray<FVector> Points = SimulateProjectileTrajectory(Projectile.MaxChargeTime, 0.01f, Projectile.GravityEffectMultiplier);
                DrawSimulatedTrajectory(Points, Projectile);
            }

            if (!Projectile.AutoFireAtMaxCharge || ChargeRatio < 1.0f)
            {
                return;
            }
        }

        FireProjectile();
        OnCooldown = true;
    }

    float HandleCharging(float DeltaTime, AProjectileActorBase Projectile)
    {
        ChargeTime = Math::Clamp(ChargeTime + DeltaTime, 0.0f, Projectile.MaxChargeTime);
        ChargeRatio = (Projectile.MaxChargeTime == 0.0f) ? 1.0f : ChargeTime / Projectile.MaxChargeTime;
        VelocityMultiplier = Math::Lerp(Projectile.InitialVelocityMultiplier, Projectile.MaxVelocityMultiplier, ChargeRatio);
        InitialVelocity = CalculateInitialVelocity(Projectile);

        return ChargeRatio;
    }

    void FireProjectile()
    {
        AProjectileActorBase Projectile = Cast<AProjectileActorBase>(SpawnActor(RangedAttackComp.ProjectileClass, SpawnLocation));
        Print("Firing projectile with velocity: " + InitialVelocity.ToString());
        
        if (Projectile != nullptr)
        {
            TArray<AActor> ActorsToIgnore;
            ActorsToIgnore.Add(Owner);
            Projectile.Init(Owner, InitialVelocity, ActorsToIgnore);
            ClearSimulatedTrajectory();
        }
    }

    FVector CalculateInitialVelocity(AProjectileActorBase Projectile)
    {
        FVector ForwardDirection = Owner.GetActorForwardVector();
        return ForwardDirection * VelocityMultiplier + FVector(0, 0, Projectile.InitialZAngleMultiplier * VelocityMultiplier);
    }

    FVector CalculateSpawnLocation()
    {
        return Owner.GetActorLocation() 
            + Owner.GetActorForwardVector() * RangedAttackComp.ProjectileSpawnOffset.X
            + Owner.GetActorRightVector() * RangedAttackComp.ProjectileSpawnOffset.Y
            + Owner.GetActorUpVector() * RangedAttackComp.ProjectileSpawnOffset.Z;
    }

    TArray<FVector> SimulateProjectileTrajectory(float SimulationTime, float TimeStep, float GravityEffectMultiplier)
    {
        FVector Position = SpawnLocation;
        FVector Velocity = InitialVelocity;
        TArray<FVector> Points;

        Points.Add(Position);

        for (float t = 0; t <= SimulationTime; t += TimeStep)
        {
            Velocity.Z -= (RangedAttackComp.Gravity * GravityEffectMultiplier) * TimeStep;
            Position += Velocity * TimeStep;
            Points.Add(Position);
        }

        return Points;
    }

    void DrawSimulatedTrajectory(const TArray<FVector>& Points, AProjectileActorBase Projectile)
    {
        Spline.ClearSplinePoints();
        ClearSimulatedTrajectory();

        for (int i = 0; i < Points.Num(); ++i)
        {
            Spline.AddSplinePointAtIndex(Points[i], i, ESplineCoordinateSpace::World, false);
        }
        Spline.SetSplinePointType(Points.Num() - 1, ESplinePointType::CurveClamped, true);

        // Create spline meshes between each pair of points
        for (int i = 0; i < Points.Num() - 1; ++i)
        {
            USplineMeshComponent SplineMesh = USplineMeshComponent::Create(Owner);
            SplineMesh.AttachToComponent(Spline);
            SplineMesh.SetMobility(EComponentMobility::Movable);
            SplineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            SplineMesh.SetStartScale(FVector2D(0.1f, 0.1f));
            SplineMesh.SetEndScale(FVector2D(0.1f, 0.1f));
            SplineMesh.SetMaterial(0, RangedAttackComp.SimulatedProjectileTrajectoryMaterial);

            FVector StartPos, StartTangent, EndPos, EndTangent;
            Spline.GetLocationAndTangentAtSplinePoint(i, StartPos, StartTangent, ESplineCoordinateSpace::Local);
            Spline.GetLocationAndTangentAtSplinePoint(i + 1, EndPos, EndTangent, ESplineCoordinateSpace::Local);

            SplineMesh.SetStaticMesh(Projectile.TrajectoryMesh);
            SplineMesh.SetStartAndEnd(StartPos, StartTangent, EndPos, EndTangent);

            SplineMeshes.Add(SplineMesh);
        }
    }

    void ClearSimulatedTrajectory()
    {
        Spline.ClearSplinePoints();
        for (USplineMeshComponent Mesh : SplineMeshes)
        {
            Mesh.DestroyComponent(Mesh);
        }
        SplineMeshes.Empty();
    }

};
