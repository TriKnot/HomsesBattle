class UMeleeAttackCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    UHitSphereComponent HitBox;
    UHomseMovementComponent MoveComp;
    AHomseCharacterBase HomseOwner;
    UCapabilityComponent CapComp;

    float DamageAmount = 10.0f;
    float ActiveDuration = 0.1f;
    float CooldownTime = 0.2f;
    float DashStrength = 1000.0f;


    float DashLength = 1000.0f;
    bool bShouldBrake = false;
    float InitialVelocity;

    float CooldownTimer = 0.0f;
    TArray<AActor> HitActors;
    UAsyncRootMovement AsyncRootMove;


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
        return CooldownTimer >= CooldownTime;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        HitActors.Empty();
        CooldownTimer = 0.0f;

        // Snap character rotation to camera rotation
        FRotator DashDirection = HomseOwner.GetControlRotation();
        DashDirection.Pitch = 0.0f;
        DashDirection.Normalize();
        //HomseOwner.SetActorRotation(DashDirection);
        MoveComp.SetOrientToMovement(false);

        InitialVelocity = MoveComp.Velocity.Size();

        AsyncRootMove = UAsyncRootMovement::ApplyConstantForce
        (
            MoveComp.CharacterMovement, 
            DashDirection.Vector(), 
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

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!IsValid(AsyncRootMove) || AsyncRootMove.MovementState != ERootMotionState::Ongoing)
        {
            CooldownTimer += DeltaTime;
            MoveComp.SetOrientToMovement(true);
            return;   
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