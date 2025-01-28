class UDashCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;
    UHomseMovementComponent MoveComp;
    UCapabilityComponent CapabilityComp;

    float Duration = 0.2f;
    float DashLength = 1000.0f;
    FVector DashVelocity;
    float DashTimer = 0.0f;

    FVector InitialVelocity;


    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(Owner);
        MoveComp = HomseOwner.HomseMovementComponent;
        CapabilityComp = HomseOwner.CapabilityComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        if(!CapabilityComp.GetActionStatus(InputActions::Dash))
            return false;
        
        if(MoveComp.bIsBlocked)
            return false;

        if(MoveComp.GetVelocity().Size() < KINDA_SMALL_NUMBER)
            return false;

        return  true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return DashTimer >= Duration;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        DashTimer = 0.0f;
        DashVelocity = MoveComp.Velocity.GetSafeNormal() * (DashLength / Duration);
        DashVelocity.Z = 0.0f;
        InitialVelocity = MoveComp.Velocity;
        MoveComp.Lock();
    }
    
    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        DashVelocity = FVector::ZeroVector;
        MoveComp.SetVelocity(InitialVelocity);
        MoveComp.Unlock();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        DashTimer += DeltaTime;
        
        float Alpha = Math::Clamp(DashTimer / Duration, 0.0f, 1.0f);
        float ZVelocity = MoveComp.Velocity.Z;
        FVector NewVelocity = Math::Lerp(DashVelocity, InitialVelocity, Alpha);
        NewVelocity.Z = ZVelocity;
        MoveComp.SetVelocity(NewVelocity);
        MoveComp.Lock();
    }
};