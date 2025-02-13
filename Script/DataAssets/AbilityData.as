class UAbilityData : UDataAsset
{
    // Reference to the corresponding capability class that will use this data
    UPROPERTY()
    TSubclassOf<UAbilityCapability> AbilityCapabilityClass;

    // Common ability properties
    UPROPERTY()
    float CooldownTime = 0.2f;

    UPROPERTY()
    bool bCanBeCharged = false;
};
