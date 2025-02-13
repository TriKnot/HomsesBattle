class UDashCapability : UAbilityCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    UAsyncRootMovement AsyncRootMove;

    float Duration = 0.2f;
    float DashStrength = 2500.0f;
    float DashCooldown = 1.0f;
    float InitialVelocity = 0.0f;

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        if(!CapComp.GetActionStatus(InputActions::Dash))
            return false;
        
        if(MoveComp.bIsLocked)
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
            DashStrength, 
            Duration, 
            false, 
            MoveComp.DashCurve, 
            true, 
            ERootMotionFinishVelocityMode::ClampVelocity, 
            FVector::ZeroVector, 
            InitialVelocity * 2
        );

        MoveComp.Lock();
    }

    
    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        MoveComp.Unlock();
        AsyncRootMove = nullptr;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!IsValid(AsyncRootMove) || AsyncRootMove.MovementState != ERootMotionState::Ongoing)
        {
            UpdateCooldown(DeltaTime);
            MoveComp.bIsDashing = false;
            return;   
        }
    }
};