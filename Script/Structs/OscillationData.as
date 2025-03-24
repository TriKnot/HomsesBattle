struct FOscillationData
{
    UPROPERTY(EditAnywhere)
    UCurveFloat OscillationCurve;

    UPROPERTY(EditAnywhere)
    float Period = 1.f;

    UPROPERTY(EditAnywhere)
    float Scale = 50.f;

    UPROPERTY(EditAnywhere)
    FVector Direction = FVector::UpVector;

    float ElapsedTime = 0.f;
    float LastFrameValue = 0.f;
};
