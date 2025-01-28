class AHomseCharacterBase : ACharacter
{
    UPROPERTY(DefaultComponent)
    UCapabilityComponent CapabilityComponent;

    UPROPERTY(DefaultComponent)
    private UHomseMovementComponent Movement;

    UFUNCTION(BlueprintPure)
    UHomseMovementComponent GetHomseMovementComponent() property
    {
        return Movement;
    }

    UPROPERTY()
    bool bIsJumping = false;

}