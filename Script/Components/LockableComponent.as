class ULockableComponent : UActorComponent
{
    UPROPERTY()
    bool bIsLocked;

    UFUNCTION(BlueprintEvent)
    void Lock()
    {
        bIsLocked = true;
    }

    UFUNCTION(BlueprintEvent)
    void Unlock()
    {
        bIsLocked = false;
    }
}