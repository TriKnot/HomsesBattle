UCLASS(Abstract)
class UAbilityCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    UPROPERTY(EditDefaultsOnly, Instanced, BlueprintReadWrite, Category="Ability|Conditions")
    TArray<UAbilityCondition> EnableConditions;

    UPROPERTY(EditDefaultsOnly, Instanced, BlueprintReadWrite, Category="Ability|Conditions")
    TArray<UAbilityCondition> DisableConditions;

    UPROPERTY(EditDefaultsOnly, Instanced, BlueprintReadWrite, Category="Ability|Conditions")
    TArray<UAbilityCondition> FireConditions;

    UPROPERTY(EditDefaultsOnly, Instanced, BlueprintReadWrite, Category="Ability|Modifiers")
    TArray<UAbilityModifier> Modifiers;

    AHomseCharacterBase HomseOwner;
    UAbilityComponent AbilityComp;

    EActiveAbilityState AbilityState;
    FTimer StateTimer;

    float WarmUpDuration = 0.0f;
    float ActiveDuration = 0.0f;
    float CooldownDuration = 0.0f;
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
            if(IsValid(Modifier))
                Modifier.TeardownModifier(this);
        }
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() 
    { 
        return AreConditionsMet(EnableConditions, false);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() 
    { 
        return AreConditionsMet(DisableConditions, true);
    }

    bool ShouldFire()
    {
        return AreConditionsMet(FireConditions, false);
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        bFired = false;

        ResetAllContexts();

        for (UAbilityModifier Modifier : Modifiers)
        {
            if(!IsValid(Modifier))
                continue;

            Modifier.OnAbilityActivate(this);
        }

        SwitchState(WarmUpDuration > 0.0f ? EActiveAbilityState::WarmUp : EActiveAbilityState::Active);

        if (AbilityState == EActiveAbilityState::Active)
            FireAbility();

    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        switch (AbilityState)
        {
            case EActiveAbilityState::WarmUp:
                HandleWarmUpState(DeltaTime);
                Print(f"Warming Up {GetName()}!", 0);
                break;
            case EActiveAbilityState::Active:
                HandleActiveState(DeltaTime);
                Print(f"Active! {GetName()}", 0);
                break;
            case EActiveAbilityState::Cooldown:
                HandleCooldownState(DeltaTime);
                Print(f"Cooldown! {GetName()}", 0);
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

    void HandleWarmUpState(float DeltaTime)
    {
        if(ShouldFire() && !bFired)
        {
            FireAbility();
            SwitchState(EActiveAbilityState::Active);
            return;
        }

        StateTimer.Tick(DeltaTime);

        for (UAbilityModifier Modifier : Modifiers)
        {
            if (IsValid(Modifier))
                Modifier.OnAbilityWarmUpTick(this, DeltaTime);
        }

    }

    void HandleActiveState(float DeltaTime)
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

    void HandleCooldownState(float DeltaTime)
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
            if(IsValid(Modifier))
                Modifier.OnAbilityDeactivate(this);
        }        
    }

    UFUNCTION(BlueprintEvent)
    void FireAbility()
    {
        for (UAbilityModifier Modifier : Modifiers)
        {
            if(IsValid(Modifier))
                Modifier.ModifyFire(this);
        }

        for (UAbilityModifier Modifier : Modifiers)
        {
            if(IsValid(Modifier))
                Modifier.OnAbilityFire(this);
        }

        bFired = true;
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

    void ResetAllContexts()
    {
        for (UAbilityContext Context : Contexts)
        {
            if (IsValid(Context))
                Context.Reset();
        }
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

    bool AreConditionsMet(const TArray<UAbilityCondition>&in Conditions, bool bDefaultValue = true) const
    {
        if(Conditions.IsEmpty())
            return bDefaultValue;

        bool bResultAND = true; 

        for (const UAbilityCondition Condition : Conditions)
        {
            if (!IsValid(Condition))
                continue;

            bool bConditionMet = Condition.IsConditionMet(this);
            bConditionMet = Condition.bInvertCondition ? !bConditionMet : bConditionMet;

            if (Condition.EvaluationType == EConditionEvaluationType::ECE_AND) 
                bResultAND = bConditionMet && bResultAND;
            else if(Condition.EvaluationType == EConditionEvaluationType::ECE_OR && bConditionMet) 
                return true;
        }

        return bResultAND;
    }

};

enum EActiveAbilityState
{
    WarmUp,
    Active,
    Cooldown
};