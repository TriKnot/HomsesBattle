class UHitDamageModifier : UAbilityModifier
{
    UPROPERTY(Category="HitDamage")
    FDamageData DamageData;

    TArray<UHealthComponent> HitHealthComps;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        HitHealthComps.Empty();        
        DamageData.SetSourceActor(Ability.Owner);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityTick(UAbilityCapability Ability, float DeltaTime)
    {
        ProcessHits(Ability);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityDeactivate(UAbilityCapability Ability)
    {
        ProcessHits(Ability);
    }

    void ProcessHits(UAbilityCapability Ability)
    {
        if (!IsValid(Ability))
            return;

        UHitContext HitContext = Cast<UHitContext>(Ability.GetOrCreateAbilityContext(UHitContext::StaticClass()));
        if (!IsValid(HitContext))
            return;

        for (FHitResult HitResult : HitContext.HitResults)
        {
            if(HitResult.Actor == Ability.Owner)
                continue;
            
            UHealthComponent HitHealthComp = UHealthComponent::Get(HitResult.Actor);
            if (!IsValid(HitHealthComp)
                || HitHealthComps.Contains(HitHealthComp))
                continue;

            DamageData.SetDamageLocation(HitResult.Location);
            HitHealthComp.AddDamageInstanceData(DamageData);
            HitHealthComps.Add(HitHealthComp);
        }
    }

}