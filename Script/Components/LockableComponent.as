class ULockableComponent : UActorComponent
{
    UPROPERTY()
    bool bIsBlocked;

    UFUNCTION(BlueprintEvent)
    void Lock()
    {
        bIsBlocked = true;
    }

    UFUNCTION(BlueprintEvent)
    void Unlock()
    {
        bIsBlocked = false;
    }
}