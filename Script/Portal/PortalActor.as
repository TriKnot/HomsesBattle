class APortalActor : AActor
{
    // Components
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
    USceneCaptureComponent2D PortalCamera;
    default PortalCamera.bCaptureEveryFrame = false;
    default PortalCamera.bCaptureOnMovement = false;
    default PortalCamera.bAlwaysPersistRenderingState = true;
    default PortalCamera.CompositeMode = ESceneCaptureCompositeMode::SCCM_Composite;

    UPROPERTY(DefaultComponent, Attach = Root)
    UCameraComponent PortalPlayerCamera;

    // Material
    UPROPERTY(EditDefaultsOnly)
    UMaterialInterface PortalMaterialBase;

    // State

    private APortalActor LinkedPortal;
    private UMaterialInstanceDynamic PortalMaterialInstance;
    private TMap<AActor, FVector> TrackedActors;
    private UCameraComponent PlayerCamera;
    TArray<FVector> MeshWorldCorners;

    bool bCameraSynced = true;
    bool bCameraTransitionActive = false;
    float NearClipDistance = 10.0f;

    default SetTickGroup(ETickingGroup::TG_LastDemotable);

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PortalMaterialInstance = PortalFrameMesh.CreateDynamicMaterialInstance(0, PortalMaterialBase);

        PortalCamera.TextureTarget = Cast<UTextureRenderTarget2D>(NewObject(this, UTextureRenderTarget2D::StaticClass()));
        PortalCamera.TextureTarget.InitAutoFormat(1024, 1024);
        PortalMaterialInstance.SetTextureParameterValue(n"PortalTexture", PortalCamera.TextureTarget);
     
        UPortalSubsystem::Get().RegisterPortal(this);

        CalculateMeshWorldCorners();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!EnsureCamera())
            return;

        if(!WasRecentlyRendered() || !CanSeePortal(PlayerCamera, this))
            return;

        HandleTeleportation();
        UpdatePortalCamera();
        HandleSceneCapture();

        if (bCameraTransitionActive)
            HandleCameraTransition();
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

        APlayerController Controller = Cast<APlayerController>(TeleportedPawn.GetController());
        if (!IsValid(Controller))
            return;

        SetCameraSynced(false);
        Controller.SetViewTargetWithBlend(LinkedPortal);
        bCameraTransitionActive = true;
    }

    void HandleCameraTransition()
    {
        APlayerController Controller = Gameplay::GetPlayerController(0);

        if (IsCameraClippingPortalPlane())
        {
            SetCameraSynced(true);
            Controller.SetViewTargetWithBlend(PlayerCamera.Owner);
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
        float Distance = (PortalFrameMesh.GetWorldLocation() - LinkedPortal.PortalPlayerCamera.GetWorldLocation()).DotProduct(GetActorForwardVector());
        return Math::Abs(Distance) <= NearClipDistance * 2.0f;
    }
    
    FVector ComputeLinkedCameraLocation(FVector PreviousLocation)
    {
        FTransform FromTransform = GetActorTransform();
        FVector Scale = FromTransform.GetScale3D();
        Scale.X *= -1;
        Scale.Y *= -1;
        
        FTransform MirrorTransform(FromTransform.Rotation, FromTransform.Location, Scale);
        
        FVector LocalCameraPos = MirrorTransform.InverseTransformPosition(PreviousLocation);

        return LinkedPortal.GetActorTransform().TransformPosition(LocalCameraPos);
    }

    FRotator ComputeLinkedCameraRotation(FRotator PreviousRotation)
    {
        FVector Forward = PreviousRotation.GetForwardVector();
        FVector Right = PreviousRotation.GetRightVector();
        FVector Up = PreviousRotation.GetUpVector();

        TArray<FVector> LocalAxes;
        LocalAxes.Add(Forward);
        LocalAxes.Add(Right);
        LocalAxes.Add(Up);

        TArray<FVector> TransformedAxes;
        TransformedAxes.SetNum(LocalAxes.Num());

        FTransform FromTransform = GetActorTransform();
        FTransform LinkedTransform = LinkedPortal.GetActorTransform();

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
        PortalCamera.bEnableClipPlane = true;
        PortalCamera.ClipPlaneBase = PortalFrameMesh.GetWorldLocation() + GetActorForwardVector() * -3.0f;
        PortalCamera.ClipPlaneNormal = GetActorForwardVector();
    }

    void UpdateResolution()
    {
        APlayerController Controller = Gameplay::GetPlayerController(0);
        if (!IsValid(Controller))
            return;

        int32 ViewportX = 0, ViewportY = 0;
        Controller.GetViewportSize(ViewportX, ViewportY);
        
        if (PortalCamera.TextureTarget.SizeX != ViewportX || PortalCamera.TextureTarget.SizeY != ViewportY)
        {
            PortalCamera.TextureTarget.ResizeTarget(uint32(ViewportX), uint32(ViewportY));
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

        FVector NewCaptureLocation = ComputeLinkedCameraLocation(PlayerCamera.GetWorldLocation());
        FRotator NewCaptureRotation = ComputeLinkedCameraRotation(PlayerCamera.GetWorldRotation());
        LinkedPortal.PortalCamera.SetWorldLocationAndRotation(NewCaptureLocation, NewCaptureRotation);
    }

    void UpdatePortalCamera()
    {
        FVector Location = ComputeLinkedCameraLocation(PlayerCamera.GetWorldLocation());
        FRotator Rotation = ComputeLinkedCameraRotation(PlayerCamera.GetWorldRotation());

        PortalPlayerCamera.SetWorldLocationAndRotation(Location, Rotation);
    }

    void HandleSceneCapture()
    {
        UpdateResolution();
        UpdateClippingPlane();

        FVector TempLocation = FVector::ZeroVector;
        FRotator TempRotation = FRotator::ZeroRotator;
        int CurrentRecursion = 0;
        UpdateLinkedSceneCaptureRecursive(TempLocation, TempRotation, CurrentRecursion, 3);
    }

    void UpdateLinkedSceneCaptureRecursive(FVector OldLocation, FRotator OldRotation, int CurrentRecursion, int MaxRecursions = 3)
    {
        if(CurrentRecursion == 0)
        {
            Rendering::ClearRenderTarget2D(LinkedPortal.PortalCamera.TextureTarget);

            UCameraComponent Camera = bCameraSynced ? PlayerCamera : LinkedPortal.PortalPlayerCamera;

            if(!IsValid(Camera))
                return;

            FVector TempLocation = ComputeLinkedCameraLocation(Camera.GetWorldLocation());
            FRotator TempRotation = ComputeLinkedCameraRotation(Camera.GetWorldRotation());
            
            UpdateLinkedSceneCaptureRecursive(TempLocation, TempRotation, CurrentRecursion + 1, MaxRecursions);

            LinkedPortal.PortalCamera.SetWorldLocationAndRotation(TempLocation, TempRotation);
            LinkedPortal.PortalCamera.CaptureScene();
        }
        else if(CurrentRecursion < MaxRecursions)
        {            
            FVector TempLocation = ComputeLinkedCameraLocation(OldLocation);
            FRotator TempRotation = ComputeLinkedCameraRotation(OldRotation);

            UpdateLinkedSceneCaptureRecursive(TempLocation, TempRotation, CurrentRecursion + 1, MaxRecursions);

            LinkedPortal.PortalCamera.SetWorldLocationAndRotation(TempLocation, TempRotation);
            LinkedPortal.PortalCamera.CaptureScene();
        }
        else
        {
            FVector Location = ComputeLinkedCameraLocation(OldLocation);
            FRotator Rotation = ComputeLinkedCameraRotation(OldRotation);

            LinkedPortal.PortalCamera.SetWorldLocationAndRotation(Location, Rotation);
            PortalFrameMesh.SetVisibility(false);
            LinkedPortal.PortalCamera.CaptureScene();
            PortalFrameMesh.SetVisibility(true);
        }
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

        for (const FVector& Point : Portal.MeshWorldCorners)
        {
            FVector2D ScreenPos;
            if (PlayerController.ProjectWorldLocationToScreen(Point, ScreenPos))
            {
                if(ScreenPos.X > 0 && ScreenPos.X < ViewportX 
                && ScreenPos.Y > 0 && ScreenPos.Y < ViewportY)
                    return true;
            }        
        }
        return false;
    }

    void CalculateMeshWorldCorners()
    {
        FVector LocalMin, LocalMax;
        PortalFrameMesh.GetLocalBounds(LocalMin, LocalMax);

        FTransform MeshTransform = PortalFrameMesh.GetWorldTransform();

        MeshWorldCorners.Add(MeshTransform.TransformPosition(FVector(LocalMin.X, LocalMin.Y, 0)));
        MeshWorldCorners.Add(MeshTransform.TransformPosition(FVector(LocalMax.X, LocalMin.Y, 0)));
        MeshWorldCorners.Add(MeshTransform.TransformPosition(FVector(LocalMax.X, LocalMax.Y, 0)));
        MeshWorldCorners.Add(MeshTransform.TransformPosition(FVector(LocalMin.X, LocalMax.Y, 0)));
    }

}