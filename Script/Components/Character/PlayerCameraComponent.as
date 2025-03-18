class UPlayerCameraComponent : UActorComponent
{
    access CameraProtection = protected, UPlayerCameraCapability, UCameraShakeCapability;
    access:CameraProtection USpringArmComponent SpringArmComp;
    access:CameraProtection UCameraComponent CameraComp;

    UCameraShakeComponent CameraShakeComp;

    TMap<UObject, FCameraOffsetTarget> ActiveOffsets;
    TMap<UObject, FCameraOffsetTarget> RevertingOffsets;

    void RegisterOffset(UObject Capability, FVector& Offset, float LerpTime, bool bOverridePrevious = false)
    {
        if (ActiveOffsets.Contains(Capability) && !bOverridePrevious)
            return;

        FCameraOffsetTarget OffsetTarget;
        OffsetTarget.TargetOffset = Offset;
        OffsetTarget.LerpTime = LerpTime;
        OffsetTarget.LocalT = 0.0f;
        
        if (RevertingOffsets.Contains(Capability))
        {
            RevertingOffsets.Remove(Capability);
        }

        ActiveOffsets.Remove(Capability);
        ActiveOffsets.Add(Capability, OffsetTarget);
    }

    void UnregisterOffset(UObject Capability)
    {
        if (ActiveOffsets.Contains(Capability))
        {
            FCameraOffsetTarget OffsetTarget = ActiveOffsets[Capability];
            ActiveOffsets.Remove(Capability);
            RevertingOffsets.Add(Capability, OffsetTarget);
        }
    }

    void AddCameraOffset(FVector NewOffset)
    {
        CameraComp.AddRelativeLocation(NewOffset);
    }

    void EnableCameraDrag(bool bEnable)
    {
        SpringArmComp.bEnableCameraLag = bEnable;
    }

    FVector GetCameraOffset() const property
    {
        return CameraComp.GetRelativeLocation();
    }
};

struct FCameraOffsetTarget 
{
    FVector TargetOffset;
    float LerpTime;
    float LocalT;

    // Computes the forward delta offset for the current tick.
    FVector GetDeltaOffset(float DeltaTime)
    {
        // Compute the offset before updating.
        float CurrentAlpha = (LerpTime > 0.0f) ? (LocalT / LerpTime) : 1.0f;
        FVector CurrentOffset = Math::Lerp(FVector::ZeroVector, TargetOffset, CurrentAlpha);

        // Increment LocalT and clamp to LerpTime.
        float NewLocalT = Math::Min(LocalT + DeltaTime, LerpTime);
        float NewAlpha = (LerpTime > 0.0f) ? (NewLocalT / LerpTime) : 1.0f;
        FVector NewOffset = Math::Lerp(FVector::ZeroVector, TargetOffset, NewAlpha);

        // Update state.
        LocalT = NewLocalT;
        // Return only the difference (delta) between frames.
        return NewOffset - CurrentOffset;
    }

    // Computes the reverse delta offset for the current tick.
    FVector GetDeltaOffsetReverse(float DeltaTime)
    {
        float CurrentAlpha = (LerpTime > 0.0f) ? (LocalT / LerpTime) : 1.0f;
        FVector CurrentOffset = Math::Lerp(FVector::ZeroVector, TargetOffset, CurrentAlpha);

        // Decrement LocalT down to zero.
        float NewLocalT = Math::Max(LocalT - DeltaTime, 0.0f);
        float NewAlpha = (LerpTime > 0.0f) ? (NewLocalT / LerpTime) : 1.0f;
        FVector NewOffset = Math::Lerp(FVector::ZeroVector, TargetOffset, NewAlpha);

        LocalT = NewLocalT;
        return NewOffset - CurrentOffset;
    }

    bool IsReverted() const
    {
        return LocalT <= 0.0f;
    }
}