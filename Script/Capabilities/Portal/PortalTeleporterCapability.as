class UPortalTeleporterCapability : UCapability
{
    default Priority = ECapabilityPriority::PreMovement;

    private APortalActor PortalOwner;
    private UPortalComponent PortalComp;
    private float LastCleanupTime = 0.0f;
    
    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PortalOwner = Cast<APortalActor>(Owner);
        PortalComp = PortalOwner.PortalComponent;
        
        // Setup teleportation-related components
        SetupPlayerNearbyDetectionBox();
        
        // Initialize portal plane for teleportation checks
        UpdatePortalPlane();

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
        UpdatePortalPlane();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!IsValid(PortalComp) || !IsValid(PortalComp.GetLinkedPortal()))
            return;

        ProcessNewlyArrivedActors();

        // Handle teleportation
        HandleTeleportationOfNearbyActors();
        
        // Handle camera transition if active
        if (PortalComp.GetIsCameraTransitionActive())
        {
            HandleCameraTransition();
        }
    }

    void ProcessNewlyArrivedActors()
    {
        for (UTeleportActorComponent Component : PortalComp.GetTrackedTeleportComponents())
        {
            if (!IsValid(Component) || !IsValid(Component.Owner) || Component.GetActivePortal() == PortalOwner)
                continue;

            // Reset the teleportation state of the actor
            Component.SetActivePortal(Component.Owner);
        }
    }

    private void HandleTeleportationOfNearbyActors()
    {           
        TArray<AActor> TeleportedActors;
        for (UTeleportActorComponent Component : PortalComp.GetTrackedTeleportComponents())
        {
            if (!IsValid(Component) || !IsValid(Component.Owner))
                continue;
            
            // First, check if the actor has crossed the portal plane            
            if (HasJustCrossedPortalPlane(Component))
            {
                PerformTeleport(Component);
                TeleportedActors.Add(Component.Owner);

                UTeleportActorComponent TeleportedActorComp = UTeleportActorComponent::GetOrCreate(Component.Owner);
                TeleportedActorComp.bSetUpNewPortal = true;
                TeleportedActorComp.SetActivePortal(PortalOwner);
                
                // If it's the local player character, initiate camera transition
                ACharacter LocalPlayerCharacter = Gameplay::GetPlayerCharacter(0); // TODO: Find a better way of doing this when the project goes multiplayer
                if (Component.Owner == LocalPlayerCharacter)
                {
                    SwitchCamera(false);
                }
            }
        }
    }

    private bool HasJustCrossedPortalPlane(UTeleportActorComponent TeleportedActorComp)
    {
        if (!PortalComp.GetIsCameraSynced() || !IsValid(TeleportedActorComp))
            return false;
                
        FVector CurrentLocation = TeleportedActorComp.Owner.GetActorLocation();

        bool bWasBehind = PortalComp.IsBehindPortal(TeleportedActorComp.GetLastKnownLocation());
        bool bIsBehind = PortalComp.IsBehindPortal(CurrentLocation);

        TeleportedActorComp.UpdateLastKnownLocation();

        return bIsBehind && !bWasBehind;
    }

    void PerformTeleport(UTeleportActorComponent TeleportedActorComp)
    {
        AActor TargetActor = TeleportedActorComp.Owner;
        FTransform TargetTransform = CalculateTeleportTargetTransform(TargetActor);
        TargetActor.SetActorLocationAndRotation(TargetTransform.GetLocation(), TargetTransform.GetRotation(), true);

        APawn Pawn = Cast<APawn>(TargetActor);
        if (IsValid(Pawn))
        {
            AdjustControllerRotationPostTeleport(Pawn, TargetTransform.GetRotation().Rotator());
        }

        AdjustVelocityPostTeleport(TargetActor);

        TeleportedActorComp.SetActivePortal(PortalOwner);
        TeleportedActorComp.UpdateLastKnownLocation();
    }

    private FTransform CalculateTeleportTargetTransform(const AActor TargetActor) const
    {
        const FTransform& SourcePortalTransform = PortalOwner.GetActorTransform();
        const FTransform& LinkedPortalTransform = PortalComp.GetLinkedPortal().GetActorTransform();

        // Location
        FVector ActorToPortalLocalPos = SourcePortalTransform.InverseTransformPosition(TargetActor.GetActorLocation());
        FVector TargetLocation = Portal::TransformLocalPointToWorldMirrored(ActorToPortalLocalPos, LinkedPortalTransform);

        // Rotation
        FQuat ActorToPortalLocalRot = SourcePortalTransform.GetRotation().Inverse() * TargetActor.GetActorQuat();
        FRotator TargetRotation = Portal::TransformLocalRotationToWorldFlipped(
            ActorToPortalLocalRot, 
            LinkedPortalTransform.GetRotation(), 
            LinkedPortalTransform.GetRotation().GetUpVector()
        );

        return FTransform(TargetRotation, TargetLocation, TargetActor.GetActorScale3D());
    }

    private void AdjustControllerRotationPostTeleport(APawn TeleportedPawn, const FRotator& NewActorRotation)
    {
        if (!IsValid(TeleportedPawn)) 
            return;

        AController Controller = TeleportedPawn.GetController();
        if (IsValid(Controller))
        {
            FRotator CurrentControllerRot = Controller.GetControlRotation();
            CurrentControllerRot.Yaw = NewActorRotation.Yaw;
            Controller.SetControlRotation(CurrentControllerRot);
        }
    }

    void AdjustVelocityPostTeleport(AActor TargetActor)
    {
        UCharacterMovementComponent CharMove = UCharacterMovementComponent::Get(TargetActor);
        if (IsValid(CharMove))
        {
            CharMove.Velocity = ComputeTeleportedVelocity(TargetActor.GetVelocity());
        }
        else
        {
            UPrimitiveComponent PrimComp = Cast<UPrimitiveComponent>(TargetActor.GetRootComponent());
            if (IsValid(PrimComp) && PrimComp.IsSimulatingPhysics())
            {
                PrimComp.SetPhysicsLinearVelocity(ComputeTeleportedVelocity(TargetActor.GetVelocity()));
            }
            else
            {
                // Check for projectiles
                UProjectileMoveComponent ProjMove = UProjectileMoveComponent::Get(TargetActor);
                if (IsValid(ProjMove))
                {
                    ProjMove.ProjectileVelocity = ComputeTeleportedVelocity(ProjMove.ProjectileVelocity);
                }
            }
        }
    }

    private FVector ComputeTeleportedVelocity(FVector OldVelocity)
    {
        const FQuat SourcePortalQuat = PortalOwner.GetActorQuat();
        const FQuat DestPortalQuat = PortalComp.GetLinkedPortal().GetActorQuat();
        const FVector FlipAxis = PortalComp.GetLinkedPortal().GetActorUpVector(); // Or PortalOwner.GetActorUpVector()
        FVector LocalVelocity = SourcePortalQuat.Inverse().RotateVector(OldVelocity);

        return Portal::TransformLocalVectorToWorldFlipped(LocalVelocity, DestPortalQuat, FlipAxis);
    }

    // --- Setup Methods --    
    private void SetupPlayerNearbyDetectionBox()
    {
        if (!IsValid(PortalComp.PlayerNearbyDetectionBox))
            return;
            
        PortalComp.PlayerNearbyDetectionBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
    }
    
    private void UpdatePortalPlane()
    {
        FPlane NewPortalPlane = FPlane(PortalOwner.GetActorLocation(), PortalOwner.GetActorForwardVector());
        PortalComp.SetPortalPlane(NewPortalPlane);
    }

    private void SwitchCamera(bool bToPlayerCamera)
    {
        APlayerController Controller = Gameplay::GetPlayerController(0);
        if (IsValid(Controller))
        {
            AActor Target = bToPlayerCamera ? Gameplay::GetPlayerCharacter(0) : PortalOwner;
            Controller.SetViewTargetWithBlend(Target);
            Controller.PlayerCameraManager.SetGameCameraCutThisFrame();
            PortalComp.SetCameraSynced(bToPlayerCamera);
            PortalComp.SetCameraTransitionActive(!bToPlayerCamera);
        }
    }
    
    private void HandleCameraTransition()
    {
        if (IsCameraClippingPortalPlane())
            SwitchCamera(true);
    }
    
    private bool IsCameraClippingPortalPlane()
    {          
        float Distance = 
            (PortalComp.PortalFrameMesh.GetWorldLocation() - PortalComp.PortalPlayerCamera.GetWorldLocation())
            .DotProduct(PortalOwner.GetActorForwardVector());
                         
        return Math::Abs(Distance) <= PortalComp.NearClipDistance * 2.0f;
    }

}
