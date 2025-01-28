class UUnlockComponentCapability : UCapability
{
    default Priority = ECapabilityPriority::MIN; // This capability should be activated first
    TArray<ULockableComponent> LockableComponents;

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
    void OnActivate()
    {
        // Get all components from owner that are lockable
        TArray<UActorComponent> Components = Owner.GetComponentsByClass(ULockableComponent::StaticClass());
        for(UActorComponent Component : Components)
        {
            ULockableComponent LockableComponent = Cast<ULockableComponent>(Component);
            if(LockableComponent != nullptr)
            {
                LockableComponents.Add(LockableComponent);
            }
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        // Unlock all lockable components
        for(ULockableComponent LockableComponent : LockableComponents)
        {
            LockableComponent.Unlock();
        }
    }
};