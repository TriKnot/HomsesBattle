class UPortalCollisionHandlerCapability : UCapability
{
    default Priority = ECapabilityPriority::PostInput;

    UPortalComponent PortalComp;
    UBoxComponent BehindCheckBox;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PortalComp = UPortalComponent::GetOrCreate(Owner);

        if(!IsValid(PortalComp))
        {
            Log(n"PortalWarning", f"PortalComponent not found on portal actor: {Owner.GetName()}");
            return;
        }

        SetupBehindCheckBox();

        // Find all actors behind the portal
        TArray<AActor> OutActors;
        TArray<AActor> IgnoredActors;
        IgnoredActors.Add(Owner); // Ignore the portal actor itself
        

        if(!System::ComponentOverlapActors(Cast<UPrimitiveComponent>(BehindCheckBox),BehindCheckBox.GetWorldTransform(), TArray<EObjectTypeQuery>(), AActor::StaticClass(), IgnoredActors, OutActors))
        {
            Log(n"PortalWarning", f"Failed to perform overlap check on BehindCheckBox for portal actor: {Owner.GetName()}");
            return;
        }

        for (AActor Actor : OutActors)
        {
            // Add the actor to the portal's tracked actors
            PortalComp.ActorsBehindPortal.AddUnique(Actor);
        }
    }

    UFUNCTION(BlueprintOverride)
    void Teardown()
    {
        PortalComp.ActorsBehindPortal.Empty();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return !PortalComp.GetTrackedTeleportComponents().IsEmpty();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return PortalComp.GetTrackedTeleportComponents().IsEmpty();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        ProcessTrackedTeleportComponents();
    }

    private void ProcessTrackedTeleportComponents()
    {
        for (UTeleportActorComponent TeleportedComponent : PortalComp.GetTrackedTeleportComponents())
        {
            if (!IsValid(TeleportedComponent) || !IsValid(TeleportedComponent.Owner))
                continue;

            // Only handle primitive component collisions - camera collision is handled by UPortalCameraCapability
            ProcessActorCollisions(TeleportedComponent);
        }
    }

    private void ProcessActorCollisions(UTeleportActorComponent TeleportedComponent)
    {
        AActor TransitioningActor = TeleportedComponent.Owner;
        TArray<UPrimitiveComponent> ActorPrimitiveComponents;
        TransitioningActor.GetComponentsByClass(UPrimitiveComponent::StaticClass(), ActorPrimitiveComponents);

        for (UPrimitiveComponent ActorComponent : ActorPrimitiveComponents)
        {
            if (!IsValid(ActorComponent))
                continue;

            const bool bIsOverlappingPortal = ActorComponent.IsOverlappingComponent(PortalComp.PortalFrameMesh);
            ProcessSingleComponent(TeleportedComponent, ActorComponent, bIsOverlappingPortal);
        }
    }

    private void ProcessSingleComponent(UTeleportActorComponent TeleportedComponent, UPrimitiveComponent ActorComponent, bool bIsOverlappingPortal)
    {
        const bool bIsComponentAlreadyIgnored = TeleportedComponent.CollisionIgnoredComponents.Contains(ActorComponent);

        if (bIsOverlappingPortal)
        {
            if (!bIsComponentAlreadyIgnored)
            {
                StartIgnoringCollisionsForComponent(TeleportedComponent, ActorComponent);
            }
        }
        else
        {
            if (bIsComponentAlreadyIgnored)
            {
                StopIgnoringCollisionsForComponent(TeleportedComponent, ActorComponent);
            }
        }
    }

    private void StartIgnoringCollisionsForComponent(UTeleportActorComponent TeleportedComponent, UPrimitiveComponent TransitioningComponent)
    {
        // Process actors behind this portal
        ProcessActorsBehindPortal(TeleportedComponent, TransitioningComponent, PortalComp.ActorsBehindPortal);
        
        // Process actors behind the linked portal
        UPortalComponent LinkedPortalComponent = PortalComp.GetLinkedPortal().PortalComponent;
        if (IsValid(LinkedPortalComponent))
        {
            ProcessActorsBehindPortal(TeleportedComponent, TransitioningComponent, LinkedPortalComponent.ActorsBehindPortal);
        }
    }

    private void ProcessActorsBehindPortal(UTeleportActorComponent TeleportedComponent, UPrimitiveComponent TransitioningComponent, const TArray<AActor>& ActorsBehindPortal)
    {
        for (AActor ActorBehindPortal : ActorsBehindPortal)
        {
            if (!IsValid(ActorBehindPortal))
                continue;

            TArray<UPrimitiveComponent> BehindPortalComponents;
            ActorBehindPortal.GetComponentsByClass(UPrimitiveComponent::StaticClass(), BehindPortalComponents);

            for (UPrimitiveComponent BehindPortalComponent : BehindPortalComponents)
            {
                if (!IsValid(BehindPortalComponent))
                    continue;

                StartIgnoringCollisionBetweenComponents(TransitioningComponent, BehindPortalComponent);
                AddToIgnoredComponentsTracking(TeleportedComponent, TransitioningComponent, BehindPortalComponent);
            }
        }
    }

    private void StopIgnoringCollisionsForComponent(UTeleportActorComponent TeleportedComponent, UPrimitiveComponent TransitioningComponent)
    {
        if (!TeleportedComponent.CollisionIgnoredComponents.Contains(TransitioningComponent))
            return;

        const TSet<UPrimitiveComponent>& IgnoredComponents = TeleportedComponent.CollisionIgnoredComponents[TransitioningComponent].Components;
        
        for (UPrimitiveComponent IgnoredComponent : IgnoredComponents)
        {
            if (IsValid(IgnoredComponent))
            {
                StopIgnoringCollisionBetweenComponents(TransitioningComponent, IgnoredComponent);
            }
        }
        
        TeleportedComponent.CollisionIgnoredComponents.Remove(TransitioningComponent);
    }

    private void StartIgnoringCollisionBetweenComponents(UPrimitiveComponent ComponentA, UPrimitiveComponent ComponentB)
    {
        if (!IsValid(ComponentA) || !IsValid(ComponentB))
            return;

        ComponentA.IgnoreComponentWhenMoving(ComponentB, true);
        ComponentB.IgnoreComponentWhenMoving(ComponentA, true);
    }

    private void StopIgnoringCollisionBetweenComponents(UPrimitiveComponent ComponentA, UPrimitiveComponent ComponentB)
    {
        if (!IsValid(ComponentA) || !IsValid(ComponentB))
            return;

        ComponentA.IgnoreComponentWhenMoving(ComponentB, false);
        ComponentB.IgnoreComponentWhenMoving(ComponentA, false);
    }

    private void AddToIgnoredComponentsTracking(UTeleportActorComponent TeleportedComponent, UPrimitiveComponent TransitioningComponent, UPrimitiveComponent IgnoredComponent)
    {
        TeleportedComponent.CollisionIgnoredComponents.FindOrAdd(TransitioningComponent).Add(IgnoredComponent);
    }

    private void SetupBehindCheckBox()
    {
        BehindCheckBox = UBoxComponent::Get(Owner, n"BehindCollisionCheckBox");
        if (!IsValid(BehindCheckBox))
        {
            Log(n"PortalWarning", f"BehindCheckBox not found on portal actor: {Owner.GetName()}");
            return;
        }
        
        BehindCheckBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
    }

}
