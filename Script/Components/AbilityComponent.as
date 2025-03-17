class UAbilityComponent : ULockableComponent
{    
    // Store assigned abilities by slot
    UPROPERTY()
    TMap<FName, TSubclassOf<UAbilityCapability>> InputAbilityBindings;    

    // Store active abilities by capability class
    TArray<UAbilityCapability> ActiveAbilities;

    AHomseCharacterBase HomseOwner;
    UCapabilityComponent CapComp;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        HomseOwner = Cast<AHomseCharacterBase>(GetOwner());
        
        if (!IsValid(HomseOwner))

        {
            PrintError("UAbilityComponent: Owner is not AHomseCharacterBase");
            return;
        }

        CapComp = HomseOwner.CapabilityComponent;

        InitStartingAbilities();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        UpdateActiveAbilities();
    }

    void InitStartingAbilities()
    {
        for (auto Binding : InputAbilityBindings)
        {
            CapComp.AddCapability(Binding.Value);
        }
    }

    // void AddAbility(FName Slot, UAbilityData NewAbilityData)
    // {
    //     if (!IsValid(NewAbilityData))
    //         return;

    //     // Remove existing ability in this slot before adding the new one
    //     if (Abilities.Contains(Slot))
    //     {
    //         RemoveAbility(Slot);
    //     }

    //     // Assign new ability
    //     Abilities.Add(Slot, NewAbilityData);

    //     // Add the associated capability
    //     CapComp.AddCapability(NewAbilityData.AbilityCapabilityClass);
    // }

    // void RemoveAbility(FName Slot)
    // {
    //     if (!Abilities.Contains(Slot))
    //         return;

    //     TSubclassOf<UAbilityCapability> CapabilityClass = Abilities[Slot].AbilityCapabilityClass;

    //     // Remove ability from slot
    //     Abilities.Remove(Slot);

    //     // Remove the associated capability if no other active Ability uses it
    //     for (auto InputAbilityBinding : Abilities)
    //     {
    //         if (InputAbilityBinding.Value.AbilityCapabilityClass == CapabilityClass)
    //         {
    //             return;
    //         }
    //     }
    //     CapComp.RemoveCapability(Abilities[Slot].AbilityCapabilityClass);
    // }

    void UpdateActiveAbilities()
    {
        ActiveAbilities.Empty();

        for (auto InputAbilityBinding : InputAbilityBindings)
        {
            FName InputAction = InputAbilityBinding.Key;
            UAbilityCapability AbilityCapability = InputAbilityBinding.Value.GetDefaultObject();

            if (IsValid(AbilityCapability) && CapComp.GetActionStatus(InputAction))
            {
                // Store the ability data under its capability type
                ActiveAbilities.Add(AbilityCapability);
            }
        }
    }

    bool IsAbilityActive(UAbilityCapability Capability)
    {
        for (auto ActiveAbility : ActiveAbilities)
        {
            if (Capability.IsA(ActiveAbility.GetClass()))
            {
                return true;
            }
        }

        return false;
    }

};
