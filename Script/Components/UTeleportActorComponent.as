
class UTeleportActorComponent : UActorComponent
{    
    // --- Runtime Data ---
    private APortalActor ActivePortal;
    private FPlane ActivePortalPlane;
    private AActor DuplicateActor;
    private FVector LastKnownLocation;
    TMap<UMeshComponent, FMaterialInstanceCollection> OriginalMaterials;
    bool bSetUpNewPortal;


    void NotifyTeleported(APortalActor PortalActor, const FPlane& InPortalPlane)
    {
        ActivePortal = PortalActor;
        ActivePortalPlane = InPortalPlane;
        bSetUpNewPortal = true;
    }

    void SetActivePortal(APortalActor PortalActor)
    {
        ActivePortal = PortalActor;
    }

    void SetActivePortal(AActor Actor)
    {
        APortalActor CastActor = Cast<APortalActor>(Actor);
        if (IsValid(CastActor))
        {
            ActivePortal = CastActor;
            SetActivePortalPlane();
        }
        else
        {
            Log(n"Warning", "Attempted to set active portal to non-portal actor");
        }
    }

    APortalActor GetActivePortal() const
    {
        return ActivePortal;
    }

    private void SetActivePortalPlane()
    {
        UPortalComponent PortalComp = UPortalComponent::Get(ActivePortal);
        if(!IsValid(PortalComp))
            return;

        ActivePortalPlane = PortalComp.GetPortalPlane();
    }

    FPlane GetActivePortalPlane() const
    {
        return ActivePortalPlane;
    }

    void SetDuplicateActor(AActor InDuplicateActor)
    {
        DuplicateActor = InDuplicateActor;
    }
    
    AActor GetDuplicateActor() const
    {
        return DuplicateActor;
    }

    void UpdateLastKnownLocation()
    {
        LastKnownLocation = Owner.GetActorLocation();
    }

    const FVector& GetLastKnownLocation() const
    {
        return LastKnownLocation;
    }
}