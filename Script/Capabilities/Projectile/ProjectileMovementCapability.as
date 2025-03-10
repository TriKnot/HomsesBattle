class UProjectileMovementCapability : UCapability
{
    default Priority = ECapabilityPriority::Movement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;
    UProjectileDamageComponent DamageComponent;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
        DamageComponent = UProjectileDamageComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FVector NewLocation = Owner.GetActorLocation() + (MoveComponent.ProjectileVelocity * DeltaTime);
        ProjectileOwner.SetActorLocation(NewLocation, true, DamageComponent.MovementHitResult, false);
    }
};