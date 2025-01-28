class ASHomsePlayerCharacter : AHomseCharacterBase
{
    UPROPERTY(DefaultComponent)
    UPlayerInputComponent Input;

    default CapabilityComponent.CapabilitiesTypes.Add(UDashCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UUnlockComponentCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UMovementCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UPlayerCameraCapability::StaticClass());

}