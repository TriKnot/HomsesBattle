class UProjectileOscillationCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;
    UProjectileCollisionComponent CollisionComponent;
    
    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
        CollisionComponent = UProjectileCollisionComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated 
            && !MoveComponent.OscillationDatas.IsEmpty();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(CollisionComponent.MovementHitResult.bBlockingHit)
            ResetOscillationsToZero();

        FVector TotalOscillationOffset = FVector::ZeroVector;

        FVector ForwardDir = MoveComponent.ProjectileVelocity.GetSafeNormal();
        FVector RightDir = ForwardDir.CrossProduct(FVector::UpVector).GetSafeNormal();
        FVector UpDir = RightDir.CrossProduct(ForwardDir).GetSafeNormal();

        for (FOscillationData& Oscillation : MoveComponent.OscillationDatas)
        {
            Oscillation.ElapsedTime += DeltaTime;

            float NormalizedTime = Math::Fmod(Oscillation.ElapsedTime, Oscillation.Period) / Oscillation.Period;
            float CurrentValue = Oscillation.OscillationCurve.GetFloatValue(NormalizedTime);

            float DeltaValue = CurrentValue - Oscillation.LastFrameValue;

            FVector LocalDirection = 
                RightDir * Oscillation.Direction.X +
                ForwardDir * Oscillation.Direction.Y +
                UpDir * Oscillation.Direction.Z;

            TotalOscillationOffset += LocalDirection.GetSafeNormal() * DeltaValue * Oscillation.Scale;

            Oscillation.LastFrameValue = CurrentValue;
        }

        MoveComponent.AccumulatedFrameOffsets += TotalOscillationOffset;
    }

    void ResetOscillationsToZero()
    {
        for (FOscillationData& Oscillation : MoveComponent.OscillationDatas)
        {
            Oscillation.ElapsedTime = 0.f;
            Oscillation.LastFrameValue = Oscillation.OscillationCurve.GetFloatValue(0.f);
        }
    }

}