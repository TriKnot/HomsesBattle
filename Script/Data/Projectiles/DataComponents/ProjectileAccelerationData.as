class UProjectileAccelerationData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, Category = "Acceleration")
    UCurveFloat AccelerationCurve;

    // Total duration of the acceleration effect, 0 means infinite duration
    UPROPERTY(EditAnywhere, Category = "Acceleration")
    float TotalDuration = 0.f; 

    UPROPERTY(EditAnywhere, Category = "Acceleration")
    float AccelerationScale = 1000.f; 

    UPROPERTY(EditAnywhere, Category = "Oscillation")
    bool bOscillate = false;

    UPROPERTY(EditAnywhere, Category = "Oscillation", meta=(EditCondition="bOscillate", ClampMin=0.01))
    float OscillationPeriod = 1.f; 

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileAccelerationCapability::StaticClass());

        UProjectileMoveComponent MoveComponent = UProjectileMoveComponent::GetOrCreate(Projectile);

        MoveComponent.AccelerationCurve = AccelerationCurve;
        MoveComponent.TotalAccelerationDuration = TotalDuration;
        MoveComponent.AccelerationScale = AccelerationScale;
        MoveComponent.bOscillateAcceleration = bOscillate;
        MoveComponent.AccelerationOscillationPeriod = OscillationPeriod;
    }
};
