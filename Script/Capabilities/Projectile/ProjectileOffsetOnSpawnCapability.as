class UProjectileOffsetOnSpawnCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;

    FVector TotalOffsetDistance;
    float ElapsedTime;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return TotalOffsetDistance == MoveComponent.InitialOffset;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        TotalOffsetDistance = FVector::ZeroVector;
        ElapsedTime = 0.f;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        ProjectileOwner.CapabilityComponent.RemoveCapability(this.GetClass());
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        ElapsedTime += DeltaTime;

        FVector ForwardDir = MoveComponent.ProjectileVelocity.GetSafeNormal();
        FVector RightDir = ForwardDir.CrossProduct(FVector::UpVector).GetSafeNormal();
        FVector UpDir = RightDir.CrossProduct(ForwardDir).GetSafeNormal();

        float OffsetLerpAlpha = Math::Clamp(ElapsedTime / MoveComponent.OffsetLerpTime, 0.f, 1.f);

        FVector FrameOffsetDistance = Math::Lerp(FVector::ZeroVector, MoveComponent.InitialOffset, OffsetLerpAlpha) - TotalOffsetDistance;
        TotalOffsetDistance += FrameOffsetDistance;

        FVector NewOffset = 
            RightDir * FrameOffsetDistance.X 
            + ForwardDir * FrameOffsetDistance.Y 
            + UpDir * FrameOffsetDistance.Z;
        
        MoveComponent.AccumulatedFrameOffsets += NewOffset;
    }
};