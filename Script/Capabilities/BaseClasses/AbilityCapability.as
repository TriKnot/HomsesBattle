class UAbilityCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    UPROPERTY(EditDefaultsOnly, Instanced, BlueprintReadWrite, Category="Ability")
    UAbilityTriggerModeModifier TriggerModeModifier;
    UPROPERTY(EditDefaultsOnly, Instanced, BlueprintReadWrite, Category="Ability")
    TArray<UAbilityModifier> Modifiers;

    float WarmUpDuration = 0.0f;
    float ActiveDuration = 0.0f;
    float CooldownDuration = 0.0f;

    FTimer StateTimer;
    AHomseCharacterBase HomseOwner;
    UAbilityComponent AbilityComp;
    EActiveAbilityState AbilityState;

    access TriggerProtection = protected, UAbilityTriggerModeModifier;
    access:TriggerProtection bool bShouldFire;
    private bool bFired = false;

    private TArray<UAbilityContext> Contexts;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        if (!IsValid(HomseOwner))
            return;

        AbilityComp = HomseOwner.AbilityComponent;

        for (UAbilityModifier Modifier : Modifiers)
        {
            if(!IsValid(Modifier))
                continue;
            
            Modifier.SetupModifier(this);
        }
    }

    UFUNCTION(BlueprintOverride)
    void Teardown()
    {
        for (UAbilityModifier Modifier : Modifiers)
        {
            if(!IsValid(Modifier))
                continue;

            Modifier.TeardownModifier(this);
        }
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return !AbilityComp.IsLocked() && AbilityComp.IsAbilityActive(this);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() 
    { 
        return AbilityComp.IsLocked(this) || (bFired && StateTimer.IsFinished());
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        bFired = false;
        bShouldFire = false;

        if(WarmUpDuration > 0.0f)
        {
            SwitchState(EActiveAbilityState::WarmUp);
        }else
        {
            SwitchState(EActiveAbilityState::Active);
            FireAbility();
        }

        for (UAbilityContext Context : Contexts)
        {
            if(!IsValid(Context))
                continue;

            Context.Reset();
        }

        for (UAbilityModifier Modifier : Modifiers)
        {
            if(!IsValid(Modifier))
                continue;

            Modifier.OnAbilityActivate(this);
        }

        if (IsValid(TriggerModeModifier))
        {
            TriggerModeModifier.OnAbilityStart(this);
        }

    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        switch (AbilityState)
        {
            case EActiveAbilityState::WarmUp:
                TickWarmUp(DeltaTime);
                Print("Warming Up!", 0);
                break;
            case EActiveAbilityState::Active:
                TickActivePhase(DeltaTime);
                Print("Active!", 0);
                break;
            case EActiveAbilityState::Cooldown:
                TickCooldown(DeltaTime);
                Print("Cooldown!", 0);
                break;
            default:
                break;
        }

        for (UAbilityModifier Modifier : Modifiers)
        {
            if (IsValid(Modifier))
                Modifier.OnAbilityTick(this, DeltaTime);
        }
    }

    void TickWarmUp(float DeltaTime)
    {
        if(!AbilityComp.IsAbilityActive(this))
        {
            TriggerModeModifier.OnAbilityReleased(this);
        }

        if(bShouldFire && !bFired)
        {
            FireAbility();
            SwitchState(EActiveAbilityState::Active);
            return;
        }

        if (!TriggerModeModifier.IsA(UOnAbilityReleasedTriggerModeAbilityModifier) && StateTimer.IsFinished())
            return;

        StateTimer.Tick(DeltaTime);

        for (UAbilityModifier Modifier : Modifiers)
        {
            if (IsValid(Modifier))
                Modifier.OnAbilityWarmUpTick(this, DeltaTime);
        }

    }

    void TickActivePhase(float DeltaTime)
    {
        StateTimer.Tick(DeltaTime);

        for (UAbilityModifier Modifier : Modifiers)
        {
            if (IsValid(Modifier))
                Modifier.OnAbilityActiveTick(this, DeltaTime);
        }

        if (StateTimer.IsFinished())
        {
            SwitchState(EActiveAbilityState::Cooldown);
        }
    }

    void TickCooldown(float DeltaTime)
    {
        StateTimer.Tick(DeltaTime);

        for (UAbilityModifier Modifier : Modifiers)
        {
            if (IsValid(Modifier))
                Modifier.OnAbilityCooldownTick(this, DeltaTime);
        }
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        for (UAbilityModifier Modifier : Modifiers)
        {
            if(!IsValid(Modifier))
                continue;

            Modifier.OnAbilityDeactivate(this);
        }        
    }

    UFUNCTION(BlueprintEvent)
    void FireAbility()
    {
        for (UAbilityModifier Modifier : Modifiers)
        {
            if(!IsValid(Modifier))
                continue;

            Modifier.ModifyFire(this);
        }

        for (UAbilityModifier Modifier : Modifiers)
        {
            if(!IsValid(Modifier))
                continue;

            Modifier.OnAbilityFire(this);
        }

        bFired = true;
    }

    UAbilityContext& GetOrCreateAbilityContext(TSubclassOf<UAbilityContext> ContextClass)
    {
        UAbilityContext OutContext;
        if(TryGetContext(ContextClass, OutContext))
            return OutContext;
        OutContext = NewObject(this, ContextClass);
        Contexts.Add(OutContext);
        return OutContext;
    }
    
    private bool TryGetContext(TSubclassOf<UAbilityContext> ContextClass, UAbilityContext&out OutContext)
    {
        for (UAbilityContext Context : Contexts)
        {
            if(Context.Class == ContextClass)
            {
                OutContext = Context;
                return true;
            }
        }

        OutContext = nullptr;
        return false;
    }

    private void SwitchState(EActiveAbilityState NewState)
    {
        switch (NewState)
        {
            case EActiveAbilityState::WarmUp:
                StateTimer.SetDuration(WarmUpDuration);
                break;
            case EActiveAbilityState::Active:
                StateTimer.SetDuration(ActiveDuration);
                break;
            case EActiveAbilityState::Cooldown:
                StateTimer.SetDuration(CooldownDuration);
                break;
            default:
                break;
        }

        AbilityState = NewState;
        StateTimer.Reset();
        StateTimer.Start();
    }

};

enum EActiveAbilityState
{
    WarmUp,
    Active,
    Cooldown
};