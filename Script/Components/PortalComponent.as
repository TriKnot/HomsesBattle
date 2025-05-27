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

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Duplication")
    float SpawnDuplicateBufferDistance = 150.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Duplication")
    float RemoveDuplicateBufferDistance = 150.0f;
    
    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual")
    FLinearColor BaseColor = FLinearColor(1.00, 0.00, 0.95, 0.25);

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual")
    FLinearColor HighlightColor = FLinearColor(1.00, 0.00, 0.97, 0.64);

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Clip|Material")
    float ClipOffset = 0.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    UNiagaraSystem IntersectionNiagaraSystem_SkeletalMesh;

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    UNiagaraSystem OffsetIntersectionNiagaraSystem_SkeletalMesh;

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    UNiagaraSystem IntersectionNiagaraSystem_StaticMesh;

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    float ClipIntersetionThickness = 1.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    float ClipIntersectionOffset = 0.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    FName OriginParamName = n"PortalPlaneOrigin";

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    FName NormalParamName = n"PortalPlaneNormal";

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    FName IntersectionThicknessParamName = n"IntersectionThickness";

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    FName SkeletalMeshSampleParamName = n"SkeletalMeshSample";

    UPROPERTY(EditDefaultsOnly, Category = "Portal|Visual|Niagara")
    FName StaticMeshSampleParamName = n"StaticMeshSample";

    // --- Components References ---
    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PortalFrameMesh;   
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent PlayerNearbyDetectionBox;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    USceneCaptureComponent2D PortalSceneCapture;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UCameraComponent PortalPlayerCamera;

    // --- Runtime Data ---
    private APortalActor LinkedPortal;
    private UMaterialInstanceDynamic PortalMaterialInstance;
    private TArray<UTeleportActorComponent> TrackedTeleportedActorComponents;
    private FPlane PortalPlane;
    private TArray<FVector> MeshWorldCorners;
    private TMap<int, FProjectedPortalCorners> ProjectedMeshWorldCorners;
    private bool bCameraSynced = true;
    private bool bCameraTransitionActive = false;
    TMap<AActor, FMaterialInstanceCollection> ActorToOriginalMaterials;
    TArray<AActor> ActorsBehindPortal;  

    // --- Duplicate Actors Management ---
    bool GetTeleportComponent(const AActor OriginalActor, UTeleportActorComponent& OutComponent) const
    {
        if(!IsValid(OriginalActor))
            return false;

        for (UTeleportActorComponent TeleportedActorComp : TrackedTeleportedActorComponents)
        {
            if (IsValid(TeleportedActorComp) && TeleportedActorComp.Owner == OriginalActor)
            {
                OutComponent = TeleportedActorComp;
                return true;
            }
        }

        return false;
    }

    bool IsTrackingActor(const AActor OriginalActor) const
    {
        if(!IsValid(OriginalActor))
            return false;

        for (UTeleportActorComponent TeleportedActorComp : TrackedTeleportedActorComponents)
        {
            if (IsValid(TeleportedActorComp) && TeleportedActorComp.Owner == OriginalActor)
            {
                return true;
            }
        }

        return false;
    }

    // --- Linked Portal Management ---

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

    // --- Actor Tracking ---

    void StartTracking(UTeleportActorComponent TrackedComponent)
    {
        if (IsValid(TrackedComponent))
        {
            TrackedTeleportedActorComponents.AddUnique(TrackedComponent);
        }
    }

    void StartTracking(AActor Actor)
    {
        if (IsValid(Actor))
        {
            UTeleportActorComponent TeleportedActorComp = UTeleportActorComponent::GetOrCreate(Actor);
            StartTracking(TeleportedActorComp);
        }
    }

    void StopTracking(UTeleportActorComponent TrackedComponent)
    {
        if (IsValid(TrackedComponent))
        {
            TrackedTeleportedActorComponents.Remove(TrackedComponent);
        }
    }

    void StopTracking(AActor Actor)
    {
        if (IsValid(Actor))
        {
            UTeleportActorComponent TeleportedActorComp = UTeleportActorComponent::GetOrCreate(Actor);
            StopTracking(TeleportedActorComp);
        }
    }

    // --- Camera Sync & Transition ---

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

    // --- Portal Plane ---
    void SetPortalPlane(const FPlane& NewPortalPlane) 
    { 
        PortalPlane = NewPortalPlane; 
    }

    FPlane GetPortalPlane() const 
    { 
        return PortalPlane; 
    }

    bool IsBehindPortal(const FVector& Point) const 
    { 
        return PortalPlane.PlaneDot(Point) < 0.0f; 
    }

    TArray<UTeleportActorComponent>& GetTrackedTeleportComponents() 
    { 
        return TrackedTeleportedActorComponents;
    }

    // --- Mesh Corners (for rendering) ---
    void SetMeshWorldCorners(const TArray<FVector>& Corners) 
    { 
        MeshWorldCorners = Corners; 
    }

    const TArray<FVector>& GetMeshWorldCorners() const 
    { 
        return MeshWorldCorners; 
    }

    TMap<int, FProjectedPortalCorners>& GetProjectedMeshWorldCorners() 
    { 
        return ProjectedMeshWorldCorners; 
    } 

    // --- Material Instance ---
    void SetPortalMaterialInstance(UMaterialInstanceDynamic MaterialInstance)
    {
        PortalMaterialInstance = MaterialInstance;
    }
    
    UMaterialInstanceDynamic GetPortalMaterialInstance() const
    {
        return PortalMaterialInstance;
    }
}

