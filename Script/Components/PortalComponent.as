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

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Duplicate")
    float DuplicateTransitionTime = 0.1f;

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Duplication")
    float SpawnDuplicateBufferDistance = 150.0f;
    
    UPROPERTY(EditDefaultsOnly, Category = "Portal|Duplication")
    float RemoveDuplicateBufferDistance = 150.0f;
    
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
    private TArray<AActor> TeleportedActors;
    private TMap<AActor, FDuplicateInfo> DuplicatedActors;

    const TMap<AActor, FDuplicateInfo>& GetDuplicatedActors() 
    { 
        return DuplicatedActors; 
    }

    void RegisterDuplicate(const AActor OriginalActor, AActor DuplicateActor, bool bTeleported = false)
    {
        if (IsValid(OriginalActor) && IsValid(DuplicateActor))
        {
            FDuplicateInfo Info;
            Info.DuplicateActor = DuplicateActor;
            Info.bOriginalWasTeleported = bTeleported;
            
            DuplicatedActors.Add(OriginalActor, Info);
        }
    }

    void UpdateDuplicateStatus(const AActor OriginalActor, bool bTeleported)
    {
        if (DuplicatedActors.Contains(OriginalActor))
        {
            DuplicatedActors[OriginalActor].bOriginalWasTeleported = bTeleported;
        }
    }

    void RemoveDuplicate(const AActor OriginalActor)
    {
        DuplicatedActors.Remove(OriginalActor);
    }

    void EmptyDuplicatedActors() 
    { 
        DuplicatedActors.Empty(); 
    }

    AActor GetDuplicateActor(const AActor OriginalActor)
    {
        if (DuplicatedActors.Contains(OriginalActor))
        {
            return DuplicatedActors[OriginalActor].DuplicateActor;
        }
        return nullptr;
    }

    bool IsActorTeleported(const AActor OriginalActor)
    {
        if (DuplicatedActors.Contains(OriginalActor))
        {
            return DuplicatedActors[OriginalActor].bOriginalWasTeleported;
        }
        return false;
    }

    void TransferDuplicateToLinkedPortal(const AActor OriginalActor)
    {
        if (!IsValid(LinkedPortal) || !DuplicatedActors.Contains(OriginalActor))
            return;
                
        FDuplicateInfo& DuplicateInfo = DuplicatedActors[OriginalActor];
        
        // Mark as in transition state and store current time
        DuplicateInfo.bInTransition = true;
        DuplicateInfo.TransitionStartTime = System::GetGameTimeInSeconds();
        
        // Update teleported status
        DuplicateInfo.bOriginalWasTeleported = true;
        
        // Register the duplicate with the linked portal, mark that it's still in transition
        LinkedPortal.PortalComponent.RegisterDuplicate(OriginalActor, DuplicateInfo.DuplicateActor, true);
    }


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

    void SetCameraSynced(bool bInCameraSynced)
    {
        bCameraSynced = bInCameraSynced;
        if (IsValid(LinkedPortal))
            LinkedPortal.PortalComponent.bCameraSynced = bInCameraSynced;
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

    TArray<AActor> GetTeleportedActors() const
    {
        return TeleportedActors;
    }

    void AddTeleportedActor(AActor Actor)
    {
        if (IsValid(Actor))
            TeleportedActors.AddUnique(Actor);
    }

    void RemoveTeleportedActor(AActor Actor)
    {
        if (IsValid(Actor))
            TeleportedActors.Remove(Actor);
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
