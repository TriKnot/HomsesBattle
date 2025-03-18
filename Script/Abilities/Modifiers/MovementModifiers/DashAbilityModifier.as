class UDashAbilityModifier : UAbilityModifier
{
    UPROPERTY()
    float DashStrength;

    UPROPERTY()
    float Duration;

    UPROPERTY()
    UCurveFloat DashCurve;

    UHomseMovementComponent MoveComp;
    UCapabilityComponent CapComp;

    float InitialVelocity = 0.0f;
    UAsyncRootMovement AsyncRootMove;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        if (!IsValid(Ability))
            return;

        MoveComp = UHomseMovementComponent::Get(Ability.Owner);
        CapComp = UCapabilityComponent::Get(Ability.Owner);

        if (!IsValid(MoveComp) || !IsValid(CapComp))
            return;

        FVector2D MoveInput = CapComp.MovementInput;
        FRotator ControllerRotator = Ability.HomseOwner.GetControlRotation();

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
            DashCurve,
            true, 
            ERootMotionFinishVelocityMode::ClampVelocity, 
            FVector::ZeroVector, 
            InitialVelocity * 2
        );

        AsyncRootMove.OnMovementFailed.AddUFunction(this, n"OnDashFinished");
        AsyncRootMove.OnMovementFinished.AddUFunction(this, n"OnDashFinished");
        
        MoveComp.bIsDashing = true;
    }
    
    UFUNCTION()
    void OnDashFinished()
    {
        MoveComp.bIsDashing = false;
    }

}