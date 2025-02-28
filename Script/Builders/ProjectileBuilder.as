class UProjectileBuilder
{
    AProjectileActor Projectile;

    UProjectileBuilder()
    {
        Projectile = AProjectileActor::Spawn();
    }

    UProjectileBuilder WithProjectileData(UProjectileData DataContainer)
    {
        if (IsValid(DataContainer))
        {
            for (UProjectileDataComponent Component : DataContainer.Components)
            {
                if (IsValid(Component))
                {
                    Component.ApplyData(Projectile);
                }
            }
        }
        return this;
    }

    UProjectileBuilder WithSourceActor(AActor InSource)
    {
        Projectile.SetSourceActor(InSource);
        return this;
    }

    UProjectileBuilder WithInitialVelocity(const FVector& InVelocity)
    {
        Projectile.SetInitialVelocity(InVelocity);
        return this;
    }

    UProjectileBuilder WithStartingLocation(const FVector& InLocation)
    {
        Projectile.SetActorLocation(InLocation);
        return this;
    }

    UProjectileBuilder WithIgnoredActors(const TArray<AActor>& InIgnoredActors)
    {
        Projectile.SetIgnoredActors(InIgnoredActors);
        return this;
    }

    AProjectileActor Build()
    {
        return Projectile;
    }

}