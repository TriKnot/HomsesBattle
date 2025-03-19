class UProjectileMoveComponent : UActorComponent
{
    FVector ProjectileVelocity;
    UProjectileGravityData GravityData;
    int MaxBounces;
    float BounceEnergyLoss;
};