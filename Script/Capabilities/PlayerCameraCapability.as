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

        UpdateCameraOffset(DeltaTime);
    }

    void UpdateCameraOffset(float DeltaTime)
    {
        FVector TotalOffset;

        // Tick Active forwards
        for (auto& Pair : CameraComp.ActiveOffsets)
        {
            FCameraOffsetTarget& Offset = Pair.Value;

            FVector OffsetContribution = Offset.GetDeltaOffset(DeltaTime);
            TotalOffset += OffsetContribution;
        }

        // Tick Reverting backwards
        TArray<UObject> RevertingKeys;
        CameraComp.RevertingOffsets.GetKeys(RevertingKeys);
        for (UObject Key : RevertingKeys)
        {
            FCameraOffsetTarget& Offset = CameraComp.RevertingOffsets[Key];
            TotalOffset += Offset.GetDeltaOffsetReverse(DeltaTime);

            // Remove pair from original map if fully reverted
            if (Offset.IsReverted())
            {
                CameraComp.RevertingOffsets.Remove(Key);
            }
        }

        FVector CurrentOffset = CameraComp.GetCameraOffset();
        FVector NewOffset = Math::VInterpTo(CurrentOffset, TotalOffset, DeltaTime, 10.0f);
        CameraComp.AddCameraOffset(TotalOffset);
    }
};