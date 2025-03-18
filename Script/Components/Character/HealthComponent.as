class UHealthComponent : ULockableComponent
{
    UPROPERTY()
    float MaxHealth = 100.0f;

    UPROPERTY()
    float CurrentHealth = 100.0f;

    UPROPERTY()
    bool bIsInvulnerable = false;

    private TArray<FDamageData> DamageInstancesArray;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CurrentHealth = MaxHealth;
    }

    TArray<FDamageData> GetDamageInstances() const property
    {
        return DamageInstancesArray;
    }

    void AddDamageInstanceData(FDamageData DamageInstance)
    {
        if(bIsInvulnerable || CurrentHealth <= 0.0f)
            return;
        DamageInstancesArray.Add(DamageInstance);
    }

    void RemoveDamageInstance(const FDamageData& DamageInstance)
    {
        DamageInstancesArray.Remove(DamageInstance);
    }

};