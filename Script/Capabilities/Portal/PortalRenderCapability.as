class UPortalRenderCapability : UCapability
{
    default Priority = ECapabilityPriority::MAX;

    private APortalActor PortalOwner;
    private UPortalComponent PortalComp;
    private UCameraComponent PlayerCamera;
    private float LastResolutionUpdateTime = 0.0f;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PortalOwner = Cast<APortalActor>(Owner);
        PortalComp = UPortalComponent::GetOrCreate(PortalOwner);
        
        // Setup components related to rendering
        SetupPortalFrameMesh();
        SetupSceneCapture();
        SetupPortalPlayerCamera();
        
        // Initialize rendering data
        InitializePortalMaterial();
        CalculateMeshWorldCorners();
        
        // Register with portal subsystem
        UPortalSubsystem::Get().RegisterPortal(PortalOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return IsValid(PortalComp.GetLinkedPortal());
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return !IsValid(PortalComp.GetLinkedPortal());
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        // When activated, set the material of the portal frame
        UMaterialInstanceDynamic LinkedMaterial = PortalComp.GetLinkedPortal().PortalComponent.GetPortalMaterialInstance();
        if (IsValid(LinkedMaterial))
        {
            PortalComp.PortalFrameMesh.SetMaterial(0, LinkedMaterial);
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (!EnsureCamera())
        {
            Log(n"PortalRenderCapability", f"Camera is not valid for {Owner.GetName()}. Cannot update portal.");
            return;
        }
            
        // Quick visibility test - if portal isn't visible, skip rendering 
        // Always update if the camera is not synced
        if (PortalComp.GetIsCameraSynced() && !IsPortalVisibleToPlayer())
        {
            return;
        }
            
        // Update portal camera and rendering
        UpdatePortalCamera();
        HandleSceneCapture();
    }
    
    // --- Setup Methods ---
    
    private void SetupPortalFrameMesh()
    {         
        PortalComp.PortalFrameMesh = UStaticMeshComponent::GetOrCreate(PortalOwner, n"PortalFrameMesh");

        // Setup collision for portal frame
        PortalComp.PortalFrameMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
        PortalComp.PortalFrameMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_GameTraceChannel1, ECollisionResponse::ECR_Block);
    }
    
    private void SetupSceneCapture()
    {
        PortalComp.PortalSceneCapture = USceneCaptureComponent2D::GetOrCreate(PortalOwner, n"PortalSceneCapture");
            
        // Initialize SceneCapture settings
        PortalComp.PortalSceneCapture.bCaptureEveryFrame = false;
        PortalComp.PortalSceneCapture.bCaptureOnMovement = false;
        PortalComp.PortalSceneCapture.bAlwaysPersistRenderingState = true;
        PortalComp.PortalSceneCapture.CompositeMode = ESceneCaptureCompositeMode::SCCM_Composite;

        UpdateClippingPlane();
    }
    
    private void SetupPortalPlayerCamera()
    {
        PortalComp.PortalPlayerCamera = UCameraComponent::GetOrCreate(PortalOwner, n"PortalPlayerCamera");
    }
    
    private void InitializePortalMaterial()
    {
        if (!IsValid(PortalComp.PortalMaterialBase))
        {
            Log(n"Error", "PortalMaterialBase is not set. Please assign a material to the portal.");
            return;
        }
        
        UMaterialInstanceDynamic MaterialInstance = PortalComp.PortalFrameMesh.CreateDynamicMaterialInstance(0, PortalComp.PortalMaterialBase);
        PortalComp.SetPortalMaterialInstance(MaterialInstance);
        
        // Create the portal camera texture target
        UTextureRenderTarget2D RenderTarget = Cast<UTextureRenderTarget2D>(NewObject(this, UTextureRenderTarget2D::StaticClass()));
        RenderTarget.InitAutoFormat(1024, 1024);
        PortalComp.PortalSceneCapture.TextureTarget = RenderTarget;
        MaterialInstance.SetTextureParameterValue(n"PortalTexture", RenderTarget);
    }

    void UpdateResolution()
    {
        APlayerController Controller = Gameplay::GetPlayerController(0);
        if (!IsValid(Controller))
            return;

        int32 ViewportX = 0, ViewportY = 0;
        Controller.GetViewportSize(ViewportX, ViewportY);
        
        if (PortalComp.PortalSceneCapture.TextureTarget.SizeX != ViewportX || PortalComp.PortalSceneCapture.TextureTarget.SizeY != ViewportY)
        {
            PortalComp.PortalSceneCapture.TextureTarget.ResizeTarget(uint32(ViewportX), uint32(ViewportY));
        }
    }
    
    private void CalculateMeshWorldCorners()
    {
        if (!IsValid(PortalComp) || !IsValid(PortalComp.PortalFrameMesh))
            return;
            
        FVector LocalMin, LocalMax;
        PortalComp.PortalFrameMesh.GetLocalBounds(LocalMin, LocalMax);

        FTransform MeshTransform = PortalComp.PortalFrameMesh.GetWorldTransform();

        TArray<FVector> Corners;
        Corners.Add(MeshTransform.TransformPosition(FVector(LocalMin.X, LocalMin.Y, 0)));
        Corners.Add(MeshTransform.TransformPosition(FVector(LocalMax.X, LocalMin.Y, 0)));
        Corners.Add(MeshTransform.TransformPosition(FVector(LocalMax.X, LocalMax.Y, 0)));
        Corners.Add(MeshTransform.TransformPosition(FVector(LocalMin.X, LocalMax.Y, 0)));
        
        PortalComp.SetMeshWorldCorners(Corners);
    }
    
    // --- Helper Methods ---
    private bool EnsureCamera()
    {
        if (!IsValid(PlayerCamera))
        {
            PlayerCamera = UCameraComponent::Get(Gameplay::GetPlayerCharacter(0));
            if (!IsValid(PlayerCamera))
                return false;

            // Initialize portal camera properties from player camera
            SyncCameraProperties();
            UpdateResolution();

            return true;
        }
        return IsValid(PlayerCamera);
    }
    
    private void SyncCameraProperties()
    {
        if (!IsValid(PortalComp.PortalPlayerCamera) || !IsValid(PlayerCamera))
            return;
            
        PortalComp.PortalPlayerCamera.ProjectionMode = PlayerCamera.ProjectionMode;
        PortalComp.PortalPlayerCamera.FieldOfView = PlayerCamera.FieldOfView;
        PortalComp.PortalPlayerCamera.bOverrideAspectRatioAxisConstraint = PlayerCamera.bOverrideAspectRatioAxisConstraint;
        PortalComp.PortalPlayerCamera.AspectRatioAxisConstraint = PlayerCamera.AspectRatioAxisConstraint;
    }
    
    private bool IsPortalVisibleToPlayer()
    {
        if (!IsValid(PlayerCamera) || !IsValid(PortalComp.GetLinkedPortal()))
            return false;
            
        // Skip if the player camera is behind the portal
        if (PortalComp.IsBehindPortal(PlayerCamera.GetWorldLocation()))
            return false;
            
        // Is portal in camera view frustum?
        return IsVisibleInPlayerViewport();
    }
    
    private bool IsVisibleInPlayerViewport()
    {
        APlayerController PlayerController = Gameplay::GetPlayerController(0);
        if (!IsValid(PlayerController))
            return false;
                       
        // For more precision, check if any corners are in the viewport
        int ViewportX = 0;
        int ViewportY = 0;
        PlayerController.GetViewportSize(ViewportX, ViewportY);

        for (const FVector& Corner : PortalComp.GetMeshWorldCorners())
        {
            FVector2D ScreenPos;
            if (PlayerController.ProjectWorldLocationToScreen(Corner, ScreenPos))
            {
                if (ScreenPos.X > 0 && ScreenPos.X < ViewportX &&
                    ScreenPos.Y > 0 && ScreenPos.Y < ViewportY)
                {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    private void UpdatePortalCamera()
    {
        UPortalComponent LinkedPortalComp = PortalComp.GetLinkedPortal().PortalComponent;
        if (!IsValid(LinkedPortalComp))
            return;
            
        FTransform FromTransform;
        FTransform LinkedTransform;
        
        if (PortalComp.GetIsCameraSynced())
        {
            FromTransform = PortalOwner.GetActorTransform();
            LinkedTransform = PortalComp.GetLinkedPortal().GetActorTransform();
        }
        else
        {
            FromTransform = PortalComp.GetLinkedPortal().GetActorTransform();
            LinkedTransform = PortalOwner.GetActorTransform();
        }

        FVector Location = ComputeLinkedCameraLocation(
            FromTransform, 
            LinkedTransform,
            PlayerCamera.GetWorldLocation());
                                            
        FRotator Rotation = ComputeLinkedCameraRotation(
            FromTransform, 
            LinkedTransform,
            PlayerCamera.GetWorldRotation());

        PortalComp.PortalPlayerCamera.SetWorldLocationAndRotation(Location, Rotation);
    }
    
    private void HandleSceneCapture()
    {
        UPortalComponent LinkedPortalComp = PortalComp.GetLinkedPortal().PortalComponent;
        if (!IsValid(LinkedPortalComp))
        {
            Log(n"Error", f"Linked portal component is not valid for {GetName()}. Cannot handle scene capture.");
            return;
        }
            
        UpdateClippingPlane();       
        
        // Reset projection data
        PortalComp.GetProjectedMeshWorldCorners().Empty();
        
        // Start recursion
        UpdateLinkedSceneCaptureRecursive(FVector::ZeroVector, FRotator::ZeroRotator, 0, PortalComp.MaxPortalRecursion);
    }
    
    private void UpdateLinkedSceneCaptureRecursive(FVector OldLocation, FRotator OldRotation, int CurrentRecursion, int MaxRecursions)
    {
        UPortalComponent LinkedPortalComp = PortalComp.GetLinkedPortal().PortalComponent;
        if (!IsValid(LinkedPortalComp))
        {
            Log(n"Error", f"Linked portal component is not valid for {GetName()}. Cannot update linked scene capture.");
            return;
        }
            
        UCameraComponent Camera = PortalComp.GetIsCameraSynced() ? PlayerCamera : PortalComp.PortalPlayerCamera;
        
        if (CurrentRecursion == 0)
        {
            if (!IsValid(Camera))
            {
                Log(n"PortalRenderCapability", f"Camera is not valid for {GetName()}. Cannot update linked scene capture.");
                return;
            }

            FVector TempLocation = ComputeLinkedCameraLocation(
                PortalOwner.GetActorTransform(), 
                PortalComp.GetLinkedPortal().GetActorTransform(), 
                Camera.GetWorldLocation());
                                                            
            FRotator TempRotation = ComputeLinkedCameraRotation(
                PortalOwner.GetActorTransform(), 
                PortalComp.GetLinkedPortal().GetActorTransform(), 
                Camera.GetWorldRotation());
                                                            
            LinkedPortalComp.PortalSceneCapture.SetWorldLocationAndRotation(TempLocation, TempRotation);

            // Continue recursion if the portal is visible
            if (CanSeePortalTransformed(CurrentRecursion))
            {
                UpdateLinkedSceneCaptureRecursive(TempLocation, TempRotation, CurrentRecursion + 1, MaxRecursions);
            }
          
            LinkedPortalComp.PortalSceneCapture.SetWorldLocationAndRotation(TempLocation, TempRotation);
            LinkedPortalComp.PortalSceneCapture.CaptureScene();
        }
        else if (CurrentRecursion < MaxRecursions)
        {            
            FVector TempLocation = ComputeLinkedCameraLocation(
                PortalOwner.GetActorTransform(), 
                PortalComp.GetLinkedPortal().GetActorTransform(), 
                OldLocation);
                                                            
            FRotator TempRotation = ComputeLinkedCameraRotation(
                PortalOwner.GetActorTransform(), 
                PortalComp.GetLinkedPortal().GetActorTransform(), 
                OldRotation);
                                                            
            LinkedPortalComp.PortalSceneCapture.SetWorldLocationAndRotation(TempLocation, TempRotation);

            // Continue recursion if the portal is visible
            if (CanSeePortalTransformed(CurrentRecursion))
            {
                UpdateLinkedSceneCaptureRecursive(TempLocation, TempRotation, CurrentRecursion + 1, MaxRecursions);
            }

            LinkedPortalComp.PortalSceneCapture.SetWorldLocationAndRotation(TempLocation, TempRotation);
            LinkedPortalComp.PortalSceneCapture.CaptureScene();
        }
        else
        {
            FVector Location = ComputeLinkedCameraLocation(
                PortalOwner.GetActorTransform(), 
                PortalComp.GetLinkedPortal().GetActorTransform(), 
                OldLocation);
                                                        
            FRotator Rotation = ComputeLinkedCameraRotation(
                PortalOwner.GetActorTransform(), 
                PortalComp.GetLinkedPortal().GetActorTransform(), 
                OldRotation);
                                                        
            LinkedPortalComp.PortalSceneCapture.SetWorldLocationAndRotation(Location, Rotation);
            
            // Final recursion - always render but hide portal to avoid recursion artifacts
            bool bWasHidden = PortalOwner.IsHidden();
            PortalOwner.SetActorHiddenInGame(true);
            LinkedPortalComp.PortalSceneCapture.CaptureScene();
            PortalOwner.SetActorHiddenInGame(bWasHidden);

        }
    }
    
    private FVector ComputeLinkedCameraLocation(FTransform FromTransform, FTransform LinkedTransform, FVector OldLocation)
    {
        // Create a mirrored transform
        FVector Scale = FromTransform.GetScale3D();
        Scale.X *= -1;
        Scale.Y *= -1;
        FTransform MirrorTransform(FromTransform.Rotation, FromTransform.Location, Scale);
        
        // Transform camera position through the portal
        FVector LocalCameraPos = MirrorTransform.InverseTransformPosition(OldLocation);
        return LinkedTransform.TransformPosition(LocalCameraPos);
    }

    private FRotator ComputeLinkedCameraRotation(FTransform FromTransform, FTransform LinkedTransform, FRotator OldRotation)
    {
        // Extract camera axes
        FVector CameraForward = OldRotation.GetForwardVector();
        FVector CameraRight = OldRotation.GetRightVector();
        FVector CameraUp = OldRotation.GetUpVector();

        // Create array of axes to transform
        TArray<FVector> LocalAxes;
        LocalAxes.Add(CameraForward);
        LocalAxes.Add(CameraRight);
        LocalAxes.Add(CameraUp);

        TArray<FVector> TransformedAxes;
        TransformedAxes.SetNum(LocalAxes.Num());

        // Transform each axis
        for (int32 i = 0; i < LocalAxes.Num(); i++)
        {
            FVector LocalAxis = FromTransform.InverseTransformVectorNoScale(LocalAxes[i]);
            FVector MirroredAxis = MirrorVectorXY(LocalAxis);
            TransformedAxes[i] = LinkedTransform.TransformVectorNoScale(MirroredAxis);
        }

        // Create new rotation from transformed axes
        return FRotator::MakeFromAxes(TransformedAxes[0], TransformedAxes[1], TransformedAxes[2]);
    }
    
    private FVector MirrorVectorXY(const FVector& Vector) const
    {
        // Mirror vector along X and Y axes
        FVector MirroredVec = Vector.MirrorByVector(FVector(1, 0, 0)); 
        MirroredVec = MirroredVec.MirrorByVector(FVector(0, 1, 0));
        return MirroredVec;
    }
    
    private void UpdateClippingPlane()
    {
        if (!IsValid(PortalComp.PortalSceneCapture))
        {
            Log(n"Error", f"Portal scene capture is not valid for {GetName()}. Cannot update clipping plane.");
            return;
        }
            
        PortalComp.PortalSceneCapture.bEnableClipPlane = true;
        PortalComp.PortalSceneCapture.ClipPlaneBase = PortalComp.PortalFrameMesh.GetWorldLocation() + PortalOwner.GetActorForwardVector() * -3.0f;
        PortalComp.PortalSceneCapture.ClipPlaneNormal = PortalOwner.GetActorForwardVector();
    }
    
    private bool CanSeePortalTransformed(const int Recursion)
    {
        UPortalComponent LinkedPortalComp = PortalComp.GetLinkedPortal().PortalComponent;
        if (!IsValid(LinkedPortalComp))
            return false;

        // Get outer portal corners projection
        FProjectedPortalCorners OuterProjectedFrameCorners;
        OuterProjectedFrameCorners.Recursion = Recursion;
        
        for (const FVector& Corner : LinkedPortalComp.GetMeshWorldCorners())
        {
            FVector2D ScreenPosition;
            if (SceneCapture::ProjectWorldToScreen(LinkedPortalComp.PortalSceneCapture, Corner, ScreenPosition, 10000.0f, true))
            {
                OuterProjectedFrameCorners.ProjectedCorners.Add(ScreenPosition);
            }
        }
        
        PortalComp.GetProjectedMeshWorldCorners().Add(Recursion, OuterProjectedFrameCorners);
        
        // Get inner portal corners projection
        TArray<FVector2D> ProjectedFrameCorners;
        for (const FVector& Corner : PortalComp.GetMeshWorldCorners())
        {
            FVector2D ScreenPosition;
            if (SceneCapture::ProjectWorldToScreen(LinkedPortalComp.PortalSceneCapture, Corner, ScreenPosition))
            {
                ProjectedFrameCorners.Add(ScreenPosition);
            }
        }

        // Check if the inner portal is visible in all previous projections
        for (int i = 0; i < PortalComp.GetProjectedMeshWorldCorners().Num(); i++)
        {
            if (!IsAnyPointInsideBounds(ProjectedFrameCorners, PortalComp.GetProjectedMeshWorldCorners()[i].ProjectedCorners))
                return false;
        }
    
        return true;
    }
    
    private bool IsAnyPointInsideBounds(const TArray<FVector2D>& PointsToCheck, const TArray<FVector2D>& BoundaryPoints)
    {
        if (BoundaryPoints.IsEmpty())
            return false;

        // Check if any of the test points are within the boundary
        for (const FVector2D& Point : PointsToCheck)
        {
            if (IsPointInsideConvexPolygon(Point, BoundaryPoints))
                return true;
        }
        
        return false;
    }
   
    private bool IsPointInsideConvexPolygon(const FVector2D& Point, const TArray<FVector2D>& PolygonVertices)
    {
        if (PolygonVertices.Num() < 3)
            return false;

        bool bHasPositive = false;
        bool bHasNegative = false;

        for (int32 i = 0; i < PolygonVertices.Num(); ++i)
        {
            const FVector2D& V1 = PolygonVertices[i];
            const FVector2D& V2 = PolygonVertices[(i + 1) % PolygonVertices.Num()];

            FVector2D Edge = V2 - V1;
            FVector2D ToPoint = Point - V1;

            float CrossProduct = Edge.CrossProduct(ToPoint);

            if (CrossProduct > KINDA_SMALL_NUMBER)
            {
                bHasPositive = true;
            }
            else if (CrossProduct < KINDA_SMALL_NUMBER)
            {
                bHasNegative = true;
            }

            if (bHasPositive && bHasNegative)
                return false;
        }

        return true;
    }

    // --- Debug Methods ---

    // Draw the 2D projected polygon on a flat plane near world origin
    private void DrawDebugProjectedPolygon(const TArray<FVector2D>& ProjectedCorners, FLinearColor Color, 
                                        float ZOffset = 0.0f, float Duration = 0.0f, float Thickness = 2.0f)
    {
        if (ProjectedCorners.Num() < 3)
            return;
            
        // Scale factor to make the debug visualization a reasonable size
        float ScaleFactor = 100.0f;
        
        // Create 3D points from the 2D projections
        TArray<FVector> WorldPoints;
        for (const FVector2D& ScreenPos : ProjectedCorners)
        {
            // Convert from [0,1] screen space to centered coordinates 
            // and scale up to a visible size at origin
            FVector WorldPos = FVector(
                ZOffset,
                (ScreenPos.X - 0.5f),
                (ScreenPos.Y - 0.5f)
            );
            
            WorldPoints.Add(WorldPos);
        }
        
        // Draw the polygon
        for (int32 i = 0; i < WorldPoints.Num(); ++i)
        {
            int32 NextIdx = (i + 1) % WorldPoints.Num();
            System::DrawDebugLine(WorldPoints[i], WorldPoints[NextIdx], Color, Duration, 2);
        }
    }
}
