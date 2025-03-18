class ULockComponentModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Lock")
    TArray<TSubclassOf<ULockableComponent>> LockableComponentClasses;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Lock")
    bool bLockOnWarmUp;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Lock")
    bool bLockDuringActive;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Lock")
    bool bLockOnCooldown;

    TArray<ULockableComponent> LockedComponents;
    bool bLocked = false;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability) override
    {
        if (!IsValid(Ability) || !IsValid(Ability.Owner))
            return;
        
        LockedComponents.Empty();

        for (TSubclassOf<ULockableComponent> CompClass : LockableComponentClasses)
        {
            if (!IsValid(CompClass))
                continue;
            
            ULockableComponent Comp = Cast<ULockableComponent>(Ability.Owner.GetComponentByClass(CompClass));
            if (!IsValid(Comp))
                continue;
            
            LockedComponents.Add(Comp);
        }

        bLocked = false;
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityWarmUpTick(UAbilityCapability Ability, float DeltaTime) override
    {
        if (!bLockOnWarmUp && bLocked)
            UpdateLockState(Ability, false);

        if (bLockOnWarmUp && !bLocked)
            UpdateLockState(Ability, true);

    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityActiveTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!bLockDuringActive && bLocked)
            UpdateLockState(Ability, false);

        if(bLockDuringActive && !bLocked)
            UpdateLockState(Ability, true);
    }


    UFUNCTION(BlueprintOverride)
    void OnAbilityCooldownTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!bLockOnCooldown && bLocked)
            UpdateLockState(Ability, false);

        if(bLockOnCooldown && !bLocked)
            UpdateLockState(Ability, true);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityDeactivate(UAbilityCapability Ability) override
    {
        UpdateLockState(Ability, false);
    }

    void UpdateLockState(UAbilityCapability Ability, bool bShouldLock)
    {
        if (!IsValid(Ability))
            return;
        
        for (ULockableComponent Comp : LockedComponents)
        {
            if (!IsValid(Comp))
                continue;
            
            if (bShouldLock)
            {
                Comp.Lock(Ability);
                bLocked = true;
            }
            else
            {
                Comp.Unlock(Ability);
                bLocked = false;
            }
        }
    }
}