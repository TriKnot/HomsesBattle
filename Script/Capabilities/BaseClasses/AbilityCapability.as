class UAbilityCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    // Components
    AHomseCharacterBase HomseOwner;
    UAbilityComponent AbilityComp;

    FCooldownTimer CooldownTimer;

    TArray<UAbilityModifier> Modifiers;

    private bool bFired = false;
    access TriggerProtection = protected, UAbilityTriggerModeModifier;
    access:TriggerProtection bool bShouldFire;

    TArray<UAbilityContext> Contexts;
    UAbilityTriggerModeModifier TriggerModeModifier;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        if (!IsValid(HomseOwner))
            return;

        AbilityComp = HomseOwner.AbilityComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return !AbilityComp.IsLocked() && AbilityComp.IsAbilityActive(this);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() 
    { 
        return AbilityComp.IsLocked(this) || CooldownTimer.IsFinished();
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        bFired = false;
        bShouldFire = false;

        UTestAbilityData TestAbility = Cast<UTestAbilityData>(AbilityComp.GetAbilityData(this));

        if(IsValid(TestAbility))
        {
            Modifiers = TestAbility.Modifiers;
            TriggerModeModifier = TestAbility.TriggerModeModifier;
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

        CooldownTimer.SetDuration(TestAbility.CooldownTime);
        CooldownTimer.Reset();

        TriggerModeModifier.OnAbilityStart(this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!AbilityComp.IsAbilityActive(this))
        {
            TriggerModeModifier.OnAbilityReleased(this);
        }

        CooldownTimer.Tick(DeltaTime);
        if(CooldownTimer.IsActive() || CooldownTimer.IsFinished())
            return;

        for (UAbilityModifier Modifier : Modifiers)
        {
            if(!IsValid(Modifier))
                continue;

            Modifier.OnAbilityTick(this, DeltaTime);
        }

        if(!bShouldFire || bFired)
            return;

        for (UAbilityModifier Modifier : Modifiers)
        {
            if(!IsValid(Modifier))
                continue;
            
            Modifier.ModifyFire(this);
        }

        FireAbility();
        CooldownTimer.Start();
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

};