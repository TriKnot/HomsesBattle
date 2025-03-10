class UProjectileGravityEffectCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;

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
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        MoveComponent.ProjectileVelocity.Z -= PhysicStatics::Gravity * MoveComponent.GravityData.GravityEffectMultiplier * DeltaTime;
    }
};