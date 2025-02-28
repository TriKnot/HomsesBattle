class AProjectileActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent Root;

    UProjectileGravityData GravityData;
    UProjectileDamageData DamageDataAsset;
    UProjectileMeshData MeshDataAsset;
    FVector ProjectileVelocity;
    AActor SourceActor;
    TArray<AActor> IgnoredActors;

    default Root.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    default Root.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
    default Root.SetGenerateOverlapEvents(true);

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        Move(DeltaSeconds);
    }

    void SetGravityData(UProjectileGravityData InGravityData)
    {
        GravityData = InGravityData;
    }

    void SetDamageData(UProjectileDamageData InDamageData)
    {
        DamageDataAsset = InDamageData;
    }

    void SetMeshData(UProjectileMeshData InMeshData)
    {
        MeshDataAsset = InMeshData;
        if (IsValid(MeshDataAsset) && IsValid(MeshDataAsset.ProjectileMesh))
        {
            Root.SetStaticMesh(MeshDataAsset.ProjectileMesh);
            SetActorScale3D(MeshDataAsset.Scale);
        }
    }

    void SetSourceActor(AActor InSource)
    {
        SourceActor = InSource;
    }

    void SetInitialVelocity(const FVector& InVelocity)
    {
        ProjectileVelocity = InVelocity;
    }

    void SetIgnoredActors(const TArray<AActor>& InIgnoredActors)
    {
        IgnoredActors = InIgnoredActors;
    }


    UFUNCTION(BlueprintEvent)
    void Move(float DeltaSeconds) 
    {
        if(IsValid(GravityData))
            ProjectileVelocity.Z -= PhysicStatics::Gravity * GravityData.GravityEffectMultiplier * DeltaSeconds;
        
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
            FDamageData DamageInstance = DamageDataAsset.DamageData;
            DamageInstance.SetSourceActor(this);
            DamageInstance.SetDamageLocation(HitActor.ActorLocation);

            HealthComp.AddDamageInstanceData(DamageInstance);
        }
    }

};