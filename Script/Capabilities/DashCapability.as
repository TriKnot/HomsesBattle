class UDashCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;
    UHomseMovementComponent MoveComp;
    UCapabilityComponent CapabilityComp;
    AHomseCharacterBase HomseOwner;
    UAsyncRootMovement AsyncRootMove;

    float Duration = 0.2f;
    float DashStrength = 2500.0f;
    float CooldownTimer = 0.0f;
    float DashCooldown = 1.0f;
    float InitialVelocity = 0.0f;


    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
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

        if(CapabilityComp.MovementInput.IsNearlyZero())
            return false;

        return  true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return CooldownTimer >= DashCooldown;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        CooldownTimer = 0.0f;
        FVector2D MoveInput = CapabilityComp.MovementInput;
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
        if(!IsValid(AsyncRootMove) || AsyncRootMove.MovementState == ERootMotionState::Ongoing)
            return;

        CooldownTimer += DeltaTime;        
    }
};