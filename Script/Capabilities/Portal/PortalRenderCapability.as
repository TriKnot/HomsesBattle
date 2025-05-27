class UPortalRenderCapability : UCapability
{
    default Priority = ECapabilityPriority::MAX;

    private APortalActor PortalOwner;
    private UPortalComponent PortalComp;
    private UCameraComponent PlayerCamera;
    
    // Cached values
    private int32 CachedViewportWidth = 0;
    private int32 CachedViewportHeight = 0;
    private bool bIsCameraInitialized = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PortalOwner = Cast<APortalActor>(Owner);
        PortalComp = UPortalComponent::GetOrCreate(PortalOwner);
        
        SetupPortalFrameMesh();
        SetupSceneCapture();
        SetupPortalPlayerCamera();
        
        InitializePortalMaterial();
        CalculateMeshWorldCorners();
        
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
        UMaterialInstanceDynamic LinkedPortalMaterial = PortalComp.GetLinkedPortal().PortalComponent.GetPortalMaterialInstance();
        if (IsValid(LinkedPortalMaterial))
        {
            PortalComp.PortalFrameMesh.SetMaterial(0, LinkedPortalMaterial);
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (!EnsureCameraIsValid())
        {
            return;
        }
            
        // Quick visibility test - skip rendering if portal isn't visible and camera is synced
        if (PortalComp.GetIsCameraSynced() && !IsPortalVisibleToPlayer())
        {
            return;
        }
            
        UpdatePortalCameraTransform();
        HandleSceneCapture();
    }
    
    // --- Setup Methods ---
    private void SetupPortalFrameMesh()
    {         
        PortalComp.PortalFrameMesh = UStaticMeshComponent::Get(PortalOwner, n"PortalFrameMesh");
        if (!IsValid(PortalComp.PortalFrameMesh))
        {
            Log(n"Error", "PortalFrameMesh is not set. Please assign a mesh to the portal frame.");
            return;
        }

        PortalComp.PortalFrameMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
        PortalComp.PortalFrameMesh.CastShadow = false;
    }
    
    private void SetupSceneCapture()
    {
        PortalComp.PortalSceneCapture = USceneCaptureComponent2D::GetOrCreate(PortalOwner, n"PortalSceneCapture");
            
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
        
        UTextureRenderTarget2D RenderTarget = Cast<UTextureRenderTarget2D>(NewObject(this, UTextureRenderTarget2D::StaticClass()));
        RenderTarget.InitAutoFormat(1024, 1024);
        PortalComp.PortalSceneCapture.TextureTarget = RenderTarget;
        MaterialInstance.SetTextureParameterValue(n"PortalTexture", RenderTarget);
    }

    private void UpdateResolution()
    {
        APlayerController PlayerController = Gameplay::GetPlayerController(0);
        if (!IsValid(PlayerController))
            return;

        int32 CurrentViewportWidth = 0;
        int32 CurrentViewportHeight = 0;
        PlayerController.GetViewportSize(CurrentViewportWidth, CurrentViewportHeight);
        
        // Only update if resolution changed
        if (CachedViewportWidth != CurrentViewportWidth || CachedViewportHeight != CurrentViewportHeight)
        {
            PortalComp.PortalSceneCapture.TextureTarget.ResizeTarget(uint32(CurrentViewportWidth), uint32(CurrentViewportHeight));
            CachedViewportWidth = CurrentViewportWidth;
            CachedViewportHeight = CurrentViewportHeight;
        }
    }
    
    private void CalculateMeshWorldCorners()
    {
        if (!IsValid(PortalComp) || !IsValid(PortalComp.PortalFrameMesh))
            return;
            
        FVector LocalBoundsMin, LocalBoundsMax;
        PortalComp.PortalFrameMesh.GetLocalBounds(LocalBoundsMin, LocalBoundsMax);

        const FTransform MeshWorldTransform = PortalComp.PortalFrameMesh.GetWorldTransform();

        TArray<FVector> WorldCorners;
        WorldCorners.Reserve(4);
        WorldCorners.Add(MeshWorldTransform.TransformPosition(FVector(LocalBoundsMin.X, LocalBoundsMin.Y, 0)));
        WorldCorners.Add(MeshWorldTransform.TransformPosition(FVector(LocalBoundsMax.X, LocalBoundsMin.Y, 0)));
        WorldCorners.Add(MeshWorldTransform.TransformPosition(FVector(LocalBoundsMax.X, LocalBoundsMax.Y, 0)));
        WorldCorners.Add(MeshWorldTransform.TransformPosition(FVector(LocalBoundsMin.X, LocalBoundsMax.Y, 0)));
        
        PortalComp.SetMeshWorldCorners(WorldCorners);
    }
    
    private bool EnsureCameraIsValid()
    {
        if (bIsCameraInitialized && IsValid(PlayerCamera))
        {
            return true;
        }

        PlayerCamera = UCameraComponent::Get(Gameplay::GetPlayerCharacter(0));
        if (!IsValid(PlayerCamera))
        {
            return false;
        }

        SyncCameraProperties();
        UpdateResolution();
        bIsCameraInitialized = true;

        return true;
    }
    
    private void SyncCameraProperties()
    {
        if (!IsValid(PortalComp.PortalPlayerCamera) || !IsValid(PlayerCamera))
            return;
            
        PortalComp.PortalPlayerCamera.SetProjectionMode(PlayerCamera.ProjectionMode);
        PortalComp.PortalPlayerCamera.SetFieldOfView(PlayerCamera.FieldOfView);
        PortalComp.PortalPlayerCamera.bOverrideAspectRatioAxisConstraint = PlayerCamera.bOverrideAspectRatioAxisConstraint;
        PortalComp.PortalPlayerCamera.SetAspectRatioAxisConstraint(PlayerCamera.AspectRatioAxisConstraint);
    }
    
    private bool IsPortalVisibleToPlayer()
    {          
        if (PortalComp.IsBehindPortal(PlayerCamera.GetWorldLocation()))
        {
            return false;
        }
            
        return IsVisibleInPlayerViewport();
    }
    
    private bool IsVisibleInPlayerViewport()
    {
        APlayerController PlayerController = Gameplay::GetPlayerController(0);
        if (!IsValid(PlayerController))
            return false;

        // Use cached viewport size if available
        int32 ViewportWidth = CachedViewportWidth;
        int32 ViewportHeight = CachedViewportHeight;
        
        if (ViewportWidth == 0 || ViewportHeight == 0)
        {
            PlayerController.GetViewportSize(ViewportWidth, ViewportHeight);
        }

        const TArray<FVector>& PortalWorldCorners = PortalComp.GetMeshWorldCorners();
        TArray<FVector2D> ScreenSpaceCorners;
        ScreenSpaceCorners.Reserve(PortalWorldCorners.Num()); // Performance: pre-allocate
        
        // Project all corners to screen space
        for (const FVector& WorldCorner : PortalWorldCorners)
        {
            FVector2D ScreenPosition;
            if (PlayerController.ProjectWorldLocationToScreen(WorldCorner, ScreenPosition))
            {
                ScreenSpaceCorners.Add(ScreenPosition);
            }
        }

        if (ScreenSpaceCorners.IsEmpty())
        {
            return false;
        }

        const FVector2D ViewportMin(0, 0);
        const FVector2D ViewportMax(ViewportWidth, ViewportHeight);
        
        // Check if any portal edge intersects with viewport bounds
        for (int32 CornerIndex = 0; CornerIndex < ScreenSpaceCorners.Num(); ++CornerIndex)
        {
            const int32 NextCornerIndex = (CornerIndex + 1) % ScreenSpaceCorners.Num();
            const FVector2D& EdgeStart = ScreenSpaceCorners[CornerIndex];
            const FVector2D& EdgeEnd = ScreenSpaceCorners[NextCornerIndex];
            
            if (DoesLineIntersectRectangle(EdgeStart, EdgeEnd, ViewportMin, ViewportMax))
            {
                return true;
            }
        }

        // Check if viewport is completely inside the portal
        TArray<FVector2D> ViewportCorners;
        ViewportCorners.Reserve(4); 
        ViewportCorners.Add(FVector2D(0, 0));
        ViewportCorners.Add(FVector2D(ViewportWidth, 0));
        ViewportCorners.Add(FVector2D(ViewportWidth, ViewportHeight));
        ViewportCorners.Add(FVector2D(0, ViewportHeight));
        
        for (const FVector2D& ViewportCorner : ViewportCorners)
        {
            if (!IsPointInsideConvexPolygon(ViewportCorner, ScreenSpaceCorners))
            {
                return false;
            }
        }
        
        return true;
    }

    private void UpdatePortalCameraTransform()
    {
        UPortalComponent LinkedPortalComponent = PortalComp.GetLinkedPortal().PortalComponent;
        if (!IsValid(LinkedPortalComponent))
            return;
            
        const bool bIsCameraSynced = PortalComp.GetIsCameraSynced();

        const FTransform SourcePortalTransform = bIsCameraSynced ? PortalOwner.GetActorTransform() : PortalComp.GetLinkedPortal().GetActorTransform();
        const FTransform TargetPortalTransform = bIsCameraSynced ? PortalComp.GetLinkedPortal().GetActorTransform() : PortalOwner.GetActorTransform();

        const FVector CameraToPortalLocalPosition = SourcePortalTransform.InverseTransformPosition(PlayerCamera.GetWorldLocation());
        const FVector TargetCameraLocation = Portal::TransformLocalPointToWorldMirrored(CameraToPortalLocalPosition, TargetPortalTransform);
        
        const FQuat CameraToPortalLocalRotation = SourcePortalTransform.GetRotation().Inverse() * PlayerCamera.GetWorldRotation().Quaternion();
        const FRotator TargetCameraRotation = Portal::TransformLocalRotationToWorldFlipped(CameraToPortalLocalRotation, TargetPortalTransform.GetRotation(), TargetPortalTransform.Rotator().UpVector);

        PortalComp.PortalPlayerCamera.SetWorldLocationAndRotation(TargetCameraLocation, TargetCameraRotation);
    }
    
    private void HandleSceneCapture()
    {
        UPortalComponent LinkedPortalComponent = PortalComp.GetLinkedPortal().PortalComponent;
        if (!IsValid(LinkedPortalComponent))
        {
            Log(n"Error", f"Linked portal component is not valid for {GetName()}. Cannot handle scene capture.");
            return;
        }
            
        UpdateClippingPlane();       
        PortalComp.GetProjectedMeshWorldCorners().Empty();
        
        UpdateLinkedSceneCaptureRecursive(0, PortalComp.MaxPortalRecursion);
    }
    
    private void UpdateLinkedSceneCaptureRecursive(int32 CurrentRecursionLevel, int32 MaxRecursionLevels, FVector PreviousCameraLocation = FVector::ZeroVector, FRotator PreviousCameraRotation = FRotator::ZeroRotator)
    {
        UPortalComponent LinkedPortalComponent = PortalComp.GetLinkedPortal().PortalComponent;
        if (!IsValid(LinkedPortalComponent))
        {
            Log(n"Error", f"Linked portal component is not valid for {GetName()}. Cannot update linked scene capture.");
            return;
        }
                   
        FVector CurrentCameraLocation;
        FRotator CurrentCameraRotation;
        const FTransform& ThisPortalTransform = PortalOwner.GetActorTransform();
        const FTransform& LinkedPortalTransform = PortalComp.GetLinkedPortal().GetActorTransform();

        if (CurrentRecursionLevel == 0)
        {
            APlayerCameraManager PlayerCameraManager = Gameplay::GetPlayerCameraManager(0);
            if (!IsValid(PlayerCameraManager))
            {
                Log(n"Error", f"Player camera manager is not valid for {GetName()}. Cannot update linked scene capture.");
                return;
            }

            const FVector LocalCameraPosition = ThisPortalTransform.InverseTransformPosition(PlayerCameraManager.GetCameraLocation());
            CurrentCameraLocation = Portal::TransformLocalPointToWorldMirrored(LocalCameraPosition, LinkedPortalTransform);
            
            const FQuat LocalCameraRotation = ThisPortalTransform.GetRotation().Inverse() * PlayerCameraManager.GetCameraRotation().Quaternion();
            CurrentCameraRotation = Portal::TransformLocalRotationToWorldFlipped(LocalCameraRotation, LinkedPortalTransform.GetRotation(), LinkedPortalTransform.Rotator().UpVector);
        }
        else 
        {            
            const FVector LocalCameraPosition = ThisPortalTransform.InverseTransformPosition(PreviousCameraLocation);
            CurrentCameraLocation = Portal::TransformLocalPointToWorldMirrored(LocalCameraPosition, LinkedPortalTransform);
            
            const FQuat LocalCameraRotation = ThisPortalTransform.GetRotation().Inverse() * PreviousCameraRotation.Quaternion();
            CurrentCameraRotation = Portal::TransformLocalRotationToWorldFlipped(LocalCameraRotation, LinkedPortalTransform.GetRotation(), LinkedPortalTransform.Rotator().UpVector);
        }

        LinkedPortalComponent.PortalSceneCapture.SetWorldLocationAndRotation(CurrentCameraLocation, CurrentCameraRotation);

        // Final recursion - always render but hide portal to avoid recursion artifacts
        if (CurrentRecursionLevel == MaxRecursionLevels - 1)
        {
            PortalOwner.SetActorHiddenInGame(true);
            LinkedPortalComponent.PortalSceneCapture.CaptureScene();
            PortalOwner.SetActorHiddenInGame(false);
            return;
        }

        // Continue recursion if the portal is visible
        if (CanSeePortalTransformed(CurrentRecursionLevel))
        {
            UpdateLinkedSceneCaptureRecursive(CurrentRecursionLevel + 1, MaxRecursionLevels, CurrentCameraLocation, CurrentCameraRotation);
        }

        LinkedPortalComponent.PortalSceneCapture.SetWorldLocationAndRotation(CurrentCameraLocation, CurrentCameraRotation);
        LinkedPortalComponent.PortalSceneCapture.CaptureScene();
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
    
    private bool CanSeePortalTransformed(const int32 RecursionLevel)
    {
        UPortalComponent LinkedPortalComponent = PortalComp.GetLinkedPortal().PortalComponent;
        if (!IsValid(LinkedPortalComponent))
            return false;

        FProjectedPortalCorners OuterProjectedCorners;
        OuterProjectedCorners.Recursion = RecursionLevel;
        
        for (const FVector& WorldCorner : LinkedPortalComponent.GetMeshWorldCorners())
        {
            FVector2D ScreenPosition;
            if (SceneCapture::ProjectWorldToScreen(LinkedPortalComponent.PortalSceneCapture, WorldCorner, ScreenPosition, 10000.0f, true))
            {
                OuterProjectedCorners.ProjectedCorners.Add(ScreenPosition);
            }
        }
        
        PortalComp.GetProjectedMeshWorldCorners().Add(RecursionLevel, OuterProjectedCorners);
        
        TArray<FVector2D> InnerProjectedCorners;
        InnerProjectedCorners.Reserve(4); // Performance: pre-allocate
        
        for (const FVector& WorldCorner : PortalComp.GetMeshWorldCorners())
        {
            FVector2D ScreenPosition;
            if (SceneCapture::ProjectWorldToScreen(LinkedPortalComponent.PortalSceneCapture, WorldCorner, ScreenPosition))
            {
                InnerProjectedCorners.Add(ScreenPosition);
            }
        }

        // DrawDebugProjectedPolygon(ProjectedFrameCorners, FLinearColor::Red, 0.0f);
        // DrawDebugProjectedPolygon(OuterProjectedFrameCorners.ProjectedCorners, FLinearColor::Green, 5.0f);
        
        // Check if the inner portal is visible in all previous projections
        for (int32 ProjectionIndex = 0; ProjectionIndex < PortalComp.GetProjectedMeshWorldCorners().Num(); ProjectionIndex++)
        {
            if (!IsAnyPointInsideBounds(InnerProjectedCorners, PortalComp.GetProjectedMeshWorldCorners()[ProjectionIndex].ProjectedCorners))
                return false;
        }
    
        return true;
    }
    
    private bool IsAnyPointInsideBounds(const TArray<FVector2D>& PointsToTest, const TArray<FVector2D>& BoundaryPoints)
    {
        if (BoundaryPoints.IsEmpty())
            return false;

        for (const FVector2D& TestPoint : PointsToTest)
        {
            if (IsPointInsideConvexPolygon(TestPoint, BoundaryPoints))
                return true;
        }
        
        return false;
    }

    private bool DoesLineIntersectRectangle(const FVector2D& LineStart, const FVector2D& LineEnd, const FVector2D& RectangleMin, const FVector2D& RectangleMax)
    {
        // Check intersection with each rectangle edge
        if (DoLinesIntersect(LineStart, LineEnd, 
            FVector2D(RectangleMin.X, RectangleMin.Y), FVector2D(RectangleMax.X, RectangleMin.Y)))
        {
            return true;
        }
        
        if (DoLinesIntersect(LineStart, LineEnd, 
            FVector2D(RectangleMax.X, RectangleMin.Y), FVector2D(RectangleMax.X, RectangleMax.Y)))
        {
            return true;
        }
        
        if (DoLinesIntersect(LineStart, LineEnd, 
            FVector2D(RectangleMax.X, RectangleMax.Y), FVector2D(RectangleMin.X, RectangleMax.Y)))
        {
            return true;
        }
        
        if (DoLinesIntersect(LineStart, LineEnd, 
            FVector2D(RectangleMin.X, RectangleMax.Y), FVector2D(RectangleMin.X, RectangleMin.Y)))
        {
            return true;
        }
        
        return false;
    }

    private bool DoLinesIntersect(const FVector2D& FirstLineStart, const FVector2D& FirstLineEnd, const FVector2D& SecondLineStart, const FVector2D& SecondLineEnd)
    {
        const FVector2D FirstLineDirection = FirstLineEnd - FirstLineStart;
        const FVector2D SecondLineDirection = SecondLineEnd - SecondLineStart;
        const FVector2D StartPointDifference = SecondLineStart - FirstLineStart;
        
        const float DirectionsCrossProduct = FirstLineDirection.CrossProduct(SecondLineDirection);
        
        // Lines are parallel
        if (Math::IsNearlyZero(DirectionsCrossProduct))
            return false;
        
        const float FirstLine = StartPointDifference.CrossProduct(SecondLineDirection) / DirectionsCrossProduct;
        const float SecondLine = StartPointDifference.CrossProduct(FirstLineDirection) / DirectionsCrossProduct;
        
        return (FirstLine >= 0.0f && FirstLine <= 1.0f && 
                SecondLine >= 0.0f && SecondLine <= 1.0f);
    }
   
    private bool IsPointInsideConvexPolygon(const FVector2D& TestPoint, const TArray<FVector2D>& PolygonVertices)
    {
        if (PolygonVertices.Num() < 3)
            return false;

        bool bHasPositiveCrossProduct = false;
        bool bHasNegativeCrossProduct = false;

        for (int32 VertexIndex = 0; VertexIndex < PolygonVertices.Num(); ++VertexIndex)
        {
            const FVector2D& CurrentVertex = PolygonVertices[VertexIndex];
            const FVector2D& NextVertex = PolygonVertices[(VertexIndex + 1) % PolygonVertices.Num()];

            const FVector2D EdgeDirection = NextVertex - CurrentVertex;
            const FVector2D PointDirection = TestPoint - CurrentVertex;

            const float CrossProductResult = EdgeDirection.CrossProduct(PointDirection);

            if (CrossProductResult > KINDA_SMALL_NUMBER)
            {
                bHasPositiveCrossProduct = true;
            }
            else if (CrossProductResult < -KINDA_SMALL_NUMBER)
            {
                bHasNegativeCrossProduct = true;
            }

            if (bHasPositiveCrossProduct && bHasNegativeCrossProduct)
                return false;
        }

        return true;
    }

    // --- Debug Methods ---

    private void DrawDebugProjectedPolygon(const TArray<FVector2D>& ProjectedCorners, FLinearColor DebugColor, float ZAxisOffset = 0.0f, float DebugDuration = 0.0f, float LineThickness = 2.0f)
    {
        if (ProjectedCorners.Num() < 3)
            return;
            
        TArray<FVector> WorldDebugPoints;
        WorldDebugPoints.Reserve(ProjectedCorners.Num());
        
        for (const FVector2D& ScreenPosition : ProjectedCorners)
        {
            const FVector WorldPosition = FVector(
                ZAxisOffset,
                (ScreenPosition.X - 0.5f),
                (ScreenPosition.Y - 0.5f)
            );
            
            WorldDebugPoints.Add(WorldPosition);
        }
        
        for (int32 PointIndex = 0; PointIndex < WorldDebugPoints.Num(); ++PointIndex)
        {
            const int32 NextPointIndex = (PointIndex + 1) % WorldDebugPoints.Num();
            System::DrawDebugLine(WorldDebugPoints[PointIndex], WorldDebugPoints[NextPointIndex], DebugColor, DebugDuration, LineThickness);
        }
    }
}
