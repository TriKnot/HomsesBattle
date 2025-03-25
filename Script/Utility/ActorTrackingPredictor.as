class UActorTrackingPredictor : UObject
{
    private float PositionRecordInterval;
    private int MaxPositionHistory;
    private float SmoothingFactor;  
    private AActor TargetActor = nullptr;

    private TArray<FTimedPosition> PositionHistory;
    private float TimeSinceLastRecord;
    private FVector SmoothedVelocity;
    private bool bHasInitialVelocity;
    float WeightDecayFactor = 0.5f;

    void Init(float InPositionRecordInterval = 0.1f, int InMaxPositionHistory = 10, float InWeightDecayFactor = 0.5f, float InSmoothingFactor = 0.5f)
    {
        PositionRecordInterval = InPositionRecordInterval;
        MaxPositionHistory = InMaxPositionHistory;
        SmoothingFactor = Math::Clamp(InSmoothingFactor, 0.f, 1.f); // Clamp smoothing factor between 0 and 1
        WeightDecayFactor = Math::Clamp(InWeightDecayFactor, 0.f, 1.f); // Clamp weight decay factor between 0 and 1
        PositionHistory.Reserve(MaxPositionHistory + 1); // Reserve space for the max history + 1 (+1 to avoid resizing before removing the last element)
    }

    void SetTarget(AActor InTargetActor)
    {
        TargetActor = InTargetActor;
    }

    // In Tick function:
    void Tick(float DeltaTime)
    {
        if (!IsValid(TargetActor)) // Reset if target is invalid
        {
            PositionHistory.Empty();
            SmoothedVelocity = FVector::ZeroVector;
            TimeSinceLastRecord = 0.f;
            return;
        }

        for(FTimedPosition& Pos : PositionHistory)
        {
            System::DrawDebugSphere(Pos.GetPosition(), 10);
        }

        float CurrentTime = TargetActor.GetWorld().GetTimeSeconds();
        TimeSinceLastRecord += DeltaTime;

        // Record position every interval
        if (TimeSinceLastRecord >= PositionRecordInterval || PositionHistory.Num() == 0)
        {
            RecordPosition(CurrentTime);
            UpdateSmoothedVelocity();
            TimeSinceLastRecord = 0.f;
        }
    }

    void RecordPosition(float CurrentTime)
    {
        FTimedPosition NewPosition = FTimedPosition(TargetActor.GetActorLocation(), CurrentTime);
        PositionHistory.Insert(NewPosition, 0);

        if (PositionHistory.Num() > MaxPositionHistory)
            PositionHistory.RemoveAt(MaxPositionHistory);
    }

    void UpdateSmoothedVelocity()
    {
        const int32 NumPositions = PositionHistory.Num();
        if (NumPositions < 2) // Cannot calculate velocity with less than 2 positions
        {
            SmoothedVelocity = FVector::ZeroVector;
            bHasInitialVelocity = false;
            return;
        }

        FVector WeightedVelocitySum = FVector::ZeroVector;
        float TotalWeight = 0.f;

        for(int i = 0; i < NumPositions - 1; i++)
        {
            const FTimedPosition& CurrentPosition = PositionHistory[i];
            const FTimedPosition& PreviousPosition = PositionHistory[i + 1];

            const float TimeDelta = CurrentPosition.GetTimestamp() - PreviousPosition.GetTimestamp();

            if(TimeDelta <= KINDA_SMALL_NUMBER) // Skip to avoid division by zero
                continue;

            const FVector SegmentDelta = CurrentPosition.GetPosition() - PreviousPosition.GetPosition();
            const FVector SegmentDeltaVelocity = SegmentDelta / TimeDelta;

            // Higher weight gives more influence to older data and the reverse for lower weight
            const float Weight = Math::Pow(WeightDecayFactor, i);

            WeightedVelocitySum += SegmentDeltaVelocity * Weight;
            TotalWeight += Weight;
        }

        if(TotalWeight <= KINDA_SMALL_NUMBER)
            return;

        FVector NewSmoothedVelocity = WeightedVelocitySum / TotalWeight;

        if (bHasInitialVelocity)
        {
            // Interpolate between current and new velocity to smooth out changes
            SmoothedVelocity = Math::Lerp(SmoothedVelocity, NewSmoothedVelocity, 1.0f - SmoothingFactor);
        }
        else
        {
            // If we don't have an initial velocity, just set it to the new velocity
            SmoothedVelocity = NewSmoothedVelocity;
            bHasInitialVelocity = true;
        }

    }

    // Predict using average velocity
    FVector GetPredictedLocation(float PredictionTime) const
    {
        return IsValid(TargetActor)
            ? TargetActor.GetActorLocation() + SmoothedVelocity * PredictionTime
            : FVector::ZeroVector;
    }

}

struct FTimedPosition
{
    private FVector Pos;
    private float Time;

    FTimedPosition(FVector InPosition, float InTimestamp)
    {
        Pos = InPosition;
        Time = InTimestamp;
    }

    const FVector& GetPosition() const property
    {
        return Pos;
    }

    const float GetTimestamp() const property
    {
        return Time;
    }
}