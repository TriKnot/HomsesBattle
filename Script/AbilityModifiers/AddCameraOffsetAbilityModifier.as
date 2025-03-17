class UAddCameraOffsetAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    FVector Offset = FVector(0.0f, 0.0f, 0.0f);

    UPROPERTY(EditAnywhere)
    float LerpTime = 0.0f;

    UPROPERTY(EditAnywhere)
    EAbilityPhase AdditionPhase = EAbilityPhase::Activation;

    UPROPERTY(EditAnywhere)
    EAbilityPhase RemovalPhase = EAbilityPhase::Deactivation;

    UPlayerCameraComponent CameraComp;
    bool bTriggered = false;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        if (!IsValid(Ability))
            return;

        bTriggered = false;
        CameraComp = UPlayerCameraComponent::Get(Ability.Owner);

        if (!IsValid(CameraComp))
            return;
        HandlePhaseSwitch(EAbilityPhase::Activation);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityDeactivate(UAbilityCapability Ability)
    {
        if (!IsValid(CameraComp))
            return;
        HandlePhaseSwitch(EAbilityPhase::Deactivation);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityWarmUpTick(UAbilityCapability Ability, float DeltaTime)
    {
        if (!IsValid(CameraComp))
            return;
        HandlePhaseTick(EAbilityPhase::WarmUp);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityActiveTick(UAbilityCapability Ability, float DeltaTime)
    {
        if (!IsValid(CameraComp))
            return;
        HandlePhaseTick(EAbilityPhase::Active);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityCooldownTick(UAbilityCapability Ability, float DeltaTime)
    {
        if (!IsValid(CameraComp))
            return;
        HandlePhaseTick(EAbilityPhase::Cooldown);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityFire(UAbilityCapability Ability)
    {
        if (!IsValid(CameraComp))
            return;
        HandlePhaseSwitch(EAbilityPhase::Fire);
    }

    void HandlePhaseSwitch(EAbilityPhase Phase)
    {
        if (AdditionPhase == Phase)
            ToggleOffset(true);
        else if (RemovalPhase == Phase)
            ToggleOffset(false);
    }

    void HandlePhaseTick(EAbilityPhase Phase)
    {
        if (AdditionPhase != Phase && RemovalPhase != Phase)
            return;
    
        if (bTriggered)
            return;

        HandlePhaseSwitch(Phase);
        bTriggered = true;
    }

    void ToggleOffset(bool bEnable)
    {
        if (bEnable)
            CameraComp.RegisterOffset(this, Offset, LerpTime);
        else
            CameraComp.UnregisterOffset(this);
    }

}