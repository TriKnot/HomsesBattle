class UProjectileMoveComponent : UActorComponent
{
    // Base velocity of the projectile
    FVector ProjectileVelocity;

    // Gravity data
    UProjectileGravityData GravityData;

    // Acceleration over time data
    UCurveFloat AccelerationCurve;
    float TotalAccelerationDuration;      
    float AccelerationScale;  
    bool bOscillateAcceleration;
    float AccelerationOscillationPeriod;  

    // Oschillation data
    UCurveFloat HorizontalOscillationCurve;
    float HorizontalOscillationPeriod;
    float HorizontalOscillationScale; 

    // Vertical oscillation
    UCurveFloat VerticalOscillationCurve;
    float VerticalOscillationPeriod;
    float VerticalOscillationScale; 

    // Drag data
    float DragCoefficient;
    float FluidDensity;

    // Initial offset data
    FVector InitialOffset;
    float OffsetLerpTime;
}