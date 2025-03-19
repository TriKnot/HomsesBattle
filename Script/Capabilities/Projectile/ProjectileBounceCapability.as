class UProjectileBounceCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    AProjectileActor ProjectileOwner;
    UProjectileDamageComponent DamageComponent;
    UProjectileMoveComponent MoveComponent;

    int CurrentBounceCount = 0;

    FTimer CooldownTimer;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        DamageComponent = UProjectileDamageComponent::GetOrCreate(ProjectileOwner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated 
            && DamageComponent.MovementHitResult.bBlockingHit
            && (CurrentBounceCount < MoveComponent.MaxBounces);
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
        FVector ReflectedVelocity = IncomingVelocity.MirrorByVector(DamageComponent.MovementHitResult.Normal);
        ReflectedVelocity *= 1 - MoveComponent.BounceEnergyLoss;
        MoveComponent.ProjectileVelocity = ReflectedVelocity;

        CurrentBounceCount++;

        // Slight position adjustment to avoid repeated collisions
        FVector AdjustedPosition = ProjectileOwner.GetActorLocation() + DamageComponent.MovementHitResult.Normal * 2.f;
        ProjectileOwner.SetActorLocation(AdjustedPosition);

        if(CurrentBounceCount < MoveComponent.MaxBounces)
        {
            CooldownTimer.SetDuration(0.1f);
            CooldownTimer.Reset();
            CooldownTimer.Start();
        }
        else
        {
            DamageComponent.bAllowDestroy = true;
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        CooldownTimer.Tick(DeltaTime);
    }
};
