class UMeleeAttackData : UAbilityData
{
    // Damage settings
    UPROPERTY()
    FDamageData DamageData;

    UPROPERTY()
    float HitboxRadius = 50.0f;

    // Dash settings
    UPROPERTY()
    float DashStrength = 1500.0f;

    UPROPERTY()
    float ActiveDuration = 0.1f;

    UPROPERTY()
    FName Socket = n"AttackSocket";
};
