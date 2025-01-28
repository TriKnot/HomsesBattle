class AHomseCharacterBase : ACharacter
{
    UPROPERTY(DefaultComponent)
    UCapabilityComponent CapabilityComponent;

    UPROPERTY(DefaultComponent)
    private UHomseMovementComponent Movement;

    default CapsuleComponent.SimulatePhysics = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CapsuleComponent.SimulatePhysics = false;
    }

    UFUNCTION(BlueprintPure)
    UHomseMovementComponent GetHomseMovementComponent() property
    {
        return Movement;
    }

    UPROPERTY()
    bool bIsJumping = false;

}