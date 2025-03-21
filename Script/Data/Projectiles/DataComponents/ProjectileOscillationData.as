class UProjectileOscillationData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, Category = "Horizontal Oscillation")
    UCurveFloat HorizontalOscillationCurve;

    UPROPERTY(EditAnywhere, Category = "Horizontal Oscillation")
    float HorizontalOscillationPeriod = 1.f;

    UPROPERTY(EditAnywhere, Category = "Horizontal Oscillation")
    float HorizontalOscillationScale = 50.f;

    UPROPERTY(EditAnywhere, Category = "Vertical Oscillation")
    UCurveFloat VerticalOscillationCurve;

    UPROPERTY(EditAnywhere, Category = "Vertical Oscillation")
    float VerticalOscillationPeriod = 1.f;

    UPROPERTY(EditAnywhere, Category = "Vertical Oscillation")
    float VerticalOscillationScale = 50.f;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileOscillationCapability::StaticClass());

        UProjectileMoveComponent OscComp = UProjectileMoveComponent::GetOrCreate(Projectile);

        OscComp.HorizontalOscillationCurve = HorizontalOscillationCurve;
        OscComp.HorizontalOscillationPeriod = HorizontalOscillationPeriod;
        OscComp.HorizontalOscillationScale = HorizontalOscillationScale;

        OscComp.VerticalOscillationCurve = VerticalOscillationCurve;
        OscComp.VerticalOscillationPeriod = VerticalOscillationPeriod;
        OscComp.VerticalOscillationScale = VerticalOscillationScale;
    }
};
