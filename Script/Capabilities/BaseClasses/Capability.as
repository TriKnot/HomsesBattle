enum ECapabilityPriority
{
    MIN         UMETA(Hidden),
    PostInput,
    PreMovement,
    Movement,
    PostMovement,
    MAX         UMETA(Hidden)
}

class UCapability : UObject
{
    UCapabilityComponent OwningComponent;
    AActor Owner;
    ECapabilityPriority Priority = ECapabilityPriority::PostMovement;

    UPROPERTY(NotEditable)
    bool bIsActive = false;
    UPROPERTY(NotEditable)
    bool bIsBlocked = false;

    void Initialize(UCapabilityComponent inOwningComponent, AActor inOwningActor)
    {
        OwningComponent = inOwningComponent;
        Owner = inOwningActor;
    }

    UFUNCTION(BlueprintEvent)
    void Setup() {}

    UFUNCTION(BlueprintEvent)
    void Teardown() {}

    UFUNCTION(BlueprintEvent)
    bool ShouldActivate() { return false; }

    UFUNCTION(BlueprintEvent)
    bool ShouldDeactivate() { return true; }

    UFUNCTION(BlueprintEvent)
    void OnActivate() {}

    UFUNCTION(BlueprintEvent)
    void OnDeactivate() {}

    UFUNCTION(BlueprintEvent)
    void TickActive(float DeltaTime) {}

    UFUNCTION(BlueprintEvent)
    void ResetFrameTransient() {}
}