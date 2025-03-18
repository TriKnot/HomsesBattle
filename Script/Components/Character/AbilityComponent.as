class UAbilityComponent : ULockableComponent
{    
    // Store assigned abilities by slot
    UPROPERTY()
    TArray<TSubclassOf<UAbilityCapability>> Abilities;    

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

    void InitStartingAbilities()
    {
        for (auto Ability : Abilities)
        {
            CapComp.AddCapability(Ability);
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

};
