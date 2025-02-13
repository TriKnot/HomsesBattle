class UAbilityData : UDataAsset
{
    // Reference to the corresponding capability class that will use this data
    UPROPERTY()
    TSubclassOf<UAbilityCapability> AbilityCapabilityClass;

    // Common ability properties
    UPROPERTY()
    float CooldownTime;

    UPROPERTY()
    bool bCanBeCharged;
};
