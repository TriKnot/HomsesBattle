class APortalActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PortalFrameMesh;
    default PortalFrameMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

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

    UPROPERTY(EditDefaultsOnly)
    UMaterialInterface PortalMaterialBase;


    private APortalActor LinkedPortalActor;
    private UMaterialInstanceDynamic PortalMaterialInstance;
    private TMap<AActor, FVector> TeleportationMap;
    private UCameraComponent PlayerCamera;


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
        if(!IsValid(LinkedPortalActor))
            return;

        if(!IsValid(PlayerCamera))
        {
            ACharacter PlayerCharacter = Gameplay::GetPlayerCharacter(0);
            PlayerCamera = UCameraComponent::Get(PlayerCharacter);
        }

        FVector NewCaptureLocation = ComputeLinkedCameraLocation(PlayerCamera);
        FRotator NewCaptureRotation = ComputeLinkedCameraRotation(PlayerCamera);
        LinkedPortalActor.SceneCapture.SetWorldLocationAndRotation(NewCaptureLocation, NewCaptureRotation);
        
        UpdateResolution();
        UpdateClippingPlane();

        TArray<AActor> OverlappingActors;
        TeleportTriggerVolume.GetOverlappingActors(OverlappingActors);
        for (AActor OverlappingActor : OverlappingActors)
        {
            if(!IsValid(OverlappingActor) || OverlappingActor == this)
                continue;
            
            if(ShouldTeleport(OverlappingActor))
            {
                TeleportActor(OverlappingActor);
            }
        }
    }

    void SetLinkedPortalActor(APortalActor NewLinkedPortalActor)
    {
        LinkedPortalActor = NewLinkedPortalActor;

        if(!IsValid(LinkedPortalActor))
            return;

        PortalFrameMesh.SetMaterial(0, LinkedPortalActor.PortalMaterialInstance);
    }
    
    FVector ComputeLinkedCameraLocation(UCameraComponent Camera)
    {
        FTransform LocalTransform = GetActorTransform();
        FVector Scale = LocalTransform.GetScale3D();
        Scale.X *= -1;
        Scale.Y *= -1;
        FTransform MirrorTransform(GetActorRotation(), GetActorLocation(), Scale);
        
        FVector LocalCameraPos = MirrorTransform.InverseTransformPosition(PlayerCamera.GetWorldLocation());

        FTransform LinkedTransform = LinkedPortalActor.GetActorTransform();
        return LinkedTransform.TransformPosition(LocalCameraPos);
    }

    FRotator ComputeLinkedCameraRotation(UCameraComponent Camera)
    {
        FTransform LocalTransform = GetActorTransform();
        FTransform LinkedTransform = LinkedPortalActor.GetActorTransform();

        FVector CameraForward = PlayerCamera.GetForwardVector();
        FVector CameraRight = PlayerCamera.GetRightVector();
        FVector CameraUp = PlayerCamera.GetUpVector();

        TArray<FVector> LocalAxes;
        LocalAxes.Add(CameraForward);
        LocalAxes.Add(CameraRight);
        LocalAxes.Add(CameraUp);

        TArray<FVector> TransformedAxes;
        TransformedAxes.SetNum(LocalAxes.Num());

        for (int32 i = 0; i < LocalAxes.Num(); i++)
        {
            FVector LocalAxis = LocalTransform.InverseTransformVectorNoScale(LocalAxes[i]);
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

        TeleportationMap.Add(OtherActor, OtherActor.GetActorLocation()); 
    }

    UFUNCTION()
    void OnPlayerNearbyOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
    {
        if(!IsValid(OtherActor))
            return;

        TeleportationMap.Remove(OtherActor); 
    }

    void TeleportActor(AActor TargetActor)
    {        
        FVector NewLocation = ComputeTeleportedLocation(TargetActor, LinkedPortalActor);
        FRotator NewRotation = ComputeTeleportedRotation(TargetActor, LinkedPortalActor);

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
            CharMove.Velocity = ComputeTeleportedVelocity(OldVelocity, LinkedPortalActor);
            return;
        }

        if (HasPhysicsEnabled(TargetActor))
        {
            UPrimitiveComponent PrimComp = Cast<UPrimitiveComponent>(TargetActor.GetRootComponent());
            if (IsValid(PrimComp))
            {
                if (IsValid(PrimComp) && PrimComp.IsSimulatingPhysics())
                {
                    PrimComp.SetPhysicsLinearVelocity(ComputeTeleportedVelocity(OldVelocity, LinkedPortalActor));
                    return;
                }
            }
        }
        UProjectileMoveComponent ProjMove = UProjectileMoveComponent::Get(TargetActor);
        if (IsValid(ProjMove))

        {
            ProjMove.ProjectileVelocity = ComputeTeleportedVelocity(ProjMove.ProjectileVelocity, LinkedPortalActor);
        }
    }

    bool ShouldTeleport(AActor Actor)
    {
        FVector CurrentLocation = Actor.GetActorLocation();

        if(TeleportationMap.Contains(Actor))
        {
            FVector PreviousLocation = TeleportationMap[Actor];
            if(IsPointBehindPortal(CurrentLocation) && !IsPointBehindPortal(PreviousLocation))
            {
                return true;
            }

            TeleportationMap[Actor] = CurrentLocation;
            return false; 
        }

        TeleportationMap.Add(Actor, CurrentLocation);
        return false; 
    }

    bool IsPointBehindPortal(const FVector& Point)
    {
        FVector PortalPos = PortalFrameMesh.GetWorldLocation();
        const float Margin = 10.0f;
        PortalPos += GetActorForwardVector() * Margin;

        FVector PortalNormal = GetActorForwardVector();
        FVector ToPoint = (Point - PortalPos).GetSafeNormal();

        float DotProduct = PortalNormal.DotProduct(ToPoint);

        return (DotProduct < -KINDA_SMALL_NUMBER);
    }

    FVector ComputeTeleportedLocation(AActor TargetActor, APortalActor LinkedPortal)
    {
        if (!IsValid(TargetActor) || !IsValid(LinkedPortal))
        {
            return TargetActor.GetActorLocation();
        }

        FVector LocalOffset = GetActorTransform().InverseTransformPosition(TargetActor.GetActorLocation());
        LocalOffset.X = -LocalOffset.X;
        LocalOffset.Y = -LocalOffset.Y;

        return LinkedPortal.GetActorTransform().TransformPosition(LocalOffset);
    }

    FRotator ComputeTeleportedRotation(AActor Actor, APortalActor LinkedPortal)
    {
        if (!IsValid(Actor) || !IsValid(LinkedPortal))
        {
            return Actor.GetActorRotation();
        }

        FQuat Quat = Actor.GetActorQuat();
        FQuat CurrentPortalQuat = GetActorQuat();
        FQuat LinkedPortalQuat = LinkedPortal.GetActorQuat();

        FQuat RelativeQuat = CurrentPortalQuat.Inverse() * Quat;

        FQuat FlipQuat = FQuat(GetActorUpVector(), PI);
        FQuat MirroredRelativeQuat = FlipQuat * RelativeQuat;

        FQuat NewWorldQuat = LinkedPortalQuat * MirroredRelativeQuat;
        return NewWorldQuat.Rotator();
    }

    FVector ComputeTeleportedVelocity(FVector OldVelocity, APortalActor LinkedPortal)
    {
        if (!IsValid(LinkedPortal))
        {
            return OldVelocity;
        }

        FQuat CurrentPortalQuat = GetActorQuat();
        FQuat LinkedPortalQuat  = LinkedPortal.GetActorQuat();

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

}