class UProjectileMoveComponent : UActorComponent
{
    // Base velocity of the projectile
    FVector ProjectileVelocity;

    // Gravity data
    UProjectileGravityData GravityData;

    // Acceleration over time data
    UCurveFloat AccelerationCurve = nullptr;
    float TotalAccelerationDuration = 0.f;      
    float AccelerationScale = 1.f;  
    bool bOscillateAcceleration = false;
    float AccelerationOscillationPeriod = 1.f;  

    // Drag data
    float DragCoefficient;
    float FluidDensity;
};