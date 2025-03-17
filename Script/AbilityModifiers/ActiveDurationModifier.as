class UActiveDurationModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float ActiveDuration = 1.0f;

    UFUNCTION(BlueprintOverride)
    void SetupModifier(UAbilityCapability Ability)
    {
        Ability.ActiveDuration = ActiveDuration;
    }

}