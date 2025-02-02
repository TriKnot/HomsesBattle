class ASHomsePlayerCharacter : AHomseCharacterBase
{
    UPROPERTY(DefaultComponent)
    UPlayerInputComponent InputComponent;

    default CapabilityComponent.CapabilitiesTypes.Add(UDashCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UUnlockComponentCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UMovementCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UPlayerCameraCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UJumpCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UDeathCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UMeleeAttackCapability::StaticClass());
}