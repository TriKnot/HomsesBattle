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
        Projectile.CapabilityComponent.AddCapability(UProjectileMovementCapability::StaticClass());
        UProjectileMoveComponent::GetOrCreate(Projectile).ProjectileVelocity = InVelocity;
        return this;
    }

    UProjectileBuilder WithStartingLocation(const FVector& InLocation)
    {
        Projectile.SetActorLocation(InLocation);
        return this;
    }

    AProjectileActor Build()
    {
        return Projectile;
    }

}