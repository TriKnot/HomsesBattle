class UAbilityCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    // Components
    AHomseCharacterBase HomseOwner;
    UCapabilityComponent CapComp;
    UHomseMovementComponent MoveComp;

    // Cooldown
    UPROPERTY()
    float AbilityCooldown = 0.2f;
    float CooldownTimer = 0.0f;
    bool OnCooldown = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        if (!IsValid(HomseOwner))
            return;

        CapComp = HomseOwner.CapabilityComponent;
        MoveComp = HomseOwner.HomseMovementComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return CooldownTimer <= 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        ResetCoolDown();
    }

    void ResetCoolDown()
    {
        CooldownTimer = AbilityCooldown;
        OnCooldown = false;
    }

    UFUNCTION(BlueprintEvent)
    void UpdateCooldown(float DeltaTime)
    {
        if (CooldownTimer > 0.0f)
        {
            CooldownTimer -= DeltaTime;
            if (CooldownTimer <= 0.0f)
            {
                OnCooldown = false;
            }
        }
    }

};