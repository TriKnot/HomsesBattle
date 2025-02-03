class AProjectileActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent Root;

    UProjectileData Data;
    FVector ProjectileVelocity;
    AActor SourceActor;
    TArray<AActor> IgnoredActors;

    default Root.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    default Root.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
    default Root.SetGenerateOverlapEvents(true);

    UFUNCTION(BlueprintEvent)
    void Init(AActor Source, FVector InitialVelocity, TArray<AActor> ActorsToIgnore, UProjectileData ProjectileData)
    {
        SourceActor = Source;
        ProjectileVelocity = InitialVelocity;
        IgnoredActors = ActorsToIgnore;
        Data = ProjectileData;
        Root.SetStaticMesh(Data.ProjectileMesh);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        Move(DeltaSeconds);
    }

    UFUNCTION(BlueprintEvent)
    void Move(float DeltaSeconds) 
    {
        ProjectileVelocity.Z -= PhysicStatics::Gravity * Data.GravityEffectMultiplier * DeltaSeconds;
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


    void TryDealDamage(AActor HitActor)
    {
        UHealthComponent HealthComp = Cast<UHealthComponent>(HitActor.GetComponentByClass(UHealthComponent::StaticClass()));
        if(HealthComp != nullptr)
        {
            FDamageInstanceData DamageInstance;
            DamageInstance.DamageAmount = Data.Damage;
            DamageInstance.DamageDirection = ProjectileVelocity.GetSafeNormal();
            DamageInstance.SourceActor = SourceActor;
            DamageInstance.DamageLocation = GetActorLocation();
            HealthComp.DamageInstances.Add(DamageInstance);
        }
    }

};