class UAddHitBoxModifier : UAbilityModifier
{
    UPROPERTY(Category="Hitbox")
    EHitboxShape HitboxShape;

    UPROPERTY(Category="Hitbox")
    FName SocketName;

    // Parameters for a sphere hitbox.
    UPROPERTY(Category="Hitbox|Sphere", meta=(EditCondition="HitboxShape == EHitboxShape::EHS_Sphere"))
    float SphereRadius = 50.0f;

    // Parameters for a capsule hitbox.
    UPROPERTY(Category="Hitbox|Capsule", meta=(EditCondition="HitboxShape == EHitboxShape::EHS_Capsule"))
    float CapsuleRadius = 40.0f;
    UPROPERTY(Category="Hitbox|Capsule", meta=(EditCondition="HitboxShape == EHitboxShape::EHS_Capsule"))
    float CapsuleHalfHeight = 60.0f;

    // Parameters for a box hitbox.
    UPROPERTY(Category="Hitbox|Box", meta=(EditCondition="HitboxShape == EHitboxShape::EHS_Box"))
    FVector BoxExtent = FVector(50.0f, 50.0f, 50.0f);

    UPROPERTY(Category="Hitbox|Debug")
    bool bDisplayHitBoxWhileActive = false;

    UPrimitiveComponent HitboxComponent;
    UAbilityCapability CachedAbility;
    TArray<FHitResult> Hits;
    bool bHitboxActive = false;

    UFUNCTION(BlueprintOverride)
    void SetupModifier(UAbilityCapability Ability)
    {
        if (!IsValid(Ability))
            return;

        switch (HitboxShape)
        {
        case EHitboxShape::EHS_Sphere:
        {
            USphereComponent SphereComp = USphereComponent::Create(Ability.Owner);
            if (IsValid(SphereComp))
            {
                SphereComp.SetSphereRadius(SphereRadius);
                HitboxComponent = SphereComp;
            }
        }
        break;
        case EHitboxShape::EHS_Capsule:
        {
            UCapsuleComponent CapsuleComp = UCapsuleComponent::Create(Ability.Owner);
            if (IsValid(CapsuleComp))
            {
                CapsuleComp.SetCapsuleSize(CapsuleRadius, CapsuleHalfHeight);
                HitboxComponent = CapsuleComp;
            }

        }
        break;
        case EHitboxShape::EHS_Box:
        {
            UBoxComponent BoxComp = UBoxComponent::Create(Ability.Owner);
            if (IsValid(BoxComp))
            {
                BoxComp.SetBoxExtent(BoxExtent);
                HitboxComponent = BoxComp;
            }
        }
        break;
        default:
            break;
        }
        if(IsValid(HitboxComponent))
        {
            HitboxComponent.CollisionProfileName = n"Custom";
            HitboxComponent.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
            HitboxComponent.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
            HitboxComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);
            HitboxComponent.AttachToComponent(Ability.HomseOwner.Mesh, SocketName);
            CachedAbility = Ability;
        }

    }

    UFUNCTION(BlueprintOverride)
    void TeardownModifier(UAbilityCapability Ability)
    {
        if (IsValid(HitboxComponent))
        {
            HitboxComponent.DestroyComponent(HitboxComponent);
        }
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityActiveTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(Ability))
            return;

        if(Hits.Num() == 0)
            return;

        UHitContext HitContext = Cast<UHitContext>(Ability.GetOrCreateAbilityContext(UHitContext::StaticClass()));
        HitContext.Reset();

        for (FHitResult Hit : Hits)
        {
            HitContext.HitResults.Add(Hit);
        }

        Hits.Empty();        
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityCooldownTick(UAbilityCapability Ability, float DeltaTime)
    {
        if (bHitboxActive && IsValid(HitboxComponent))
        {
            HitboxComponent.OnComponentBeginOverlap.Unbind(this, n"OnHit");
            bHitboxActive = false;
            if(bDisplayHitBoxWhileActive)
                HitboxComponent.SetHiddenInGame(true);
        }
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityFire(UAbilityCapability Ability)
    {
        if(!IsValid(Ability))
            return;

        if (!IsValid(HitboxComponent))
            return;
    
        ProcessInitialHits(Ability);
        HitboxComponent.OnComponentBeginOverlap.AddUFunction(this, n"OnHit");
        bHitboxActive = true;
        if(bDisplayHitBoxWhileActive)
            HitboxComponent.SetHiddenInGame(false);
    }

    void ProcessInitialHits(UAbilityCapability Ability)
    {
        TArray<UPrimitiveComponent> OverlappingComponents;
        HitboxComponent.GetOverlappingComponents(OverlappingComponents);
        if(OverlappingComponents.Num() == 0)
            return;


        for (UPrimitiveComponent OverlapComponent : OverlappingComponents)
        {
            if (OverlapComponent == HitboxComponent
                || OverlapComponent.Owner == Ability.Owner)
                continue;

            FVector HitboxLocation = HitboxComponent.GetWorldLocation();
            FVector OverlapLocation = OverlapComponent.GetWorldLocation();

            FVector HitLocation = (HitboxLocation + OverlapLocation) * 0.5f;
            FVector HitNormal = (OverlapLocation - HitboxLocation).GetSafeNormal();

            FHitResult HitResult = FHitResult(OverlapComponent.Owner, OverlapComponent, HitLocation, HitNormal);
            Hits.Add(HitResult);
        }
    }

    UFUNCTION()
    void OnHit(UPrimitiveComponent OverLappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
    {
        Hits.Add(SweepResult);
    }

}

enum EHitboxShape
{
    EHS_None,
    EHS_Sphere,
    EHS_Box,
    EHS_Capsule
};