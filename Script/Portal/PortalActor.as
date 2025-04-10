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
    USceneCaptureComponent2D SceneCapture;

    UPROPERTY(DefaultComponent, Attach = Root)
    UCameraComponent PortalCamera;

    // Material
    UPROPERTY(EditDefaultsOnly)
    UMaterialInterface PortalMaterialBase;

    // State

    private APortalActor LinkedPortal;
    private UMaterialInstanceDynamic PortalMaterialInstance;
    private TMap<AActor, FVector> TrackedActors;
    private UCameraComponent PlayerCamera;

    bool bCameraSynced = true;
    bool bCameraTransitionActive = false;
    float NearClipDistance = 10.0f;

    default SetTickGroup(ETickingGroup::TG_PostUpdateWork);

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PortalMaterialInstance = PortalFrameMesh.CreateDynamicMaterialInstance(0, PortalMaterialBase);

        SceneCapture.TextureTarget = Cast<UTextureRenderTarget2D>(NewObject(this, UTextureRenderTarget2D::StaticClass()));
        SceneCapture.TextureTarget.InitAutoFormat(1024, 1024);
        PortalMaterialInstance.SetTextureParameterValue(n"PortalTexture", SceneCapture.TextureTarget);
     
        UPortalSubsystem::Get().RegisterPortal(this);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!EnsureCamera())
            return;


        HandleTeleportation();
        UpdateSceneCapture();
        UpdatePortalCamera();
        UpdateLinkedCapture();

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

            PortalCamera.ProjectionMode = PlayerCamera.ProjectionMode;
            PortalCamera.FieldOfView = PlayerCamera.FieldOfView;
            PortalCamera.bOverrideAspectRatioAxisConstraint = PlayerCamera.bOverrideAspectRatioAxisConstraint;
            PortalCamera.AspectRatioAxisConstraint = PlayerCamera.AspectRatioAxisConstraint;
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
        Controller.SetViewTargetWithBlend(this);
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
        float Distance = (PortalFrameMesh.GetWorldLocation() - PortalCamera.GetWorldLocation()).DotProduct(GetActorForwardVector());
        return Math::Abs(Distance) <= NearClipDistance * 2.0f;
    }


    void UpdateSceneCapture()
    {
        UpdateResolution();
        UpdateClippingPlane();
    }
    
    FVector ComputeLinkedCameraLocation(FTransform FromTransform, FTransform LinkedTransform, UCameraComponent Camera)
    {
        FVector Scale = FromTransform.GetScale3D();
        Scale.X *= -1;
        Scale.Y *= -1;
        FTransform MirrorTransform(FromTransform.Rotation, FromTransform.Location, Scale);
        
        FVector LocalCameraPos = MirrorTransform.InverseTransformPosition(Camera.GetWorldLocation());

        return LinkedTransform.TransformPosition(LocalCameraPos);
    }

    FRotator ComputeLinkedCameraRotation(FTransform FromTransform, FTransform LinkedTransform, UCameraComponent Camera)
    {
        FVector CameraForward = Camera.GetForwardVector();
        FVector CameraRight = Camera.GetRightVector();
        FVector CameraUp = Camera.GetUpVector();

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
        SceneCapture.bEnableClipPlane = true;
        SceneCapture.ClipPlaneBase = PortalFrameMesh.GetWorldLocation() + GetActorForwardVector() * -3.0f;
        SceneCapture.ClipPlaneNormal = GetActorForwardVector();
    }

    void UpdateResolution()
    {
        APlayerController Controller = Gameplay::GetPlayerController(0);
        if (!IsValid(Controller))
            return;

        int32 ViewportX = 0, ViewportY = 0;
        Controller.GetViewportSize(ViewportX, ViewportY);
        
        if (SceneCapture.TextureTarget.SizeX != ViewportX || SceneCapture.TextureTarget.SizeY != ViewportY)
        {
            SceneCapture.TextureTarget.ResizeTarget(uint32(ViewportX), uint32(ViewportY));
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

        UCameraComponent Camera = bCameraSynced ? PlayerCamera : PortalCamera;

        FVector NewCaptureLocation = ComputeLinkedCameraLocation(GetActorTransform(), LinkedPortal.GetActorTransform(), Camera);
        FRotator NewCaptureRotation = ComputeLinkedCameraRotation(GetActorTransform(), LinkedPortal.GetActorTransform(), Camera);
        LinkedPortal.SceneCapture.SetWorldLocationAndRotation(NewCaptureLocation, NewCaptureRotation);
    }

    void UpdatePortalCamera()
    {
        FVector Location = ComputeLinkedCameraLocation(LinkedPortal.GetActorTransform() , GetActorTransform(), PlayerCamera);
        FRotator Rotation = ComputeLinkedCameraRotation(LinkedPortal.GetActorTransform(), GetActorTransform(), PlayerCamera);

        PortalCamera.SetWorldLocationAndRotation(Location, Rotation);
    }

    void UpdateLinkedCapture()
    {
        UCameraComponent Camera = bCameraSynced ? PlayerCamera : PortalCamera;

        FVector NewCaptureLocation = ComputeLinkedCameraLocation(GetActorTransform(), LinkedPortal.GetActorTransform(), Camera);
        FRotator NewCaptureRotation = ComputeLinkedCameraRotation(GetActorTransform(), LinkedPortal.GetActorTransform(), Camera);
        LinkedPortal.SceneCapture.SetWorldLocationAndRotation(NewCaptureLocation, NewCaptureRotation);
    }

}