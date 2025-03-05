class UDashCapability : UAbilityCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    UPlayerCameraComponent CameraComp;
    UHomseMovementComponent MoveComp;
    UCapabilityComponent CapComp;
    UDashAbilityData DashData;
    UAsyncRootMovement AsyncRootMove;

    float InitialVelocity = 0.0f;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Super::Setup();
        MoveComp = UHomseMovementComponent::Get(Owner);
        CapComp = UCapabilityComponent::Get(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        if(MoveComp.IsLocked())
            return false;

        if(!AbilityComp.IsAbilityActive(this))
            return false;

        if(CapComp.MovementInput.IsNearlyZero())
            return false;

        return  true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return CooldownTimer.IsExpired();
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        Super::OnActivate();

        DashData = Cast<UDashAbilityData>(AbilityComp.GetAbilityData(this));
        CooldownTimer = FCooldownTimer(DashData.CooldownTime);

        MoveComp.bIsDashing = true;
        FVector2D MoveInput = CapComp.MovementInput;
        FRotator ControllerRotator = HomseOwner.GetControlRotation();

        FVector DashDirection = FVector(ControllerRotator.GetForwardVector() * MoveInput.Y + ControllerRotator.GetRightVector() * MoveInput.X);
        DashDirection.Z = 0.0f;
        DashDirection.Normalize();
        InitialVelocity = MoveComp.Velocity.Size();

        AsyncRootMove = UAsyncRootMovement::ApplyConstantForce
        (
            MoveComp.CharacterMovement, 
            DashDirection, 
            DashData.DashStrength, 
            DashData.Duration, 
            false, 
            DashData.DashCurve,
            true, 
            ERootMotionFinishVelocityMode::ClampVelocity, 
            FVector::ZeroVector, 
            InitialVelocity * 2
        );

        AsyncRootMove.OnMovementFailed.AddUFunction(this, n"OnDashFinished");
        AsyncRootMove.OnMovementFinished.AddUFunction(this, n"OnDashFinished");

        MoveComp.Lock(this);

        CameraComp = Cast<UPlayerCameraComponent>(HomseOwner.GetComponent(UPlayerCameraComponent::StaticClass()));
        if(IsValid(CameraComp))
        {
            FVector CameraOffset = FVector(MoveInput.Y * -DashData.CameraOffsetMultiplier.X, MoveInput.X * -DashData.CameraOffsetMultiplier.Y, 0);
            CameraComp.RegisterOffset(this, CameraOffset, DashData.Duration / 2);
        }

        CooldownTimer.Reset();
    }

    
    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        AsyncRootMove = nullptr;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        CooldownTimer.Tick(DeltaTime);

        if(!IsValid(AsyncRootMove) || !AsyncRootMove.IsActive())
        {
            if(IsValid(CameraComp))
            {
                CameraComp.UnregisterOffset(this);
            }
            CooldownTimer.Start();
            return;   
        }
    }

    UFUNCTION()
    void OnDashFinished()
    {
        MoveComp.Unlock(this);
        MoveComp.bIsDashing = false;
    }
};