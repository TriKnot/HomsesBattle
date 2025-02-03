class AProjectileActorBase : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent Root;

    UPROPERTY(Category = "Projectile Settings")
    float InitialVelocityMultiplier = 1500.0f;

    UPROPERTY(Category = "Projectile Settings")
    float MaxVelocityMultiplier = 3000.0f;

    UPROPERTY(Category = "Projectile Settings")
    float MaxChargeTime = 1.0f;

    UPROPERTY(Category = "Projectile Settings")
    float CooldownTime = 1.0f;

    UPROPERTY(Category = "Projectile Settings")
    bool AutoFireAtMaxCharge = false;

    UPROPERTY(Category = "Projectile Settings")
    float GravityEffectMultiplier = 1.0f;

    UPROPERTY(Category = "Projectile Settings")
    float InitialZAngleMultiplier = 1.0;

    UPROPERTY(Category = "Projectile Settings")
    float DamageAmount = 10.0f;

    UPROPERTY(Category = "Projectile Settings")
    bool DisplaySimulatedTrajectory = false;

    UPROPERTY(Category = "Projectile Settings")
    UStaticMesh TrajectoryMesh;

    default Root.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    default Root.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
    default Root.SetGenerateOverlapEvents(true);

    const float Gravity = 9810.0f;
    FVector ProjectileVelocity;
    TArray<AActor> IgnoredActors;
    AActor ActorSource;

    UFUNCTION(BlueprintEvent)
    void Init(AActor SourceActor, FVector InitialVelocity, TArray<AActor> ActorsToIgnore)
    {
        ProjectileVelocity = InitialVelocity;
        IgnoredActors = ActorsToIgnore;
        ActorSource = SourceActor;
    }

    UFUNCTION(BlueprintEvent)
    void Move(float DeltaSeconds) 
    {
        ProjectileVelocity.Z -= Gravity * GravityEffectMultiplier * DeltaSeconds;
        FVector NewLocation = ActorLocation + (ProjectileVelocity * DeltaSeconds);

        // Basic movement for non-tracking projectiles
        FHitResult HitResult;

        SetActorLocation(NewLocation, true, HitResult, false);

        if(HitResult.bBlockingHit)
        {
            OnHit(HitResult.GetActor());
        }
    };

    UFUNCTION(BlueprintEvent)
    void OnHit(AActor HitActor) 
    {
        Print("Projectile hit: " + HitActor.GetName());
        if(IgnoredActors.Contains(HitActor))
            return;

        TryDealDamage(HitActor);
        DestroyActor();
    };

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        Move(DeltaSeconds);
    }

    void TryDealDamage(AActor HitActor)
    {
        UHealthComponent HealthComp = Cast<UHealthComponent>(HitActor.GetComponentByClass(UHealthComponent::StaticClass()));
        if(HealthComp != nullptr)
        {
            FDamageInstanceData DamageInstance;
            DamageInstance.DamageAmount = DamageAmount;
            DamageInstance.DamageDirection = ProjectileVelocity.GetSafeNormal();
            DamageInstance.SourceActor = ActorSource;
            DamageInstance.DamageLocation = GetActorLocation();
            HealthComp.DamageInstances.Add(DamageInstance);
        }
    }

};