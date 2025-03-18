class UCameraShakeCapability : UCapability
{
    UCameraShakeComponent CameraShakeComp;
    UPlayerCameraComponent CameraComponent;
    UCapabilityComponent CapComp;
    float Cooldown = 0.1f;
    float CooldownTimer;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        AHomseCharacterBase HomseOwner = Cast<AHomseCharacterBase>(Owner);
        CapComp = HomseOwner.CapabilityComponent;
        CameraShakeComp = Cast<UCameraShakeComponent>(Owner.GetOrCreateComponent(UCameraShakeComponent::StaticClass()));
        CameraComponent = Cast<UPlayerCameraComponent>(HomseOwner.GetOrCreateComponent(UPlayerCameraComponent::StaticClass()));
        CameraShakeComp.Init(CameraComponent.CameraComp, 5.0f, 5.0f, 1.0f);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return CapComp.GetActionStatus(InputActions::Test);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return CooldownTimer <= 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        CooldownTimer = Cooldown;        
        CameraShakeComp.AddIntensity(0.2f);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        CooldownTimer -= DeltaTime;
    }
};