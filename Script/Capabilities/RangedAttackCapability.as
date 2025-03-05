class URangedAttackCapability : UAbilityCapability
{
    default Priority = ECapabilityPriority::PostInput;

    // Components and Data
    AController Controller;
    UCapabilityComponent CapComp;
    UHomseMovementComponent MoveComp;
    UPlayerCameraComponent CameraComp;
    USplineComponent Spline;
    TArray<USplineMeshComponent> SplineMeshes;
    UTrajectoryVisualization TrajectoryVisualization;
    URangedAttackData RangedAbilityData;

    // State
    FVector InitialVelocity;
    float ChargeTime = 0.0f;
    float ChargeRatio;
    bool bIsCharging;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Super::Setup();
        if(HomseOwner == nullptr)
            return;
        
        Controller = HomseOwner.Controller;
        CapComp = UCapabilityComponent::Get(HomseOwner);
        MoveComp = UHomseMovementComponent::Get(HomseOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return !AbilityComp.IsLocked() && AbilityComp.IsAbilityActive(this);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() 
    { 
        return AbilityComp.IsLocked(this) || CooldownTimer.IsExpired();
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        // Reset charge variables
        ChargeTime = 0.0f;
        bIsCharging = false;

        // Retrieve ability data and update cooldown duration
        RangedAbilityData = Cast<URangedAttackData>(AbilityComp.GetAbilityData(this));
        CooldownTimer.SetDuration(RangedAbilityData.CooldownTime);
        
        // Initialize trajectory visualization if needed
        if (RangedAbilityData.DisplayTrajectory && !IsValid(TrajectoryVisualization))
        {
            TrajectoryVisualization = Cast<UTrajectoryVisualization>(
                NewObject(this, UTrajectoryVisualization::StaticClass())
            );
            if (IsValid(TrajectoryVisualization))
            {
                TrajectoryVisualization.Init(RangedAbilityData, Owner);
            }
        }

        // Cache the camera component
        CameraComp = UPlayerCameraComponent::Get(HomseOwner);

        // Reset the cooldown timer
        CooldownTimer.Reset();
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        // If still charging, cancel charging and clear trajectory
        if (bIsCharging)
        {
            bIsCharging = false;
            AbilityComp.Unlock(this);
            TrajectoryVisualization.ClearSimulatedTrajectory();
        }

        Super::OnDeactivate();

        // Reset charge state and re-enable movement orientation
        ChargeTime = 0.0f;
        bIsCharging = false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        UpdateCameraAndMovement();

        // Tick the cooldown timer.
        CooldownTimer.Tick(DeltaTime);
        if (CooldownTimer.IsActive() || CooldownTimer.IsExpired())
            return;

        // Lock the ability to ensure safe processing.
        AbilityComp.Lock(this);
        bIsCharging = false;

        // Process charging if the ability supports charged shots.
        if (RangedAbilityData.ChargedShot && AbilityComp.IsAbilityActive(this))
        {
            bIsCharging = true;
            ChargeRatio = ProcessCharging(DeltaTime);
        }

        // Calculate velocity and update trajectory visualization.
        InitialVelocity = CalculateInitialVelocity();
        if (RangedAbilityData.DisplayTrajectory)
            UpdateTrajectory();

        // For charged shots, delay firing until charging is complete.
        if (RangedAbilityData.ChargedShot && bIsCharging)
            return;        

        // Fire the projectile and reset cooldown.
        FireProjectile();
        CooldownTimer.Start();
        bIsCharging = false;
        AbilityComp.Unlock(this);
    }

    // Update camera offset and movement orientation based on ability state.
    void UpdateCameraAndMovement()
    {
        MoveComp.SetOrientToMovement(!AbilityComp.IsAbilityActive(this));

        if (IsValid(CameraComp))
        {
            if (AbilityComp.IsAbilityActive(this))
            {
                CameraComp.RegisterOffset(this, RangedAbilityData.CameraOffset, RangedAbilityData.CameraLerpTime);
            }
            else
            {
                CameraComp.UnregisterOffset(this);
            }
        }
    }

    // Handle charging logic and return the current charge ratio.
    float ProcessCharging(float DeltaTime)
    {
        ChargeTime = Math::Clamp(ChargeTime + DeltaTime, 0.0f, RangedAbilityData.MaxChargeTime);
        return (RangedAbilityData.MaxChargeTime == 0.0f) ? 1.0f : ChargeTime / RangedAbilityData.MaxChargeTime;
    }

    // Calculate projectile initial velocity based on charge and input.
    FVector CalculateInitialVelocity()
    {
        float VelocityMultiplier = Math::Lerp(
            RangedAbilityData.InitialVelocityMultiplier, 
            RangedAbilityData.MaxVelocityMultiplier, 
            ChargeRatio
        );
        FVector ForwardDirection = Owner.GetActorForwardVector();
        FVector ControllerRotation = Controller.GetControlRotation().Vector();
        if (RangedAbilityData.UseControllerZ)
            ForwardDirection.Z = ControllerRotation.Z;
        return ForwardDirection * VelocityMultiplier + 
               FVector(0, 0, RangedAbilityData.InitialZAngleMultiplier * VelocityMultiplier);
    }

    // Fire the projectile using the calculated initial velocity.
    void FireProjectile()
    {
        FVector SocketLocation = HomseOwner.Mesh.GetSocketLocation(RangedAbilityData.Socket);
        UProjectileBuilder()
            .WithSourceActor(Owner)
            .WithInitialVelocity(InitialVelocity)
            .WithStartingLocation(SocketLocation)
            .WithProjectileData(RangedAbilityData.ProjectileData)
            .Build();
    }

    // Update trajectory visualization if enabled.
    void UpdateTrajectory()
    {
        TrajectoryVisualization.ClearSimulatedTrajectory();
        if (bIsCharging)
        {
            FVector SocketLocation = HomseOwner.Mesh.GetSocketLocation(RangedAbilityData.Socket);
            TrajectoryVisualization.Simulate(SocketLocation, InitialVelocity);
        }
    }


};
