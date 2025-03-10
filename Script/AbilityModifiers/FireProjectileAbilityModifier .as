class UFireProjectileAbilityModifier  : UAbilityModifier
{
    UFUNCTION(BlueprintOverride)
    void OnAbilityFire(UAbilityCapability Ability) 
    {
        if (!IsValid(Ability))
            return;

        // Query for the specialized projectile context.
        UProjectileAbilityContext ProjectileContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));

        for (AProjectileActor Projectile : ProjectileContext.Projectiles)
        {
            if (!IsValid(Projectile))
                continue;

            Projectile.Fire();
        }

        ProjectileContext.Projectiles.Empty();
    }
}