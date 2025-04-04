class UPlayerCameraCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    AHomseCharacterBase HomseOwner;
    UCapabilityComponent CapabilityComponent;
    UPlayerCameraComponent CameraComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        CapabilityComponent = HomseOwner.CapabilityComponent;
        APlayerController PlayerController = Cast<APlayerController>(HomseOwner.Controller);

        CameraComp = Cast<UPlayerCameraComponent>(UPlayerCameraComponent::GetOrCreate(HomseOwner));

        CameraComp.SpringArmComp = USpringArmComponent::Create(HomseOwner);
        CameraComp.SpringArmComp.AttachToComponent(HomseOwner.RootComponent);
        CameraComp.SpringArmComp.TargetArmLength = 650.0f;
        CameraComp.SpringArmComp.bUsePawnControlRotation = true;
        CameraComp.SpringArmComp.ProbeSize = 12.0f;
        CameraComp.SpringArmComp.bDoCollisionTest = true;
        CameraComp.SpringArmComp.bEnableCameraLag = false;

        CameraComp.CameraComp = UCameraComponent::Create(HomseOwner);
        CameraComp.CameraComp.AttachToComponent(CameraComp.SpringArmComp);
        CameraComp.CameraComp.ProjectionMode = ECameraProjectionMode::Perspective;
        CameraComp.CameraComp.FieldOfView = 90.0f;
        CameraComp.CameraComp.bOverrideAspectRatioAxisConstraint = true;
        CameraComp.CameraComp.AspectRatioAxisConstraint = EAspectRatioAxisConstraint::AspectRatio_MajorAxisFOV;

        CameraComp.CameraShakeComp = UCameraShakeComponent::Create(HomseOwner);

        if (PlayerController != nullptr)
        {
            PlayerController.SetViewTargetWithBlend(HomseOwner);
        }
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return true; 
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return false; 
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        HomseOwner.AddControllerYawInput(CapabilityComponent.MouseDelta.X);
        HomseOwner.AddControllerPitchInput(-CapabilityComponent.MouseDelta.Y);

        if(CameraComp.ActiveOffsets.Num() > 0 || CameraComp.RevertingOffsets.Num() > 0)
        {
            UpdateCameraOffset(DeltaTime);
        }
    }

    void UpdateCameraOffset(float DeltaTime)
    {
        FVector TotalOffset;

        // Tick Active forwards
        for (auto& Pair : CameraComp.ActiveOffsets)
        {
            FCameraOffsetTarget& Offset = Pair.Value;
            TotalOffset += Offset.GetDeltaOffset(DeltaTime);
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

        CameraComp.AddCameraOffset(TotalOffset);
    }
};