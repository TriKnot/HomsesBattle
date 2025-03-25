class UProjectileTrackingData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Tracking")
    float TargetSearchInterval = 0.1f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Tracking", meta=(ClampMin="0.0", ClampMax="180.0"))
    float MaxPredictionAngle = 90.f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Tracking")
    TArray<FTrackingData> TrackingData;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Tracking|TrackingPredictor")
    bool TrackPredictedTargetLocation = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Tracking|TrackingPredictor", meta=(EditCondition="TrackPredictedTargetLocation", ClampMin="0.0"))
    float PositionRecordInterval = 0.1f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Tracking|TrackingPredictor", meta=(EditCondition="TrackPredictedTargetLocation", ClampMin="1"))
    int MaxPositionHistory = 10;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Tracking|TrackingPredictor", meta=(EditCondition="TrackPredictedTargetLocation", ClampMin="0.0", ClampMax="1.0"))
    float SmoothingFactor = 0.5f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Tracking|TrackingPredictor", meta=(EditCondition="TrackPredictedTargetLocation", ClampMin="0.0", ClampMax="1.0"))
    float WeightDecayFactor = 0.5f;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileTrackingCapability::StaticClass());

        UProjectileTrackingComponent TrackingComponent = UProjectileTrackingComponent::GetOrCreate(Projectile);

        TrackingComponent.TargetSearchInterval = TargetSearchInterval;
        TrackingComponent.TrackingData = TrackingData;
        TrackingComponent.TrackPredictedTargetLocation = TrackPredictedTargetLocation;
        TrackingComponent.IgnoredActors.Add(Projectile.SourceActor);
        TrackingComponent.MaxPredictionAngle = MaxPredictionAngle;

        if(TrackPredictedTargetLocation)
        {
            TrackingComponent.PositionRecordInterval = PositionRecordInterval;
            TrackingComponent.MaxPositionHistory = MaxPositionHistory;
            TrackingComponent.SmoothingFactor = SmoothingFactor;
            TrackingComponent.WeightDecayFactor = WeightDecayFactor;
        }
    }
}

struct FTrackingData
{
    UPROPERTY(EditAnywhere)
    float MaxActivationDistance = 1000.f;

    UPROPERTY(EditAnywhere)
    float TurnRateDegrees = 10.f; 
};

