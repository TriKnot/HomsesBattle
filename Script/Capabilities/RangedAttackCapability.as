class URangedAttackCapability : UAbilityCapability
{
    // Components
    URangedAttackComponent RangedAttackComp;
    AController Controller;
    USplineComponent Spline;
    TArray<USplineMeshComponent> SplineMeshes;

    float ChargeTime = 0.0f;
    float ChargeRatio;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Super::Setup();
        if(HomseOwner == nullptr)
            return;
        
        RangedAttackComp = HomseOwner.RangedAttackComponent;
        Controller = HomseOwner.Controller;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return IsValid(RangedAttackComp.ProjectileData) 
        && CapComp.GetActionStatus(InputActions::SecondaryAttack); 
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() 
    { 
        return CooldownTimer <= 0.0f; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        Super::OnActivate();
        ChargeTime = 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        Super::OnDeactivate();
        ChargeTime = 0.0f;
        RangedAttackComp.bIsCharging = false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        RangedAttackComp.bIsCharging = false;

        // If on cooldown, update the cooldown timer
        if (OnCooldown)
        {
            UpdateCooldown(DeltaTime);
            return;
        }

        // If the player is still holding the button, keep charging
        if (CapComp.GetActionStatus(InputActions::SecondaryAttack))
        {
            RangedAttackComp.bIsCharging = true;
            ChargeRatio = HandleCharging(DeltaTime);
            float VelocityMultiplier = Math::Lerp(RangedAttackComp.ProjectileData.InitialVelocityMultiplier, RangedAttackComp.ProjectileData.MaxVelocityMultiplier, ChargeRatio);
            RangedAttackComp.InitialVelocity = CalculateInitialVelocity(RangedAttackComp.ProjectileData, VelocityMultiplier);
            MoveComp.SetOrientToMovement(false);

            if (!RangedAttackComp.ProjectileData.AutoFireAtMaxCharge || ChargeRatio < 1.0f)
            {
                return;
            }

        }

        FireProjectile();
        MoveComp.SetOrientToMovement(true);
        OnCooldown = true;
    }

    float HandleCharging(float DeltaTime)
    {
        ChargeTime = Math::Clamp(ChargeTime + DeltaTime, 0.0f, RangedAttackComp.ProjectileData.MaxChargeTime);

        return (RangedAttackComp.ProjectileData.MaxChargeTime == 0.0f) ? 1.0f : ChargeTime / RangedAttackComp.ProjectileData.MaxChargeTime;
    }

    void FireProjectile()
    {
        AProjectileActor Projectile = Cast<AProjectileActor>(SpawnActor( AProjectileActor::StaticClass(), RangedAttackComp.AttackSocketLocation,
                FRotator::ZeroRotator, n"Projectile", true)); 
        
        if (Projectile != nullptr)
        {
            TArray<AActor> ActorsToIgnore;
            ActorsToIgnore.Add(Owner);
            Projectile.Init(Owner, RangedAttackComp.InitialVelocity, ActorsToIgnore, RangedAttackComp.ProjectileData);
            FinishSpawningActor(Projectile);
            Projectile.SetActorScale3D(RangedAttackComp.ProjectileData.Scale);
            Print(Projectile.GetActorScale3D().ToString());
        }
    }

    FVector CalculateInitialVelocity(UProjectileData ProjectileData, float VelocityMultiplier)
    {
        FVector ForwardDirection = Owner.GetActorForwardVector();
        FVector ControllerRotation = Controller.GetControlRotation().Vector();
        ForwardDirection.Z = ControllerRotation.Z;
        return ForwardDirection * VelocityMultiplier + FVector(0, 0, ProjectileData.InitialZAngleMultiplier * VelocityMultiplier);
    }

};
