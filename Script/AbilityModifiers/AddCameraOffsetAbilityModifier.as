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

        if(AdditionPhase == EAbilityPhase::Activation)
            ToggleOffset(true);
        else if(RemovalPhase == EAbilityPhase::Activation)
            ToggleOffset(false);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityDeactivate(UAbilityCapability Ability)
    {
        if (!IsValid(CameraComp))
            return;

        if(AdditionPhase == EAbilityPhase::Deactivation)
            ToggleOffset(true);
        else if(RemovalPhase == EAbilityPhase::Deactivation)
            ToggleOffset(false);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityTick(UAbilityCapability Ability, float DeltaTime)
    {
        if (!IsValid(CameraComp))
            return;

        if (AdditionPhase != EAbilityPhase::Tick || RemovalPhase != EAbilityPhase::Tick)
            return;

        if(bTriggered)
            return;

        if(AdditionPhase == EAbilityPhase::Tick)
            ToggleOffset(true);
        else if(RemovalPhase == EAbilityPhase::Tick)
            ToggleOffset(false);

        bTriggered = true;
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityFire(UAbilityCapability Ability)
    {
        if (!IsValid(CameraComp))
            return;

        if(AdditionPhase == EAbilityPhase::Fire)
            ToggleOffset(true);
        else if(RemovalPhase == EAbilityPhase::Fire)
            ToggleOffset(false);
    }

    void ToggleOffset(bool bEnable)
    {
        if (bEnable)
            CameraComp.RegisterOffset(this,Offset, LerpTime);
        else
            CameraComp.UnregisterOffset(this);
    }
    
}