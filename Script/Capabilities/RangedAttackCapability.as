class URangedAttackCapability : UAbilityCapability
{
    // Components
    UAbilityComponent AbilityComp;
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
        
        AbilityComp = HomseOwner.AbilityComponent;
        Controller = HomseOwner.Controller;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return IsValid(AbilityComp.ProjectileData) 
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
        AbilityComp.bIsCharging = false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        AbilityComp.bIsCharging = false;

        // If on cooldown, update the cooldown timer
        if (OnCooldown)
        {
            UpdateCooldown(DeltaTime);
            return;
        }

        // If the player is still holding the button, keep charging
        if (CapComp.GetActionStatus(InputActions::SecondaryAttack))
        {
            AbilityComp.bIsCharging = true;
            ChargeRatio = HandleCharging(DeltaTime);
            float VelocityMultiplier = Math::Lerp(AbilityComp.ProjectileData.InitialVelocityMultiplier, AbilityComp.ProjectileData.MaxVelocityMultiplier, ChargeRatio);
            AbilityComp.InitialVelocity = CalculateInitialVelocity(AbilityComp.ProjectileData, VelocityMultiplier);
            MoveComp.SetOrientToMovement(false);

            if (!AbilityComp.ProjectileData.AutoFireAtMaxCharge || ChargeRatio < 1.0f)
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
        ChargeTime = Math::Clamp(ChargeTime + DeltaTime, 0.0f, AbilityComp.ProjectileData.MaxChargeTime);

        return (AbilityComp.ProjectileData.MaxChargeTime == 0.0f) ? 1.0f : ChargeTime / AbilityComp.ProjectileData.MaxChargeTime;
    }

    void FireProjectile()
    {
        AProjectileActor Projectile = Cast<AProjectileActor>(SpawnActor( AProjectileActor::StaticClass(), AbilityComp.AttackSocketLocation,
                FRotator::ZeroRotator, n"Projectile", true)); 
        
        if (Projectile != nullptr)
        {
            TArray<AActor> ActorsToIgnore;
            ActorsToIgnore.Add(Owner);
            Projectile.Init(Owner, AbilityComp.InitialVelocity, ActorsToIgnore, AbilityComp.ProjectileData);
            FinishSpawningActor(Projectile);
            Projectile.SetActorScale3D(AbilityComp.ProjectileData.Scale);
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
