class USpawnProjectileAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    int NumProjectiles = 1;

    UPROPERTY(EditAnywhere)
    UProjectileData ProjectileData;

    UPROPERTY(EditAnywhere)
    FName SpawnSocketName;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        UProjectileAbilityContext AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));
        AbilityContext.ProjectileData = ProjectileData;
    }

    UFUNCTION(BlueprintOverride)
    void ModifyFire(UAbilityCapability Ability)
    {
        if(!IsValid(Ability))
            return;

        UProjectileAbilityContext AbilityContext = Cast<UProjectileAbilityContext>(Ability.GetOrCreateAbilityContext(UProjectileAbilityContext::StaticClass()));

        for (int i = 0; i < NumProjectiles; i++)
        {
            FVector SocketLocation = Ability.HomseOwner.Mesh.GetSocketLocation(SpawnSocketName);
            AProjectileActor Projectile = UProjectileBuilder()
            .WithProjectileData(ProjectileData)
            .WithSourceActor(Ability.Owner)
            .WithStartingLocation(SocketLocation)
            .WithInitialVelocity(AbilityContext.InitialVelocity)
            .Build();

            AbilityContext.Projectiles.Add(Projectile);
        }
    }
}