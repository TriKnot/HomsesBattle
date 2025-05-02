class APortalActor : AActor
{
    // --- Components ---
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PortalFrameMesh;
    default PortalFrameMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
    default PortalFrameMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_GameTraceChannel1, ECollisionResponse::ECR_Block);

    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent TeleportTriggerVolume;
    default TeleportTriggerVolume.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent PlayerNearbyDetectionBox;
    default PlayerNearbyDetectionBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
    default PlayerNearbyDetectionBox.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerNearbyOverlapBegin");
    default PlayerNearbyDetectionBox.OnComponentEndOverlap.AddUFunction(this, n"OnPlayerNearbyOverlapEnd");
    
    UPROPERTY(DefaultComponent, Attach = Root)
    USceneCaptureComponent2D PortalSceneCapture;
    default PortalSceneCapture.bCaptureEveryFrame = false;
    default PortalSceneCapture.bCaptureOnMovement = false;
    default PortalSceneCapture.bAlwaysPersistRenderingState = true;
    default PortalSceneCapture.CompositeMode = ESceneCaptureCompositeMode::SCCM_Composite;

    UPROPERTY(DefaultComponent, Attach = Root)
    UCameraComponent PortalPlayerCamera;

    // --- Properties ---
    UPROPERTY(EditDefaultsOnly, Category = "Portal")
    UMaterialInterface PortalMaterialBase;
    // Maximum number of recursions for the portal rendering through the linked portal
    UPROPERTY(EditDefaultsOnly, Category = "Portal")
    int MaxPortalRecursion = 3;    
    // Distance from the portal plane to the camera for clipping
    UPROPERTY(EditDefaultsOnly, Category = "Portal")
    float NearClipDistance = 10.0f; 

    // --- State ---
    private APortalActor LinkedPortal;
    private UMaterialInstanceDynamic PortalMaterialInstance;
    private TMap<AActor, FVector> TrackedActors;
    private UCameraComponent PlayerCamera;
    TArray<FVector> MeshWorldCorners;
    TMap<int, FProjectedPortalCorners> ProjectedMeshWorldCorners;
    bool bCameraSynced = true;
    bool bCameraTransitionActive = false;


    default SetTickGroup(ETickingGroup::TG_LastDemotable);

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Create Dynamic Material Instance for the portal frame mesh
        if(!IsValid(PortalMaterialBase))
        {
            Log(n"Error", "PortalActor::BeginPlay: PortalMaterialBase is not set. Please assign a material to the portal.");
            return;
        }
        PortalMaterialInstance = PortalFrameMesh.CreateDynamicMaterialInstance(0, PortalMaterialBase);

        // Create the portal camera texture target
        PortalSceneCapture.TextureTarget = Cast<UTextureRenderTarget2D>(NewObject(this, UTextureRenderTarget2D::StaticClass()));
        PortalSceneCapture.TextureTarget.InitAutoFormat(1024, 1024);
        PortalMaterialInstance.SetTextureParameterValue(n"PortalTexture", PortalSceneCapture.TextureTarget);
     
        // Register the portal with the UPortalSubsystem
        UPortalSubsystem::Get().RegisterPortal(this);

        // Calculate where the portal frame corners are in world space
        CalculateMeshWorldCorners();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // Ensure the camera is valid
        if (!EnsureCamera()) 
            return;

        // Check if the portal is visible
        if(bCameraSynced && (!WasRecentlyRendered() || !CanSeePortal(PlayerCamera, this)))
            return;

        // Core Portal Logic
        HandleTeleportation();
        
        // Handle camera transition after teleportation
        if (bCameraTransitionActive)
            HandleCameraTransition();

        UpdatePortalCamera();
        HandleSceneCapture();

    }

    void SetLinkedPortal(APortalActor OtherPortal)
    {
        LinkedPortal = OtherPortal;
        if(IsValid(LinkedPortal))
            PortalFrameMesh.SetMaterial(0, LinkedPortal.PortalMaterialInstance);
    }
    
    bool EnsureCamera()
    {
        if (!IsValid(PlayerCamera))
        {
            PlayerCamera = UCameraComponent::Get(Gameplay::GetPlayerCharacter(0));
            if (!IsValid(PlayerCamera))
                return false;

            PortalPlayerCamera.ProjectionMode = PlayerCamera.ProjectionMode;
            PortalPlayerCamera.FieldOfView = PlayerCamera.FieldOfView;
            PortalPlayerCamera.bOverrideAspectRatioAxisConstraint = PlayerCamera.bOverrideAspectRatioAxisConstraint;
            PortalPlayerCamera.AspectRatioAxisConstraint = PlayerCamera.AspectRatioAxisConstraint;

            UpdateResolution();
            UpdateClippingPlane();
        }
        return true;
    }

    void HandleTeleportation()
    {
        TArray<AActor> OverlappingActors;
        TeleportTriggerVolume.GetOverlappingActors(OverlappingActors);
        OverlappingActors.Remove(this);

        for (AActor OverlappingActor : OverlappingActors)
        {
            if(!IsValid(OverlappingActor))
                continue;
            
            if(ShouldTeleport(OverlappingActor))
            {
                TeleportActor(OverlappingActor);
                InitiateCameraTransition(OverlappingActor);
            }
        }
    }

    bool ShouldTeleport(AActor Actor)
    {
        FVector CurrentLocation = Actor.GetActorLocation();

        if(TrackedActors.Contains(Actor))
        {
            FVector PreviousLocation = TrackedActors[Actor];
            bool HasCrossed = IsBehindPortal(CurrentLocation) && !IsBehindPortal(PreviousLocation);
            TrackedActors[Actor] = CurrentLocation;
            return HasCrossed; 
        }

        TrackedActors.Add(Actor, CurrentLocation);
        return false; 
    }

    bool IsBehindPortal(const FVector& Point)
    {
        FVector PortalToPoint = (Point - PortalFrameMesh.GetWorldLocation()).GetSafeNormal();
        return GetActorForwardVector().DotProduct(PortalToPoint) < -KINDA_SMALL_NUMBER;
    }

    void InitiateCameraTransition(AActor Actor)
    {
        APawn TeleportedPawn = Cast<APawn>(Actor);
        if (!IsValid(TeleportedPawn))
            return;

        SetCameraSynced(false);
        Gameplay::GetPlayerController(0).SetViewTargetWithBlend(this);
        bCameraTransitionActive = true;
    }

    void HandleCameraTransition()
    {
        if (IsCameraClippingPortalPlane())
        {
            SetCameraSynced(true);
            Gameplay::GetPlayerController(0).SetViewTargetWithBlend(Gameplay::GetPlayerCharacter(0));
            bCameraTransitionActive = false;
        }
    }
    
    void SetCameraSynced(bool bNewCameraSynced)
    {
        bCameraSynced = bNewCameraSynced;
        LinkedPortal.bCameraSynced = bNewCameraSynced;
    }

    bool IsCameraClippingPortalPlane() const 
    {
        float Distance = (PortalFrameMesh.GetWorldLocation() - PortalPlayerCamera.GetWorldLocation()).DotProduct(GetActorForwardVector());
        return Math::Abs(Distance) <= NearClipDistance * 2.0f;
    }
        
    FVector ComputeLinkedCameraLocation(FTransform FromTransform, FTransform LinkedTransform, FVector OldLocation)
    {
        FVector Scale = FromTransform.GetScale3D();
        Scale.X *= -1;
        Scale.Y *= -1;
        FTransform MirrorTransform(FromTransform.Rotation, FromTransform.Location, Scale);
        
        FVector LocalCameraPos = MirrorTransform.InverseTransformPosition(OldLocation);

        return LinkedTransform.TransformPosition(LocalCameraPos);
    }

    FRotator ComputeLinkedCameraRotation(FTransform FromTransform, FTransform LinkedTransform, FRotator OldRotation)
    {
        FVector CameraForward = OldRotation.GetForwardVector();
        FVector CameraRight = OldRotation.GetRightVector();
        FVector CameraUp = OldRotation.GetUpVector();

        TArray<FVector> LocalAxes;
        LocalAxes.Add(CameraForward);
        LocalAxes.Add(CameraRight);
        LocalAxes.Add(CameraUp);

        TArray<FVector> TransformedAxes;
        TransformedAxes.SetNum(LocalAxes.Num());

        for (int32 i = 0; i < LocalAxes.Num(); i++)
        {
            FVector LocalAxis = FromTransform.InverseTransformVectorNoScale(LocalAxes[i]);
            FVector MirroredAxis = MirrorVectorXY(LocalAxis);
            TransformedAxes[i] = LinkedTransform.TransformVectorNoScale(MirroredAxis);
        }

        return FRotator::MakeFromAxes(TransformedAxes[0], TransformedAxes[1], TransformedAxes[2]);
    }

    void UpdateClippingPlane()
    {
        PortalSceneCapture.bEnableClipPlane = true;
        PortalSceneCapture.ClipPlaneBase = PortalFrameMesh.GetWorldLocation() + GetActorForwardVector() * -3.0f;
        PortalSceneCapture.ClipPlaneNormal = GetActorForwardVector();
    }

    void UpdateResolution()
    {
        APlayerController Controller = Gameplay::GetPlayerController(0);
        if (!IsValid(Controller))
            return;

        int32 ViewportX = 0, ViewportY = 0;
        Controller.GetViewportSize(ViewportX, ViewportY);
        
        if (PortalSceneCapture.TextureTarget.SizeX != ViewportX || PortalSceneCapture.TextureTarget.SizeY != ViewportY)
        {
            PortalSceneCapture.TextureTarget.ResizeTarget(uint32(ViewportX), uint32(ViewportY));
        }
    }

    FVector MirrorVectorXY(const FVector& Vector) const
    {
        FVector MirroredVec = Vector.MirrorByVector(FVector(1, 0, 0)); 
        MirroredVec = MirroredVec.MirrorByVector(FVector(0, 1, 0));
        return MirroredVec;
    }

    UFUNCTION()
    void OnPlayerNearbyOverlapBegin(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
    {
        if(!IsValid(OtherActor))
            return;

        TrackedActors.Add(OtherActor, OtherActor.GetActorLocation()); 
    }

    UFUNCTION()
    void OnPlayerNearbyOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
    {
        if(!IsValid(OtherActor))
            return;

        TrackedActors.Remove(OtherActor); 
    }

    void TeleportActor(AActor TargetActor)
    {        
        FVector NewLocation = ComputeTeleportedLocation(TargetActor, LinkedPortal);
        FRotator NewRotation = ComputeTeleportedRotation(TargetActor, LinkedPortal);

        TargetActor.SetActorLocationAndRotation(NewLocation, NewRotation);

        APawn Pawn = Cast<APawn>(TargetActor);
        if (IsValid(Pawn) && IsValid(Pawn.GetController()))
        {
            AController Controller = Pawn.GetController();
            if (IsValid(Controller))
            {
                FRotator ControllerRotation = Controller.ActorRotation;
                NewRotation.Pitch = ControllerRotation.Pitch;
                NewRotation.Roll = ControllerRotation.Roll;

                Controller.SetControlRotation(NewRotation);
            }
        }

        FVector OldVelocity = TargetActor.GetVelocity();

        UCharacterMovementComponent CharMove = UCharacterMovementComponent::Get(TargetActor);
        if (IsValid(CharMove))
        {
            CharMove.Velocity = ComputeTeleportedVelocity(OldVelocity, LinkedPortal);
            return;
        }

        if (HasPhysicsEnabled(TargetActor))
        {
            UPrimitiveComponent PrimComp = Cast<UPrimitiveComponent>(TargetActor.GetRootComponent());
            if (IsValid(PrimComp))
            {
                if (IsValid(PrimComp) && PrimComp.IsSimulatingPhysics())
                {
                    PrimComp.SetPhysicsLinearVelocity(ComputeTeleportedVelocity(OldVelocity, LinkedPortal));
                    return;
                }
            }
        }
        UProjectileMoveComponent ProjMove = UProjectileMoveComponent::Get(TargetActor);
        if (IsValid(ProjMove))

        {
            ProjMove.ProjectileVelocity = ComputeTeleportedVelocity(ProjMove.ProjectileVelocity, LinkedPortal);
        }
    }
    FVector ComputeTeleportedLocation(AActor TargetActor, APortalActor TargetPortal)
    {
        if (!IsValid(TargetActor) || !IsValid(TargetPortal))
        {
            return TargetActor.GetActorLocation();
        }

        FVector LocalOffset = GetActorTransform().InverseTransformPosition(TargetActor.GetActorLocation());
        LocalOffset.X = -LocalOffset.X;
        LocalOffset.Y = -LocalOffset.Y;

        return TargetPortal.GetActorTransform().TransformPosition(LocalOffset);
    }

    FRotator ComputeTeleportedRotation(AActor Actor, APortalActor TargetPortal)
    {
        if (!IsValid(Actor) || !IsValid(TargetPortal))
        {
            return Actor.GetActorRotation();
        }

        FQuat Quat = Actor.GetActorQuat();
        FQuat CurrentPortalQuat = GetActorQuat();
        FQuat LinkedPortalQuat = TargetPortal.GetActorQuat();

        FQuat RelativeQuat = CurrentPortalQuat.Inverse() * Quat;

        FQuat FlipQuat = FQuat(GetActorUpVector(), PI);
        FQuat MirroredRelativeQuat = FlipQuat * RelativeQuat;

        FQuat NewWorldQuat = LinkedPortalQuat * MirroredRelativeQuat;
        return NewWorldQuat.Rotator();
    }

    FVector ComputeTeleportedVelocity(FVector OldVelocity, APortalActor TargetPortal)
    {
        if (!IsValid(TargetPortal))
        {
            return OldVelocity;
        }

        FQuat CurrentPortalQuat = GetActorQuat();
        FQuat LinkedPortalQuat  = TargetPortal.GetActorQuat();

        FVector LocalVelocity = CurrentPortalQuat.Inverse().RotateVector(OldVelocity);

        FQuat FlipQuat = FQuat(GetActorUpVector(), PI);
        FVector MirroredLocalVelocity = FlipQuat.RotateVector(LocalVelocity);

        return LinkedPortalQuat.RotateVector(MirroredLocalVelocity);
    }

    bool HasPhysicsEnabled(AActor Actor)
    {
        TArray<UPrimitiveComponent> Components;
        Actor.GetComponentsByClass(UPrimitiveComponent::StaticClass(), Components);
        for (UPrimitiveComponent Component : Components)
        {
            if (Component.IsSimulatingPhysics())
            {
                return true;
            }
        }
        return false;
    }

    void TransitionCamera(AActor OverlappingActor)
    {
        APawn TeleportedPawn = Cast<APawn>(OverlappingActor);
        if (!IsValid(TeleportedPawn))
            return;

        APlayerController Controller = Cast<APlayerController>(TeleportedPawn.GetController());
        if (!IsValid(Controller))
            return;

        SetCameraSynced(false);
        Controller.SetViewTargetWithBlend(this);

        FVector NewCaptureLocation = ComputeLinkedCameraLocation(GetActorTransform(), LinkedPortal.GetActorTransform(), PlayerCamera.GetWorldLocation());
        FRotator NewCaptureRotation = ComputeLinkedCameraRotation(GetActorTransform(), LinkedPortal.GetActorTransform(), PlayerCamera.GetWorldRotation());
        LinkedPortal.PortalSceneCapture.SetWorldLocationAndRotation(NewCaptureLocation, NewCaptureRotation);
    }

    void UpdatePortalCamera()
    {
        FVector Location;
        FRotator Rotation;
        if(bCameraSynced)
        {
            Location = ComputeLinkedCameraLocation(GetActorTransform(), LinkedPortal.GetActorTransform(), PlayerCamera.GetWorldLocation());
            Rotation = ComputeLinkedCameraRotation(GetActorTransform(), LinkedPortal.GetActorTransform(), PlayerCamera.GetWorldRotation());
        }
        else
        {
            Location = ComputeLinkedCameraLocation(LinkedPortal.GetActorTransform(), GetActorTransform(), PlayerCamera.GetWorldLocation());
            Rotation = ComputeLinkedCameraRotation(LinkedPortal.GetActorTransform(), GetActorTransform(), PlayerCamera.GetWorldRotation());
        }

        PortalPlayerCamera.SetWorldLocationAndRotation(Location, Rotation);
    }

    void HandleSceneCapture()
    {
        UpdateResolution();
        UpdateClippingPlane();

        FVector TempLocation = FVector::ZeroVector;
        FRotator TempRotation = FRotator::ZeroRotator;
        int CurrentRecursion = 0;
        UpdateLinkedSceneCaptureRecursive(TempLocation, TempRotation, CurrentRecursion, 7);
    }

    void UpdateLinkedSceneCaptureRecursive(FVector OldLocation, FRotator OldRotation, int CurrentRecursion, int MaxRecursions = 3)
    {
        UCameraComponent Camera = bCameraSynced ? PlayerCamera : PortalPlayerCamera;
        if(CurrentRecursion == 0)
        {
            Rendering::ClearRenderTarget2D(LinkedPortal.PortalSceneCapture.TextureTarget);


            if(!IsValid(Camera))
                return;

            FVector TempLocation = ComputeLinkedCameraLocation(GetActorTransform(), LinkedPortal.GetActorTransform(), Camera.GetWorldLocation());
            FRotator TempRotation = ComputeLinkedCameraRotation(GetActorTransform(), LinkedPortal.GetActorTransform(), Camera.GetWorldRotation());
            LinkedPortal.PortalSceneCapture.SetWorldLocationAndRotation(TempLocation, TempRotation); // Set Camera location before checking visibility

            // Continue recursion if the portal is visible
            if(CanSeePortalTransformed(this, CurrentRecursion))
            {
                UpdateLinkedSceneCaptureRecursive(TempLocation, TempRotation, CurrentRecursion + 1, MaxRecursions);
            }

            LinkedPortal.PortalSceneCapture.SetWorldLocationAndRotation(TempLocation, TempRotation);
            LinkedPortal.PortalSceneCapture.CaptureScene();
        }
        else if(CurrentRecursion < MaxRecursions)
        {            
            FVector TempLocation = ComputeLinkedCameraLocation(GetActorTransform(), LinkedPortal.GetActorTransform(), OldLocation);
            FRotator TempRotation = ComputeLinkedCameraRotation(GetActorTransform(), LinkedPortal.GetActorTransform(), OldRotation);
            LinkedPortal.PortalSceneCapture.SetWorldLocationAndRotation(TempLocation, TempRotation); // Set Camera location before checking visibility

            // Continue recursion if the portal is visible
            if(CanSeePortalTransformed(this, CurrentRecursion))
            {
                UpdateLinkedSceneCaptureRecursive(TempLocation, TempRotation, CurrentRecursion + 1, MaxRecursions);
            }

            LinkedPortal.PortalSceneCapture.SetWorldLocationAndRotation(TempLocation, TempRotation);
            LinkedPortal.PortalSceneCapture.CaptureScene();
        }
        else
        {
            // Final recursion, always render but hide portal to not have a blank frame
            FVector Location = ComputeLinkedCameraLocation(GetActorTransform(), LinkedPortal.GetActorTransform(), OldLocation);
            FRotator Rotation = ComputeLinkedCameraRotation(GetActorTransform(), LinkedPortal.GetActorTransform(), OldRotation);
            LinkedPortal.PortalSceneCapture.SetWorldLocationAndRotation(Location, Rotation);
            SetActorHiddenInGame(true);
            LinkedPortal.PortalSceneCapture.CaptureScene();
            SetActorHiddenInGame(false);
        }
    }

    bool CanSeePortalTransformed(const APortalActor Portal, const int Recursion)
    {
        // --- Input Validation ---
        if (!IsValid(Portal))
            return false;

        // Clear on first recursion
        if(Recursion == 0)
        {
            ProjectedMeshWorldCorners.Empty();
        }

        // --- Outer portal corners ---
        FProjectedPortalCorners OuterProjectedFrameCorners;
        OuterProjectedFrameCorners.Recursion = Recursion;
        for(const FVector& Corner : LinkedPortal.MeshWorldCorners)
        {
            FVector2D ScreenPosition;
            SceneCapture::ProjectWorldToScreen(LinkedPortal.PortalSceneCapture, Corner, ScreenPosition, 10000.0f, true);
            OuterProjectedFrameCorners.ProjectedCorners.Add(ScreenPosition);
            
        }
        ProjectedMeshWorldCorners.Add(Recursion, OuterProjectedFrameCorners);
        // --- End outer portal corners ---


        // --- Inner portal corners ---
        TArray<FVector2D> ProjectedFrameCorners;
        for(const FVector& Corner : Portal.MeshWorldCorners)
        {
            FVector2D ScreenPosition;
            if (SceneCapture::ProjectWorldToScreen(LinkedPortal.PortalSceneCapture, Corner, ScreenPosition))
            {
                ProjectedFrameCorners.Add(ScreenPosition);
            }
        }
        // --- End inner portal corners ---

        // Check if the projected frame corners are inside the outer portal starting with the first one outer frame.
        // The inner frame has to be visible from all previous frames to be considered visible.
        for(int i = 0; i < ProjectedMeshWorldCorners.Num(); i++)
        {
            if(!IsAnyPointInsideBounds(ProjectedFrameCorners, ProjectedMeshWorldCorners[i].ProjectedCorners, i))
                return false;
        }

        return true;
    }

    bool IsAnyPointInsideBounds(const TArray<FVector2D>& PointsToCheck, const TArray<FVector2D>& BoundaryPoints, int offset)
    {
        if (BoundaryPoints.IsEmpty())
        {
            return false;
        }

        // If any of the points to check are inside the boundary points, return true
        for (const FVector2D& PointToCheck : PointsToCheck)
        {
            if (IsPointInsideConvexPolygon(PointToCheck, BoundaryPoints))
                return true;
        }
    

        return false; // No points were found inside the bounds
    }

    // Check if a point is inside a convex polygon using the cross product method
    // The order of the vertices should be counter-clockwise (CCW) for this to work correctly.
    bool IsPointInsideConvexPolygon(const FVector2D& Point, const TArray<FVector2D>& PolygonVertices)
    {
        if (PolygonVertices.Num() < 3)
        {
            return false;
        }

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
            {
                return false;
            }
        }

        // If we went through all edges and the point was never strictly outside then it's inside or on the boundary.
        return true;
    }

    bool CanSeePortal(USceneComponent ViewerComponent, APortalActor Portal)
    {
        if(!IsValid(ViewerComponent))
            return false;

        if(IsBehindPortal(ViewerComponent.GetWorldLocation()))
            return false;

        APlayerController PlayerController = Gameplay::GetPlayerController(0);
        if (!IsValid(PlayerController))
            return false;

        int ViewportX = 0;
        int ViewportY = 0;
        PlayerController.GetViewportSize(ViewportX, ViewportY);

        bool bIsVisible = false;
        for (const FVector& Corner : Portal.MeshWorldCorners)
        {
            FVector2D ScreenPos;
            if (PlayerController.ProjectWorldLocationToScreen(Corner, ScreenPos))
            {
                if (ScreenPos.X > 0 && ScreenPos.X < ViewportX &&
                    ScreenPos.Y > 0 && ScreenPos.Y < ViewportY)
                {
                    return true; // At least one corner is visible
                }
            }
        }

        return false; // No corners are visible
    }

    void CalculateMeshWorldCorners()
    {
        FVector LocalMin, LocalMax;
        PortalFrameMesh.GetLocalBounds(LocalMin, LocalMax);

        FTransform MeshTransform = PortalFrameMesh.GetWorldTransform();

        MeshWorldCorners.Empty();
        MeshWorldCorners.Add(MeshTransform.TransformPosition(FVector(LocalMin.X, LocalMin.Y, 0)));
        MeshWorldCorners.Add(MeshTransform.TransformPosition(FVector(LocalMax.X, LocalMin.Y, 0)));
        MeshWorldCorners.Add(MeshTransform.TransformPosition(FVector(LocalMax.X, LocalMax.Y, 0)));
        MeshWorldCorners.Add(MeshTransform.TransformPosition(FVector(LocalMin.X, LocalMax.Y, 0)));
    }
    
}


struct FProjectedPortalCorners
{
    int Recursion;
    TArray<FVector2D> ProjectedCorners;
}

