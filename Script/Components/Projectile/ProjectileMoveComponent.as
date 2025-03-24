class UProjectileMoveComponent : UActorComponent
{
    // Base velocity of the projectile
    FVector ProjectileVelocity;
    FVector AccumulatedFrameOffsets;

    // Gravity data
    UProjectileGravityData GravityData;

    // Acceleration over time data
    UCurveFloat AccelerationCurve;
    float TotalAccelerationDuration;      
    float AccelerationScale;  
    bool bOscillateAcceleration;
    float AccelerationOscillationPeriod;  

    // Oscillation data
    TArray<FOscillationData> OscillationDatas;

    // Drag data
    float DragCoefficient;
    float FluidDensity;

    // Initial offset data
    FVector InitialOffset;
    float OffsetLerpTime;
}