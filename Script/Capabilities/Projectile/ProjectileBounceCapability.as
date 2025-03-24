class UProjectileBounceCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    AProjectileActor ProjectileOwner;
    UProjectileCollisionComponent CollisionComponent;
    UProjectileBounceComponent BounceComponent;
    UProjectileMoveComponent MoveComponent;

    int CurrentBounceCount = 0;
    FTimer CooldownTimer;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        CollisionComponent = UProjectileCollisionComponent::GetOrCreate(ProjectileOwner);
        BounceComponent = UProjectileBounceComponent::GetOrCreate(ProjectileOwner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated 
            && CollisionComponent.MovementHitResult.bBlockingHit
            && (CurrentBounceCount < BounceComponent.MaxBounces);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return CooldownTimer.IsFinished();
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        // Reflect projectile velocity
        FVector IncomingVelocity = MoveComponent.ProjectileVelocity;
        FVector ReflectedVelocity = IncomingVelocity.MirrorByVector(CollisionComponent.MovementHitResult.Normal);
        ReflectedVelocity *= BounceComponent.EnergyOnBounceMultiplier;
        MoveComponent.ProjectileVelocity = ReflectedVelocity;
        ProjectileOwner.SetActorRotation(ReflectedVelocity.ToOrientationRotator());

        CurrentBounceCount++;

        // Slight position adjustment to avoid repeated collisions
        FVector HitPoint = CollisionComponent.MovementHitResult.ImpactPoint;
        FVector AdjustedPosition = HitPoint + CollisionComponent.MovementHitResult.Normal * 2.0f;
        ProjectileOwner.SetActorLocation(AdjustedPosition);

        if(CurrentBounceCount < BounceComponent.MaxBounces)
        {
            CooldownTimer.SetDuration(0.01f); // ~1 frame
            CooldownTimer.Reset();
            CooldownTimer.Start();
        }
        else
        {
            CollisionComponent.bAllowDestroy = true;
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        CooldownTimer.Tick(DeltaTime);
    }
};
