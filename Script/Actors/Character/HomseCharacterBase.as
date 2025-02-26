class AHomseCharacterBase : ACharacter
{
    UPROPERTY(DefaultComponent)
    UCapsuleComponent SnoutCapsuleComponent;

    UPROPERTY(DefaultComponent)
    UCapabilityComponent CapabilityComponent;

    UPROPERTY(DefaultComponent)
    UHealthComponent HealthComponent;

    UPROPERTY(DefaultComponent)
    private UHomseMovementComponent Movement;

    UPROPERTY(DefaultComponent)
    UAbilityComponent AbilityComponent;

    default CapsuleComponent.SimulatePhysics = true;
    default CapsuleComponent.CollisionProfileName = n"Custom";
    default CapsuleComponent.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
    default CapsuleComponent.CollisionResponseToAllChannels = ECollisionResponse::ECR_Block;
    default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Ignore);
    default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

    default SnoutCapsuleComponent.CollisionProfileName = n"Custom";
    default SnoutCapsuleComponent.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
    default SnoutCapsuleComponent.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
    default SnoutCapsuleComponent.CollisionResponseToAllChannels = ECollisionResponse::ECR_Block;
    default SnoutCapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Ignore);
    default SnoutCapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
    default SnoutCapsuleComponent.RelativeLocation = FVector(37.5f, 0.0f, 10.0f);
    default SnoutCapsuleComponent.RelativeRotation = FRotator(53.0f, 0.0f,  0.0f);
    default SnoutCapsuleComponent.CapsuleRadius = 22.0f;
    default SnoutCapsuleComponent.CapsuleHalfHeight = 85.0f;

    default CapabilityComponent.CapabilitiesTypes.Add(UDeathCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UDamageHandlerCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UDashCapability::StaticClass());
    default CapabilityComponent.CapabilitiesTypes.Add(UKnockbackHandlerCapacity::StaticClass());


    UFUNCTION(BlueprintPure)
    UHomseMovementComponent GetHomseMovementComponent() property
    {
        return Movement;
    }

    UPROPERTY()
    bool bIsJumping = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CapsuleComponent.SimulatePhysics = false;
    }

}