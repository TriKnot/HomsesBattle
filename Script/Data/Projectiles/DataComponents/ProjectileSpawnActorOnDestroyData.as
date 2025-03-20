class UProjectileSpawnActorOnDestroyData : UProjectileDataComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Effect")
    TSubclassOf<AActor> ActorClass;

    UFUNCTION(BlueprintOverride)
    void ApplyData(AProjectileActor Projectile)
    {
        Projectile.CapabilityComponent.AddCapability(UProjectileSpawnActorOnDestroyCapability::StaticClass());
        UProjectileSpawnActorComponent::GetOrCreate(Projectile).EffectActorClass = ActorClass;
    }
}
