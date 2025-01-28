class UPlayerCameraCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    AHomseCharacterBase HomseOwner;
    UCapabilityComponent CapabilityComponent;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        CapabilityComponent = HomseOwner.CapabilityComponent;
    }

    UFUNCTION(BlueprintOverride)
    void Teardown()
    {
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return CapabilityComponent.MouseDelta != FVector2D::ZeroVector;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return CapabilityComponent.MouseDelta == FVector2D::ZeroVector;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        HomseOwner.AddControllerYawInput(CapabilityComponent.MouseDelta.X);
        HomseOwner.AddControllerPitchInput(-CapabilityComponent.MouseDelta.Y);
    }
};