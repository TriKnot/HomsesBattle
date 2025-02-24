class URangedAttackCapability : UAbilityCapability
{
    default Priority = ECapabilityPriority::PostInput;

    // Components
    AController Controller;
    USplineComponent Spline;
    UPlayerCameraComponent CameraComp;
    TArray<USplineMeshComponent> SplineMeshes;

    URangedAttackData RangedAbilityData;
    UTrajectoryVisualization TrajectoryVisualization;

    FVector InitialVelocity;
    FVector CameraOffset;
    float CameraLerpT;
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
        return !AbilityComp.bIsLocked && AbilityComp.IsAbilityActive(this);
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

        CameraComp = Cast<UPlayerCameraComponent>(HomseOwner.GetComponent(UPlayerCameraComponent::StaticClass()));
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
        MoveComp.SetOrientToMovement(!AbilityComp.IsAbilityActive(this));
        bool bActive = AbilityComp.IsAbilityActive(this);

        if(IsValid(CameraComp))
        {
            if(bActive)
            {
                CameraComp.RegisterOffset(this, RangedAbilityData.CameraOffset, RangedAbilityData.CameraLerpTime);
            }
            else
            {
                CameraComp.UnregisterOffset(this);
            }
        }

        if (bIsOnCooldown)
        {
            UpdateCooldown(DeltaTime);
            return;
        }

        bIsCharging = false;
        AbilityComp.Lock();

        if (bActive)
        {
            if(RangedAbilityData.ChargedShot)
            {
                bIsCharging = true;
                ChargeRatio = HandleCharging(DeltaTime);
            }
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
        AbilityComp.Unlock();
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
