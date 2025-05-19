class UPortalActorProximityTrackerCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    UPortalComponent PortalComp;
    UBoxComponent TrackingBox;


    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PortalComp = UPortalComponent::Get(Owner);
        if (!IsValid(PortalComp))
            return;
        SetupTeleportTrackingBox();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return false;
    }

    private void SetupTeleportTrackingBox()
    {
        TrackingBox = UBoxComponent::Get(Owner, n"TrackingBox");
            
        if (!IsValid(TrackingBox))
        {
            Log(n"PortalWarning", f"TrackingBox not found on portal actor: {Owner.GetName()}");
            return;
        }

        TrackingBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        TArray<AActor> OverlappingActors;
        TrackingBox.GetOverlappingActors(OverlappingActors);
        OverlappingActors.Remove(Owner); // Remove the portal actor itself from the list
        
        // Remove all actors that are no longer overlapping the tracking box
        TArray<AActor> ActorsToRemove;
        for(UTeleportActorComponent Component : PortalComp.GetTrackedTeleportComponents())
        {
            if (!IsValid(Component) || !IsValid(Component.Owner))
                continue;

            if (OverlappingActors.Contains(Component.Owner) || OverlappingActors.Contains(Component.GetDuplicateActor()))
                continue;

            ActorsToRemove.Add(Component.Owner);
        }

        for(AActor Actor : ActorsToRemove)
        {
            if (!IsValid(Actor))
                continue;

            PortalComp.StopTracking(Actor);
        }

        // Register all new actors that are overlapping the tracking box
        for(AActor Actor : OverlappingActors)
        {
            if (!IsValid(Actor) || Actor == Owner)
                continue;

            if(PortalComp.IsTrackingActor(Actor)) // If the actor is already tracked, skip it
                continue;

            UTeleportActorComponent TeleportedActorComp = UTeleportActorComponent::GetOrCreate(Actor);
            TeleportedActorComp.bSetUpNewPortal = true;
            TeleportedActorComp.SetActivePortal(Cast<APortalActor>(Owner));
            PortalComp.StartTracking(TeleportedActorComp);
        }
    }
}