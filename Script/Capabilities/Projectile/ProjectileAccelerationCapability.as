class UProjectileAccelerationCapability : UCapability
{
    default Priority = ECapabilityPriority::Movement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;

    float ElapsedTime = 0.f;
    FVector AccelerationDirection;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated
            && IsValid(MoveComponent.AccelerationCurve);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        if (MoveComponent.TotalAccelerationDuration <= 0.f)
            return false; // Infinite duration

        return ElapsedTime >= MoveComponent.TotalAccelerationDuration;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        ElapsedTime += DeltaTime;

        float CurveTime = ElapsedTime;

        if(MoveComponent.bOscillateAcceleration && MoveComponent.AccelerationOscillationPeriod > 0.f)
        {
            CurveTime = 0.5f + 0.5f * Math::Sin((2.f * PI / MoveComponent.AccelerationOscillationPeriod) * ElapsedTime);
        }
        else if (MoveComponent.TotalAccelerationDuration > 0.f)
        {
            CurveTime = Math::Clamp(CurveTime / MoveComponent.TotalAccelerationDuration, 0.f, 1.f);
        }

        float CurveValue = MoveComponent.AccelerationCurve.GetFloatValue(CurveTime);

        if(!MoveComponent.ProjectileVelocity.GetSafeNormal().IsNearlyZero())
        {
            AccelerationDirection = MoveComponent.ProjectileVelocity.GetSafeNormal();
        }

        FVector AccelerationThisFrame = AccelerationDirection * CurveValue * MoveComponent.AccelerationScale;
        MoveComponent.ProjectileVelocity += AccelerationThisFrame * DeltaTime;
    }
};
