class UDeathCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    AHomseCharacterBase HomseOwner;
    UHealthComponent HealthComp;
    TArray<ULockableComponent> LockableComponents;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        HomseOwner.GetComponentsByClass(LockableComponents);
        HealthComp = HomseOwner.HealthComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return HealthComp.CurrentHealth <= 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        HomseOwner.CapsuleComponent.SetSimulatePhysics(true);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        for(ULockableComponent LockableComponent : LockableComponents)
        {
            LockableComponent.Lock(this);
        }
    }
};