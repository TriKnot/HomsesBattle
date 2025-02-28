class ULockableComponent : UActorComponent
{
    TArray<UObject> LockingSources;

    UFUNCTION()
    bool IsLocked(UObject IgnoredSource = nullptr) const
    {
        for(UObject Source : LockingSources)
        {
            if(Source != IgnoredSource)
                return true;
        }
        return false;
    }

    UFUNCTION()
    bool IsLockedIgnoringAny(TArray<UObject> IgnoredSources = TArray<UObject>()) const
    {
        for(UObject Source : IgnoredSources)
        {
            if(!LockingSources.Contains(Source))
                return true;
        }
        return false;
    }

    UFUNCTION(BlueprintEvent)
    void Lock(UObject Source)
    {
        if(LockingSources.Contains(Source))
            return;
        LockingSources.Add(Source);
    }

    UFUNCTION(BlueprintEvent)
    void Unlock(UObject Source)
    {
        LockingSources.Remove(Source);
    }

}