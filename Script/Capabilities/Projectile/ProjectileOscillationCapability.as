class UProjectileOscillationCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;

    float ElapsedTime;
    FVector OscillationOffsetLastFrame = FVector::ZeroVector;
    
    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated && 
            (IsValid(MoveComponent.HorizontalOscillationCurve) ||
             IsValid(MoveComponent.VerticalOscillationCurve));
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        ElapsedTime += DeltaTime;

        FVector ForwardDir = MoveComponent.ProjectileVelocity.GetSafeNormal();
        FVector RightDir = ForwardDir.CrossProduct(FVector::UpVector).GetSafeNormal();
        FVector UpDir = RightDir.CrossProduct(ForwardDir).GetSafeNormal();

        FVector OscillationOffset = 
            CalculateHorizontalOffset(RightDir) + 
            CalculateVerticalOffset(UpDir);

        FVector CorrectedLocation = ProjectileOwner.GetActorLocation() - OscillationOffsetLastFrame + OscillationOffset;

        ProjectileOwner.SetActorLocation(CorrectedLocation);

        OscillationOffsetLastFrame = OscillationOffset;
    }

    FVector CalculateHorizontalOffset(const FVector& RightDir) const
    {
        if (!IsValid(MoveComponent.HorizontalOscillationCurve) 
            || MoveComponent.HorizontalOscillationPeriod <= 0.f)
            return FVector::ZeroVector;

        float HorizontalValue = GetOscillationValue(
            ElapsedTime, 
            MoveComponent.HorizontalOscillationPeriod,
            MoveComponent.HorizontalOscillationCurve
        );

        return RightDir * HorizontalValue * MoveComponent.HorizontalOscillationScale;
    }

    FVector CalculateVerticalOffset(const FVector& UpDir) const
    {
        if (!IsValid(MoveComponent.VerticalOscillationCurve) 
            || MoveComponent.VerticalOscillationPeriod <= 0.f)
            return FVector::ZeroVector;

        float VerticalValue = GetOscillationValue(
            ElapsedTime, 
            MoveComponent.VerticalOscillationPeriod,
            MoveComponent.VerticalOscillationCurve
        );

        return UpDir * VerticalValue * MoveComponent.VerticalOscillationScale;
    }

    float GetOscillationValue(float CurrentTime, float Period, const UCurveFloat Curve) const
    {
        float TimeInCycle = Math::Fmod(CurrentTime, Period);
        
        float NormalizedTime = (TimeInCycle <= Period)
            ? (TimeInCycle / Period)                           
            : (1.f - ((TimeInCycle - Period) / Period));       

        return Curve.GetFloatValue(NormalizedTime);
    }
}