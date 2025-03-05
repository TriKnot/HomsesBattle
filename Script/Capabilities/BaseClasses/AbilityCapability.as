class UAbilityCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    // Components
    AHomseCharacterBase HomseOwner;
    UAbilityComponent AbilityComp;

    FCooldownTimer CooldownTimer;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        if (!IsValid(HomseOwner))
            return;

        AbilityComp = HomseOwner.AbilityComponent;
    }

};