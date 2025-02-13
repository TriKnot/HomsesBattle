class URangedAttackCapability : UAbilityCapability
{
    // Components
    AController Controller;
    USplineComponent Spline;
    TArray<USplineMeshComponent> SplineMeshes;

    URangedAttackData RangedAbilityData;
    UTrajectoryVisualization TrajectoryVisualization;

    FVector InitialVelocity;
    float ChargeTime = 0.0f;
    float ChargeRatio;
    bool bIsCharging = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Super::Setup();
        if(HomseOwner == nullptr)
            return;
        
        Controller = HomseOwner.Controller;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return AbilityComp.IsAbilityActive(this);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() 
    { 
        return !bIsOnCooldown && !bIsCharging;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        Super::OnActivate();
        ChargeTime = 0.0f;
        bIsCharging = false;

        RangedAbilityData = Cast<URangedAttackData>(AbilityComp.GetAbilityData(this));
        AbilityCooldown = RangedAbilityData.CooldownTime;
        
        if(RangedAbilityData.DisplayTrajectory && !IsValid(TrajectoryVisualization))
        {
            TrajectoryVisualization = Cast<UTrajectoryVisualization>(NewObject(this, UTrajectoryVisualization::StaticClass()));
            if(IsValid(TrajectoryVisualization))
                TrajectoryVisualization.Init(RangedAbilityData, Owner);
        }
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        Super::OnDeactivate();
        ChargeTime = 0.0f;
        bIsCharging = false;
        MoveComp.SetOrientToMovement(true);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (bIsOnCooldown)
        {
            UpdateCooldown(DeltaTime);
            return;
        }

        bIsCharging = false;

        if (AbilityComp.IsAbilityActive(this))
        {
            if(RangedAbilityData.ChargedShot)
            {
                bIsCharging = true;
                ChargeRatio = HandleCharging(DeltaTime);
            }
            MoveComp.SetOrientToMovement(false);
        }

        float VelocityMultiplier = Math::Lerp(RangedAbilityData.InitialVelocityMultiplier, RangedAbilityData.MaxVelocityMultiplier, ChargeRatio);
        InitialVelocity = CalculateInitialVelocity(VelocityMultiplier);

        if(RangedAbilityData.DisplayTrajectory)
        {
            TrajectoryVisualization.ClearSimulatedTrajectory();
        }

        if(RangedAbilityData.ChargedShot && bIsCharging)
        {    
            if(RangedAbilityData.DisplayTrajectory)
            {
                TrajectoryVisualization.Simulate(HomseOwner.Mesh.GetSocketLocation(RangedAbilityData.Socket), InitialVelocity);
            }
            return;        
        }    

        FireProjectile();
        bIsOnCooldown = true;
        bIsCharging = false;
    }

    float HandleCharging(float DeltaTime)
    {
        ChargeTime = Math::Clamp(ChargeTime + DeltaTime, 0.0f, RangedAbilityData.MaxChargeTime);

        return (RangedAbilityData.MaxChargeTime == 0.0f) ? 1.0f : ChargeTime / RangedAbilityData.MaxChargeTime;
    }

    void FireProjectile()
    {
        FVector SocketLocation = HomseOwner.Mesh.GetSocketLocation(RangedAbilityData.Socket);
        AProjectileActor Projectile = Cast<AProjectileActor>(SpawnActor( AProjectileActor::StaticClass(), SocketLocation,
                FRotator::ZeroRotator, n"Projectile", true)); 
        
        if (Projectile != nullptr)
        {
            TArray<AActor> ActorsToIgnore;
            ActorsToIgnore.Add(Owner);
            Projectile.Init(Owner, InitialVelocity, ActorsToIgnore, RangedAbilityData.ProjectileData);
            FinishSpawningActor(Projectile);
            Projectile.SetActorScale3D(RangedAbilityData.ProjectileData.Scale);
        }
    }

    FVector CalculateInitialVelocity(float VelocityMultiplier)
    {
        FVector ForwardDirection = Owner.GetActorForwardVector();
        FVector ControllerRotation = Controller.GetControlRotation().Vector();
        if(RangedAbilityData.UseControllerZ)
            ForwardDirection.Z = ControllerRotation.Z;
        return ForwardDirection * VelocityMultiplier + FVector(0, 0, RangedAbilityData.InitialZAngleMultiplier * VelocityMultiplier);
    }

};
