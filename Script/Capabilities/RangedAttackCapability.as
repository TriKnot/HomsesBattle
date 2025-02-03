class URangedAttackCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    UCapabilityComponent CapComp;
    URangedAttackComponent RangedAttackComp;

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
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return CapComp.GetActionStatus(InputActions::SecondaryAttack); 
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
            
            if(Projectile.DisplayTrajectory)
                DrawSimulatedTrajectory(SimulateProjectileTrajectory(1.0f, 0.01f, Projectile.GravityEffectMultiplier));

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
        
        if (Projectile != nullptr)
        {
            TArray<AActor> ActorsToIgnore;
            ActorsToIgnore.Add(Owner);
            Projectile.Init(Owner, InitialVelocity, ActorsToIgnore);
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

        for (float t = 0; t <= SimulationTime; t += TimeStep)
        {
            Position += Velocity * TimeStep;
            Points.Add(Position);

            Velocity.Z -= (RangedAttackComp.Gravity * GravityEffectMultiplier) * TimeStep;
        }

        return Points;
    }

    void DrawSimulatedTrajectory(const TArray<FVector>& Points)
    {
        for (const FVector& Point : Points)
        {
            System::DrawDebugSphere(Point, 10.0f, 8);
        }
    }

};
