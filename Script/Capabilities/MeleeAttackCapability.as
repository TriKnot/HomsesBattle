class UMeleeAttackCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    UHitSphereComponent HitBox;
    UHomseMovementComponent MoveComp;
    AHomseCharacterBase HomseOwner;
    UCapabilityComponent CapComp;

    float DamageAmount = 10.0f;
    float ActiveDuration = 0.2f;
    float CooldownTime = 0.5f;

    float DashLength = 1000.0f;
    bool bShouldBrake = false;
    FVector InitialVelocity;

    float ActiveTimer = 0.0f;
    TArray<AActor> HitActors;


    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        CapComp = HomseOwner.CapabilityComponent;
        MoveComp = HomseOwner.HomseMovementComponent;
        HitBox = UHitSphereComponent::Create(Owner);
        HitBox.AttachToComponent(Owner.RootComponent);
        HitBox.SetSphereRadius(50.0f);
        HitBox.SetRelativeLocation(FVector(125.0f, 0.0f, 0.0f));
    }

    UFUNCTION(BlueprintOverride)
    void Teardown()
    {
        HitBox.DestroyComponent(HitBox);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return CapComp.GetActionStatus(InputActions::PrimaryAttack);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return ActiveTimer >= ActiveDuration + CooldownTime;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        ActiveTimer = 0.0f;
        HitActors.Empty();
        InitialVelocity = MoveComp.Velocity;

        MoveComp.AddVelocity(HomseOwner.ActorForwardVector * DashLength);
        bShouldBrake = true;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        ActiveTimer += DeltaTime;

        if(ActiveTimer >= ActiveDuration)
        {
            if(bShouldBrake)
            {
                MoveComp.SetVelocity(InitialVelocity);
                bShouldBrake = false;
            }
        }


        TArray<UHealthComponent> HitHealthComps;
        if(HitBox.TryGetHitHealthComponents(HitHealthComps))
        {
            for(UHealthComponent HitHealthComp : HitHealthComps)
            {
                AActor HitActor = HitHealthComp.GetOwner();
                if(HitActors.Contains(HitActor))
                    continue;

                FDamageInstanceData DamageInstance;

                DamageInstance.DamageAmount = DamageAmount;
                DamageInstance.SourceActor = Owner;
                DamageInstance.DamageLocation = HitBox.GetWorldLocation();
                DamageInstance.DamageDirection = HitActor.GetActorLocation() - Owner.GetActorLocation();
                HitHealthComp.DamageInstances.Add(DamageInstance);
                HitActors.Add(HitHealthComp.GetOwner());
            }
        }


        System::DrawDebugSphere(HitBox.GetWorldLocation(), HitBox.SphereRadius, 12, FLinearColor::Red, 0);
    }
};