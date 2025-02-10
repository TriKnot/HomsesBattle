class URangedAttackCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    UCapabilityComponent CapComp;
    URangedAttackComponent RangedAttackComp;
    UHomseMovementComponent MoveComp;
    AController Controller;
    USplineComponent Spline;
    TArray<USplineMeshComponent> SplineMeshes;

    float ChargeTime = 0.0f;
    float CooldownTimer = 0.0f;
    bool OnCooldown = false;
    float ChargeRatio;
    float VelocityMultiplier;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(Owner);
        CapComp = HomseOwner.CapabilityComponent;
        RangedAttackComp = HomseOwner.RangedAttackComponent;
        Controller = HomseOwner.Controller;
        MoveComp = HomseOwner.HomseMovementComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return IsValid(RangedAttackComp.ProjectileData) && CapComp.GetActionStatus(InputActions::SecondaryAttack); 
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
        CooldownTimer = RangedAttackComp.ProjectileData.CooldownTime;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        ChargeTime = 0.0f;
        OnCooldown = false;
        CooldownTimer = 0.0f;     
        RangedAttackComp.bIsCharging = false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        RangedAttackComp.bIsCharging = false;

        if (OnCooldown)
        {
            if (CooldownTimer > 0.0f)
            {
                CooldownTimer -= DeltaTime;
                return;
            }
            return;
        }

        if (CapComp.GetActionStatus(InputActions::SecondaryAttack))
        {
            RangedAttackComp.bIsCharging = true;
            ChargeRatio = HandleCharging(DeltaTime, RangedAttackComp.ProjectileData);
            RangedAttackComp.InitialVelocity = CalculateInitialVelocity(RangedAttackComp.ProjectileData);
            VelocityMultiplier = Math::Lerp(RangedAttackComp.ProjectileData.InitialVelocityMultiplier, RangedAttackComp.ProjectileData.MaxVelocityMultiplier, ChargeRatio);
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

    float HandleCharging(float DeltaTime, UProjectileData ProjectileData)
    {
        ChargeTime = Math::Clamp(ChargeTime + DeltaTime, 0.0f, ProjectileData.MaxChargeTime);
        ChargeRatio = (ProjectileData.MaxChargeTime == 0.0f) ? 1.0f : ChargeTime / ProjectileData.MaxChargeTime;

        return ChargeRatio;
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

    FVector CalculateInitialVelocity(UProjectileData ProjectileData)
    {
        FVector ForwardDirection = Owner.GetActorForwardVector();
        FVector ControllerRotation = Controller.GetControlRotation().Vector();
        ForwardDirection.Z = ControllerRotation.Z;
        return ForwardDirection * VelocityMultiplier + FVector(0, 0, ProjectileData.InitialZAngleMultiplier * VelocityMultiplier);
    }

};
