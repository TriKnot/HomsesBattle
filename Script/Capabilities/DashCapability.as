class UDashCapability : UAbilityCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    UPlayerCameraComponent CameraComp;
    UDashAbilityData DashData;
    UAsyncRootMovement AsyncRootMove;

    float InitialVelocity = 0.0f;

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        if(MoveComp.bIsLocked)
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
        return CooldownTimer <= 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        Super::OnActivate();

        DashData = Cast<UDashAbilityData>(AbilityComp.GetAbilityData(this));
        AbilityCooldown = DashData.CooldownTime;

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

        MoveComp.Lock();

        CameraComp = Cast<UPlayerCameraComponent>(HomseOwner.GetComponent(UPlayerCameraComponent::StaticClass()));
        if(IsValid(CameraComp))
        {
            FVector CameraOffset = FVector(MoveInput.Y * -DashData.CameraOffsetMultiplier.X, MoveInput.X * -DashData.CameraOffsetMultiplier.Y, 0);
            CameraComp.RegisterOffset(this, CameraOffset, DashData.Duration / 2);
        }
    }

    
    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        AsyncRootMove = nullptr;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!IsValid(AsyncRootMove) || !AsyncRootMove.IsActive())
        {
            if(IsValid(CameraComp))
            {
                CameraComp.UnregisterOffset(this);
            }
            UpdateCooldown(DeltaTime);
            return;   
        }
    }

    UFUNCTION()
    void OnDashFinished()
    {
        MoveComp.Unlock();
        MoveComp.bIsDashing = false;
    }
};