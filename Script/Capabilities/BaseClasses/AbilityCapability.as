class UAbilityCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    FName Slot;

    // Components
    AHomseCharacterBase HomseOwner;
    UCapabilityComponent CapComp;
    UHomseMovementComponent MoveComp;
    UAbilityComponent AbilityComp;

    // Cooldown
    UPROPERTY()
    float AbilityCooldown = 0.2f;
    float CooldownTimer = 0.0f;
    bool bIsOnCooldown = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        if (!IsValid(HomseOwner))
            return;

        CapComp = HomseOwner.CapabilityComponent;
        MoveComp = HomseOwner.HomseMovementComponent;
        AbilityComp = HomseOwner.AbilityComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        ResetCoolDown();
    }

    void ResetCoolDown()
    {
        CooldownTimer = AbilityCooldown;
        bIsOnCooldown = false;
    }

    UFUNCTION(BlueprintEvent)
    void UpdateCooldown(float DeltaTime)
    {
        if (CooldownTimer > 0.0f)
        {
            CooldownTimer -= DeltaTime;
            if (CooldownTimer <= 0.0f)
            {
                bIsOnCooldown = false;
            }
        }
    }

};