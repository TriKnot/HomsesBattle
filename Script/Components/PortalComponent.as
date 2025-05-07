class UPortalComponent : UActorComponent
{
    // --- Portal Configuration ---
    UPROPERTY(EditDefaultsOnly, Category = "Portal")
    UMaterialInterface PortalMaterialBase;

    UPROPERTY(EditDefaultsOnly, Category = "Portal")
    int MaxPortalRecursion = 3;
    
    UPROPERTY(EditDefaultsOnly, Category = "Portal")
    float NearClipDistance = 10.0f;
    
    UPROPERTY(EditDefaultsOnly, Category = "Portal|Performance")
    float MaxTrackedActorDistance = 500.0f;    
    
    UPROPERTY(EditDefaultsOnly, Category = "Portal|Performance")
    float TrackedActorCleanupInterval = 0.5f;

    // --- Components References ---
    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PortalFrameMesh;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent TeleportTriggerVolume;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent PlayerNearbyDetectionBox;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    USceneCaptureComponent2D PortalSceneCapture;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UCameraComponent PortalPlayerCamera;

    // --- Runtime Data ---
    private APortalActor LinkedPortal;
    private UMaterialInstanceDynamic PortalMaterialInstance;
    private TMap<AActor, FVector> TrackedActors;
    private FPlane PortalPlane;
    private TArray<FVector> MeshWorldCorners;
    private TMap<int, FProjectedPortalCorners> ProjectedMeshWorldCorners;
    private bool bCameraSynced = true;
    private bool bCameraTransitionActive = false;

    void SetLinkedPortal(APortalActor OtherPortal)
    {
        if (!IsValid(OtherPortal) || OtherPortal == Owner)
        {
            Log(n"Warning", "Attempted to link portal to invalid portal or self");
            return;
        }
        
        LinkedPortal = OtherPortal;
    }
    
    APortalActor GetLinkedPortal() const
    {
        return LinkedPortal;
    }
    
    void SetPortalMaterialInstance(UMaterialInstanceDynamic MaterialInstance)
    {
        PortalMaterialInstance = MaterialInstance;
    }
    
    UMaterialInstanceDynamic GetPortalMaterialInstance() const
    {
        return PortalMaterialInstance;
    }

    void SetPortalPlane(const FPlane& NewPortalPlane)
    {
        PortalPlane = NewPortalPlane;
    }
    
    bool IsBehindPortal(const FVector& Point) const
    {
        return PortalPlane.PlaneDot(Point) < 0.0f;
    }

    void TrackActor(AActor Actor)
    {
        if (IsValid(Actor))
            TrackedActors.Add(Actor, Actor.GetActorLocation());
    }

    void StopTrackingActor(AActor Actor)
    {
        if (IsValid(Actor))
            TrackedActors.Remove(Actor);
    }

    TMap<AActor, FVector>& GetTrackedActors()
    {
        return TrackedActors;
    }

    void SetCameraSynced(bool bNewCameraSynced)
    {
        bCameraSynced = bNewCameraSynced;
        if (IsValid(LinkedPortal))
            LinkedPortal.PortalComponent.bCameraSynced = bNewCameraSynced;
    }
    
    bool GetIsCameraSynced() const property
    {
        return bCameraSynced;
    }
    
    void SetCameraTransitionActive(bool bActive)
    {
        bCameraTransitionActive = bActive;
    }
    
    bool GetIsCameraTransitionActive() const property
    {
        return bCameraTransitionActive;
    }

    void SetMeshWorldCorners(const TArray<FVector>& Corners)
    {
        MeshWorldCorners = Corners;
    }
    
    const TArray<FVector>& GetMeshWorldCorners()
    {
        return MeshWorldCorners;
    }
    
    TMap<int, FProjectedPortalCorners>& GetProjectedMeshWorldCorners()
    {
        return ProjectedMeshWorldCorners;
    }
    
    UFUNCTION()
    void OnActorNearbyOverlapBegin(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
    {
        if (IsValid(OtherActor))
            TrackActor(OtherActor);
    }

    UFUNCTION()
    void OnActorNearbyOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
    {
        if (IsValid(OtherActor))
            StopTrackingActor(OtherActor);
    }
}
