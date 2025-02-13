class UMeleeAttackCapability : UAbilityCapability
{
    default Priority = ECapabilityPriority::PostInput;

    USphereComponent HitSphere;
    UMeleeAttackData MeleeAbilityData;

    float DamageAmount = 10.0f;
    float ActiveDuration = 0.1f;
    float CooldownTime = 0.2f;
    float DashStrength = 1500.0f;


    float DashLength = 1000.0f;
    bool bShouldBrake = false;
    float InitialVelocity;

    TArray<AActor> HitActors;
    UAsyncRootMovement AsyncRootMove;


    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Super::Setup();
        if(!IsValid(HomseOwner))
            return;

        HitSphere = USphereComponent::Create(Owner);
        HitSphere.CollisionProfileName = n"Custom";
        HitSphere.CollisionEnabled = ECollisionEnabled::QueryOnly;
        HitSphere.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
        HitSphere.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);
        HitSphere.SetSphereRadius(50.0f);
    }

    UFUNCTION(BlueprintOverride)
    void Teardown()
    {
        HitSphere.DestroyComponent(HitSphere);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return AbilityComp.IsAbilityActive(this);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() 
    { 
        return !bIsOnCooldown;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        Super::OnActivate();

        MeleeAbilityData = Cast<UMeleeAttackData>(AbilityComp.GetAbilityData(this));

        HitActors.Empty();
        
        HitSphere.AttachToComponent(HomseOwner.Mesh, MeleeAbilityData.Socket);

        if(MoveComp.IsGrounded)
            AbilityHelpers::RotateActorToCameraRotation(HomseOwner);

        // Dash in the direction the character is facing
        FRotator DashDirection = HomseOwner.GetActorRotation();
        DashDirection.Pitch = 0.0f;
        DashDirection.Normalize();

        Dash(DashDirection.Vector());

        // Check for any actors that are hit by the sphere on activation
        TArray<UHealthComponent> HitHealthComps;
        if(AbilityHelpers::TryGetHitHealthComponents(Cast<UPrimitiveComponent>(HitSphere), HitHealthComps))
        {
            for(UHealthComponent HitHealthComp : HitHealthComps)
            {
                DealDamageToHealthComponent(HitHealthComp);
            }
        }

        // Handle the case where the sphere hits an actor after activation
        HitSphere.OnComponentBeginOverlap.AddUFunction(this, n"OnHit");

        bIsOnCooldown = true;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        // If dash is finished, update cooldown and return
        if(!IsValid(AsyncRootMove) || AsyncRootMove.MovementState != ERootMotionState::Ongoing) 
        {
            UpdateCooldown(DeltaTime);
            MoveComp.SetOrientToMovement(true);
            return;   
        }
        
        System::DrawDebugSphere(HitSphere.GetWorldLocation(), HitSphere.SphereRadius, 12, FLinearColor::Red, 0);
    }

    UFUNCTION()
    void OnHit(UPrimitiveComponent OverLappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
    {
        UHealthComponent HitHealthComp = UHealthComponent::Get(OtherActor);
        if(IsValid(HitHealthComp))
            return;
        DealDamageToHealthComponent(HitHealthComp);
    }

    void DealDamageToHealthComponent(UHealthComponent HealthComp)
    {
        AActor HitActor = HealthComp.GetOwner();
        if(HitActor == Owner || HitActors.Contains(HitActor))
            return;

        FDamageInstanceData DamageInstance;
        DamageInstance.DamageAmount = DamageAmount;
        DamageInstance.SourceActor = Owner;
        DamageInstance.DamageLocation = HitSphere.GetWorldLocation();
        DamageInstance.DamageDirection = HealthComp.Owner.GetActorLocation() - Owner.GetActorLocation();
        HealthComp.DamageInstances.Add(DamageInstance);
    }

    void Dash(FVector DashDirection)
    {
        InitialVelocity = MoveComp.Velocity.Size();

        AsyncRootMove = UAsyncRootMovement::ApplyConstantForce
        (
            MoveComp.CharacterMovement, 
            DashDirection, 
            DashStrength, 
            ActiveDuration, 
            false, 
            MoveComp.DashCurve, 
            true, 
            ERootMotionFinishVelocityMode::ClampVelocity, 
            FVector::ZeroVector, 
            InitialVelocity * 2
        );

    }

};