class ASHomsePlayerCharacter : AHomseCharacterBase
{
    UPROPERTY(DefaultComponent)
    UPlayerInputComponent InputComponent;

    default CapabilityComponent.CapabilitiesTypes.Add(UMovementCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UPlayerCameraCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UCameraShakeCapability::StaticClass());

    default Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

}