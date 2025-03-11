class ULockComponentModifier : UAbilityModifier
{
    UPROPERTY()
    TArray<TSubclassOf<ULockableComponent>> LockableComponentClasses;
    TArray<ULockableComponent> LockedComponents;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        if(!IsValid(Ability.Owner))
            return;
        
        for(TSubclassOf<ULockableComponent> LockableComponentClass : LockableComponentClasses)
        {
            if(!IsValid(LockableComponentClass))
                continue;
            
            ULockableComponent LockableComponent = Ability.Owner.GetComponentByClass(LockableComponentClass);
            if(!IsValid(LockableComponent))
                continue;
            
            LockedComponents.Add(LockableComponent);
            LockableComponent.Lock(Ability);
        }

    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityDeactivate(UAbilityCapability Ability)
    {
        for(ULockableComponent LockedComponent : LockedComponents)
        {
            if(!IsValid(LockedComponent))
                continue;
            
            LockedComponent.Unlock(Ability);
        }
        LockedComponents.Empty();
    }
}