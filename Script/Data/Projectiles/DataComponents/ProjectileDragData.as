class UProjectileDragData : UProjectileDataComponent
{
    // 0.47f is the drag coefficient of a sphere
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Drag Settings", meta=(ClampMin=0.0f, ClampMax=10.0f))
    float DragCoefficient = 0.47f;

    // 1.225f is the density of air at sea level and 20 degrees Celsius, 999.97f is the density of water at 20 degrees Celsius, 1410.0f is the density of honey at 20 degrees Celsius
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Drag Settings", meta=(ClampMin=0.0f, ClampMax=2000.0f))
    float FluidDensity = 1.225f;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileDragCapability::StaticClass());
        UProjectileMoveComponent MoveComponent = UProjectileMoveComponent::GetOrCreate(Projectile);
        MoveComponent.DragCoefficient = DragCoefficient;
        MoveComponent.FluidDensity = FluidDensity;
    }
};
