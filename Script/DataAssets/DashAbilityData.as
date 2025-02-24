class UDashAbilityData : UAbilityData
{
    UPROPERTY()
    float Duration = 0.2f;

    UPROPERTY()
    float DashStrength = 2500.0f;

    UPROPERTY()
    UCurveFloat DashCurve;

    UPROPERTY()
    FVector2D CameraOffsetMultiplier;
}