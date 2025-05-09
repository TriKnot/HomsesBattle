class UPortalTeleporterCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    private APortalActor PortalOwner;
    private UPortalComponent PortalComp;
    private float LastCleanupTime = 0.0f;
    
    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PortalOwner = Cast<APortalActor>(Owner);
        PortalComp = PortalOwner.PortalComponent;
        
        // Setup teleportation-related components
        SetupTeleportTriggerVolume();
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
        // Periodically clean up distant actors to save resources
        if (System::GetGameTimeInSeconds() - LastCleanupTime > PortalComp.TrackedActorCleanupInterval)
        {
            CleanupDistantTrackedActors();
            LastCleanupTime = System::GetGameTimeInSeconds();
        }
        
        // Handle teleportation
        HandleTeleportation();
        
        // Handle camera transition if active
        if (PortalComp.GetIsCameraTransitionActive())
        {
            HandleCameraTransition();
        }
    }
    
    // --- Setup Methods ---
    private void SetupTeleportTriggerVolume()
    {
        PortalComp.TeleportTriggerVolume = UBoxComponent::Get(PortalOwner, n"TeleportTriggerVolume");
            
        if (!IsValid(PortalComp.TeleportTriggerVolume))
        {
            Log(n"PortalTeleportWarning", f"TeleportTriggerVolume not found on portal actor: {PortalOwner}");
            return;
        }

        PortalComp.TeleportTriggerVolume.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
    }
    
    private void SetupPlayerNearbyDetectionBox()
    {
        if (!IsValid(PortalComp.PlayerNearbyDetectionBox))
            return;
            
        PortalComp.PlayerNearbyDetectionBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
        PortalComp.PlayerNearbyDetectionBox.OnComponentBeginOverlap.AddUFunction(PortalComp, n"OnActorNearbyOverlapBegin");
        PortalComp.PlayerNearbyDetectionBox.OnComponentEndOverlap.AddUFunction(PortalComp, n"OnActorNearbyOverlapEnd");
    }
    
    private void UpdatePortalPlane()
    {
        FPlane NewPortalPlane = FPlane(PortalOwner.GetActorLocation(), PortalOwner.GetActorForwardVector());
        PortalComp.SetPortalPlane(NewPortalPlane);
    }
    
    private void CleanupDistantTrackedActors()
    {
        FVector PortalLocation = PortalOwner.GetActorLocation();
        TArray<AActor> ActorsToRemove;
        float MaxDistanceSquared = PortalComp.MaxTrackedActorDistance * PortalComp.MaxTrackedActorDistance;
        
        for (auto& Pair : PortalComp.GetTrackedActors())
        {
            if (!IsValid(Pair.Key) || Pair.Key.GetActorLocation().DistSquared(PortalLocation) > MaxDistanceSquared)
            {
                ActorsToRemove.Add(Pair.Key);
            }
        }
        
        for (AActor Actor : ActorsToRemove)
        {
            PortalComp.StopTrackingActor(Actor);
        }
    }
    
    private void HandleTeleportation()
    {
        if (!IsValid(PortalComp.TeleportTriggerVolume))
            return;
            
        TArray<AActor> OverlappingActors;
        PortalComp.TeleportTriggerVolume.GetOverlappingActors(OverlappingActors);

        for (AActor OverlappingActor : OverlappingActors)
        {
            if (!IsValid(OverlappingActor) || OverlappingActor == Owner)
                continue;
            
            // First, check if the actor has crossed the portal plane            
            if (HasCrossedPortalPlane(OverlappingActor))
            {
                TeleportActor(OverlappingActor);
                
                // If it's the local player character, initiate camera transition
                ACharacter LocalPlayerCharacter = Gameplay::GetPlayerCharacter(0); // TODO: Find a better way of doing this when the project goes multiplayer
                if (OverlappingActor == LocalPlayerCharacter)
                {
                    SwitchCamera(false);
                }
            }
        }
    }

    private bool HasCrossedPortalPlane(AActor Actor)
    {
        if (!IsValid(Actor) || !PortalComp.IsCameraSynced)
            return false;
                
        FVector CurrentLocation = Actor.GetActorLocation();
        TMap<AActor, FVector>& TrackedActors = PortalComp.GetTrackedActors();

        if (TrackedActors.Contains(Actor))
        {
            FVector PreviousLocation = TrackedActors[Actor];
            bool HasCrossed = PortalComp.IsBehindPortal(CurrentLocation) && !PortalComp.IsBehindPortal(PreviousLocation);
            TrackedActors[Actor] = CurrentLocation;
            return HasCrossed;
        }

        PortalComp.TrackActor(Actor);
        return false;
    }
    
    private void HandleCameraTransition()
    {
        if (IsCameraClippingPortalPlane())
            SwitchCamera(true);
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
    
    private bool IsCameraClippingPortalPlane()
    {          
        float Distance = 
            (PortalComp.PortalFrameMesh.GetWorldLocation() - PortalComp.PortalPlayerCamera.GetWorldLocation())
            .DotProduct(PortalOwner.GetActorForwardVector());
                         
        return Math::Abs(Distance) <= PortalComp.NearClipDistance * 2.0f;
    }
    
    void TeleportActor(AActor TargetActor)
    {
        NotifyLinkedPortalOfTeleport(TargetActor);

        PortalComp.AddTeleportedActor(TargetActor);

        FTransform TargetTransform = CalculateTeleportTargetTransform(TargetActor);
        TargetActor.SetActorLocationAndRotation(TargetTransform.GetLocation(), TargetTransform.GetRotation(), true);

        APawn Pawn = Cast<APawn>(TargetActor);
        if (IsValid(Pawn))
        {
            AdjustControllerRotationPostTeleport(Pawn, TargetTransform.GetRotation().Rotator());
        }

        AdjustVelocityPostTeleport(TargetActor);
    }

    private FTransform CalculateTeleportTargetTransform(const AActor TargetActor) const
    {
        const FTransform& SourcePortalTransform = PortalOwner.GetActorTransform();
        const FTransform& LinkedPortalTransform = PortalComp.GetLinkedPortal().GetActorTransform();

        // Location
        FVector ActorToPortalLocalPos = SourcePortalTransform.InverseTransformPosition(TargetActor.GetActorLocation());
        FVector TargetLocation = PortalTransformHelpers::TransformLocalPointToWorldMirrored(ActorToPortalLocalPos, LinkedPortalTransform);

        // Rotation
        FQuat ActorToPortalLocalRot = SourcePortalTransform.GetRotation().Inverse() * TargetActor.GetActorQuat();
        FRotator TargetRotation = 
            PortalTransformHelpers::TransformLocalRotationToWorldFlipped(
                ActorToPortalLocalRot, 
                LinkedPortalTransform.GetRotation(), 
                LinkedPortalTransform.GetRotation().GetUpVector()
            );

        return FTransform(TargetRotation, TargetLocation, TargetActor.GetActorScale3D());
    }

    private void NotifyLinkedPortalOfTeleport(AActor TargetActor)
    {
        UPortalComponent LinkedPortalComp = PortalComp.GetLinkedPortal().PortalComponent;
        if (IsValid(LinkedPortalComp))
        {
            LinkedPortalComp.TrackActor(TargetActor);
            LinkedPortalComp.AddTeleportedActor(TargetActor); // Mark as having arrived via teleport

            if (PortalComp.GetDuplicatedActors().Contains(TargetActor))
            {
                PortalComp.TransferDuplicateToLinkedPortal(TargetActor);
            }
        }
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
        FVector OldVelocity = TargetActor.GetVelocity();

        UCharacterMovementComponent CharMove = UCharacterMovementComponent::Get(TargetActor);
        if (IsValid(CharMove))
        {
            CharMove.Velocity = ComputeTeleportedVelocity(OldVelocity);
        }
        else
        {
            UPrimitiveComponent PrimComp = Cast<UPrimitiveComponent>(TargetActor.GetRootComponent());
            if (IsValid(PrimComp) && PrimComp.IsSimulatingPhysics())
            {
                PrimComp.SetPhysicsLinearVelocity(ComputeTeleportedVelocity(OldVelocity));
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

        return PortalTransformHelpers::TransformLocalVectorToWorldFlipped(LocalVelocity, DestPortalQuat, FlipAxis);
    }
}
