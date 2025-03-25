class UProjectileTrackingComponent : UActorComponent
{
    // Tracking
    float TargetSearchInterval; 
    TArray<FTrackingData> TrackingData;
    TArray<AActor> IgnoredActors;

    // Tracking Predictor
    float MaxPredictionAngle;

    // Tracking Predictor
    bool TrackPredictedTargetLocation;
    float PositionRecordInterval = 0.1f;
    int MaxPositionHistory = 10;
    float SmoothingFactor = 0.5f;
    float WeightDecayFactor = 0.5f;
}