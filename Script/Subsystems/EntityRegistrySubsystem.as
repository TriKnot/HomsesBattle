class UEntityRegistrySubsystem : UScriptWorldSubsystem
{
    private TArray<AHomseCharacterBase> AllHomses;
    private TArray<ASHomsePlayerCharacter> PlayerHomses;
    private TArray<ASHomseEnemyBase> AIHomses;

    UFUNCTION(BlueprintOverride)
    void Deinitialize()
    {
        ClearAllHomses();
    }

    void RegisterHomse(AHomseCharacterBase Character)
    {
        if(!IsValid(Character) || AllHomses.Contains(Character))
            return;

        AllHomses.Add(Character);

        ASHomsePlayerCharacter PlayerCharacter = Cast<ASHomsePlayerCharacter>(Character);

        if(IsValid(PlayerCharacter))    
        {
            PlayerHomses.Add(PlayerCharacter);
            return;
        }

        ASHomseEnemyBase AICharacter = Cast<ASHomseEnemyBase>(Character);
        
        if(IsValid(AICharacter))
        {
            AIHomses.Add(AICharacter);
        }

    }

    void UnregisterHomse(AHomseCharacterBase Character)
    {
        if(!IsValid(Character))
            return;

        AllHomses.Remove(Character);

        ASHomsePlayerCharacter PlayerCharacter = Cast<ASHomsePlayerCharacter>(Character);

        if(IsValid(PlayerCharacter))    
        {
            PlayerHomses.Remove(PlayerCharacter);
            return;
        }

        ASHomseEnemyBase AICharacter = Cast<ASHomseEnemyBase>(Character);
        
        if(IsValid(AICharacter))
        {
            AIHomses.Remove(AICharacter);
        }
    }

    const TArray<AHomseCharacterBase>& GetAllHomses() const
    {
        return AllHomses;
    }

    const TArray<ASHomsePlayerCharacter>& GetAllPlayers() const
    {
        return PlayerHomses;
    }

    const TArray<ASHomseEnemyBase>& GetAllEnemies() const
    {
        return AIHomses;
    }

    AHomseCharacterBase GetClosestHomseTo(FVector Location, float MaxRange = MAX_flt, TArray<AActor> IgnoredActors = nullptr) const
    {
        AHomseCharacterBase ClosestHomse = nullptr;
        float ClosestDistanceSq = MaxRange * MaxRange;

        for(AHomseCharacterBase Homse : AllHomses)
        {
            if(!IsValid(Homse) || IgnoredActors.Contains(Homse))
                continue;

            float DistanceSq = Homse.GetActorLocation().DistSquared(Location);

            if(DistanceSq < ClosestDistanceSq)
            {
                ClosestDistanceSq = DistanceSq;
                ClosestHomse = Homse;
            }
        }

        return ClosestHomse;
    }

    AHomseCharacterBase GetClosestHomseTo(AActor Actor, float MaxRange = MAX_flt, TArray<AActor> IgnoredActors = nullptr) const
    {
        FVector Location = Actor.GetActorLocation();
        return GetClosestHomseTo(Location, MaxRange, IgnoredActors);
    }

    void GetHomsesInRange(FVector Location, float MaxRange, TArray<AHomseCharacterBase>& OutHomses) const
    {
        float MaxRangeSq = MaxRange * MaxRange;
        for(AHomseCharacterBase Homse : AllHomses)
        {
            if(!IsValid(Homse))
                continue;

            float DistanceSq = Homse.GetActorLocation().DistSquared(Location);

            if(DistanceSq < MaxRangeSq)
            {
                OutHomses.Add(Homse);
            }
        }
    }

    void ClearAllHomses()
    {
        AllHomses.Empty();
        PlayerHomses.Empty();
        AIHomses.Empty();
    }
}