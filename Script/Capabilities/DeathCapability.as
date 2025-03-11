class UDeathCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    AHomseCharacterBase HomseOwner;
    UHealthComponent HealthComp;
    TArray<ULockableComponent> LockableComponents;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        HomseOwner = Cast<AHomseCharacterBase>(Owner);
        HomseOwner.GetComponentsByClass(LockableComponents);
        HealthComp = HomseOwner.HealthComponent;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return HealthComp.CurrentHealth <= 0.0f;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        TArray<UPrimitiveComponent> PrimitiveComponents;
        PrimitiveComponents.Add(HomseOwner.CapsuleComponent);
        HomseOwner.CapsuleComponent.GetChildrenComponentsByClass(UPrimitiveComponent::StaticClass(), true, PrimitiveComponents);
        
        for(UPrimitiveComponent PrimitiveComponent : PrimitiveComponents)
        {
            PrimitiveComponent.SetCollisionEnabled(ECollisionEnabled::PhysicsOnly);
            PrimitiveComponent.SetSimulatePhysics(true);
            PrimitiveComponent.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
            PrimitiveComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
        }

        HomseOwner.Mesh.SetCollisionProfileName(n"Ragdoll");
        HomseOwner.Mesh.SetSimulatePhysics(true);
        HomseOwner.Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Block);
        HomseOwner.Mesh.SetLinearDamping(5.0f);
        HomseOwner.Mesh.SetAngularDamping(5.0f);
        HomseOwner.Mesh.SetAllMassScale(0.2f);

    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        for(ULockableComponent LockableComponent : LockableComponents)
        {
            LockableComponent.Lock(this);
        }
    }
};