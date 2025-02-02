class UHealthComponent : ULockableComponent
{
    UPROPERTY()
    float MaxHealth = 100.0f;

    UPROPERTY()
    float CurrentHealth = 100.0f;

    UPROPERTY()
    bool bIsInvulnerable = false;

    TArray<FDamageInstanceData> DamageInstances;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CurrentHealth = MaxHealth;
    }
};