class UProjectileObstacleAvoidanceData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, Category = "Avoidance")
    float DetectionRadius = 500.0f;

    UPROPERTY(EditAnywhere, Category = "Avoidance")
    float DetectionDistance = 1000.0f;

    UPROPERTY(EditAnywhere, Category = "Avoidance", Meta = (ClampMin = 0.0f))
    float MaxAvoidanceAnglePerSecond = 45.0f;

    UPROPERTY(EditAnywhere, Category = "Avoidance")
    ETraceTypeQuery TraceChannel = ETraceTypeQuery::Visibility;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileObstacleAvoidanceCapability::StaticClass());

        UProjectileObstacleAvoidanceComponent AvoidanceComp = UProjectileObstacleAvoidanceComponent::GetOrCreate(Projectile);
        AvoidanceComp.DetectionRadius = DetectionRadius;
        AvoidanceComp.DetectionDistance = DetectionDistance;
        AvoidanceComp.MaxAvoidanceAnglePerSecond = MaxAvoidanceAnglePerSecond;
        AvoidanceComp.TraceChannel = TraceChannel;
    }
}