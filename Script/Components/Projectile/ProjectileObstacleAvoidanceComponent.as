class UProjectileObstacleAvoidanceComponent : UActorComponent
{
    float DetectionRadius;
    float DetectionDistance;
    float MaxAvoidanceAnglePerSecond; 
    ETraceTypeQuery TraceChannel;
};
