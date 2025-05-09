class UPortalTeleporterCapability : UCapability
{
    default Priority = ECapabilityPriority::Movement;

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
        OverlappingActors.Remove(PortalOwner);

        for (AActor OverlappingActor : OverlappingActors)
        {
            if (!IsValid(OverlappingActor))
                continue;
            
            // First, check if the actor has crossed the portal plane            
            if (HasCrossedPortalPlane(OverlappingActor))
            {
                TeleportActor(OverlappingActor);
                
                // Check if this is a player-controlled pawn
                APawn TeleportedPawn = Cast<APawn>(OverlappingActor);
                if (IsValid(TeleportedPawn) && TeleportedPawn.IsPlayerControlled())
                {
                    InitiateCameraTransition();
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

    private bool IsActorIntersectingPortalPlane(AActor Actor, float BufferDistance = 0.0f)
    {
        if (!IsValid(Actor))
            return false;
        
        // Get the actor's bounds
        FVector Location;
        FVector Extent;
        Actor.GetActorBounds(true, Location, Extent);
        FBox ActorBounds = FBox(Location - Extent, Location + Extent);
        
        // Portal plane information
        FVector PortalLocation = PortalOwner.GetActorLocation();
        FVector PortalNormal = PortalOwner.GetActorForwardVector();
        
        // Use portal mesh corners as bounds
        TArray<FVector> PortalBounds = PortalComp.GetMeshWorldCorners();
        
        // Calculate if any part of the actor is within buffer distance of the portal plane
        bool bIntersectingWithBuffer = false;
        
        // Get the 8 corners of the bounding box
        TArray<FVector> Corners;
        Corners.Add(FVector(ActorBounds.Min.X, ActorBounds.Min.Y, ActorBounds.Min.Z));
        Corners.Add(FVector(ActorBounds.Min.X, ActorBounds.Min.Y, ActorBounds.Max.Z));
        Corners.Add(FVector(ActorBounds.Min.X, ActorBounds.Max.Y, ActorBounds.Min.Z));
        Corners.Add(FVector(ActorBounds.Min.X, ActorBounds.Max.Y, ActorBounds.Max.Z));
        Corners.Add(FVector(ActorBounds.Max.X, ActorBounds.Min.Y, ActorBounds.Min.Z));
        Corners.Add(FVector(ActorBounds.Max.X, ActorBounds.Min.Y, ActorBounds.Max.Z));
        Corners.Add(FVector(ActorBounds.Max.X, ActorBounds.Max.Y, ActorBounds.Min.Z));
        Corners.Add(FVector(ActorBounds.Max.X, ActorBounds.Max.Y, ActorBounds.Max.Z));
        
        bool bHasPointInFront = false;
        bool bHasPointBehind = false;
        
        for (const FVector& Corner : Corners)
        {
            float Distance = (Corner - PortalLocation).DotProduct(PortalNormal);
            
            if (Distance > -BufferDistance) // In front or within buffer
                bHasPointInFront = true;
            if (Distance < BufferDistance) // Behind or within buffer
                bHasPointBehind = true;
            
            // If we have points on both sides or within buffer, the actor is intersecting the plane
            if (bHasPointInFront && bHasPointBehind)
                return true;
        }
        
        return false;
    }
    
    private void InitiateCameraTransition()
    {           
        // Set camera synced state to false
        PortalComp.SetCameraSynced(false);
        
        // Blend to portal camera view
        APlayerController Controller = Gameplay::GetPlayerController(0);
        if (IsValid(Controller))
            Controller.SetViewTargetWithBlend(PortalOwner);
            
        PortalComp.SetCameraTransitionActive(true);
    }
    
    private void HandleCameraTransition()
    {
        if (IsCameraClippingPortalPlane())
        {
            SwitchToPlayerCamera();
        }
    }

    private void SwitchToPlayerCamera()
    {
        ASPlayerController Controller = Cast<ASPlayerController>(Gameplay::GetPlayerController(0));
        if (IsValid(Controller))
        {
            Controller.PlayerCameraManager.SetGameCameraCutThisFrame();
            Controller.SetViewTargetWithBlend(Gameplay::GetPlayerCharacter(0));
        }
            
        PortalComp.SetCameraSynced(true);
        PortalComp.SetCameraTransitionActive(false);
    }
    
    private bool IsCameraClippingPortalPlane()
    {          
        float Distance = (PortalComp.PortalFrameMesh.GetWorldLocation() - PortalComp.PortalPlayerCamera.GetWorldLocation())
                         .DotProduct(PortalOwner.GetActorForwardVector());
                         
        return Math::Abs(Distance) <= PortalComp.NearClipDistance * 2.0f;
    }
    
    private void TeleportActor(AActor TargetActor)
    {
        if (!IsValid(TargetActor) || !IsValid(PortalComp.GetLinkedPortal()))
            return;
            
        // Calculate new position and rotation
        FVector NewLocation = ComputeTeleportedLocation(TargetActor);
        FRotator NewRotation = ComputeTeleportedRotation(TargetActor);

        // Before teleporting, tell linked portal to start tracking this actor
        UPortalComponent LinkedPortalComp = PortalComp.GetLinkedPortal().PortalComponent;
        if (IsValid(LinkedPortalComp))
        {
            // Add to tracked actors on the linked portal
            LinkedPortalComp.TrackActor(TargetActor);
            
            // Let linked portal know this is a teleported actor
            LinkedPortalComp.AddTeleportedActor(TargetActor);
            
            // If this actor has a duplicate, transfer responsibility to linked portal
            if (PortalComp.GetDuplicatedActors().Contains(TargetActor))
            {
                PortalComp.TransferDuplicateToLinkedPortal(TargetActor);
            }
        }

        // Mark as teleported in our portal
        PortalComp.AddTeleportedActor(TargetActor);

        // Set new position and rotation
        TargetActor.SetActorLocationAndRotation(NewLocation, NewRotation);

        // Handle controller rotation if applicable
        APawn Pawn = Cast<APawn>(TargetActor);
        if (IsValid(Pawn) && IsValid(Pawn.GetController()))
        {
            AController Controller = Pawn.GetController();
            if (IsValid(Controller))
            {
                // Preserve pitch and roll from controller
                FRotator ControllerRotation = Controller.ActorRotation;
                NewRotation.Pitch = ControllerRotation.Pitch;
                NewRotation.Roll = ControllerRotation.Roll;
                Controller.SetControlRotation(NewRotation);
            }
        }

        // Handle velocity
        FVector OldVelocity = TargetActor.GetVelocity();
        
        // Try to find the right component to apply velocity
        UCharacterMovementComponent CharMove = UCharacterMovementComponent::Get(TargetActor);
        if (IsValid(CharMove))
        {
            CharMove.Velocity = ComputeTeleportedVelocity(OldVelocity);
        }
        else
        {
            // Check for physics objects
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


    
    private FVector ComputeTeleportedLocation(AActor TargetActor)
    {
        if (!IsValid(TargetActor))
            return TargetActor.GetActorLocation();

        // Convert to local space relative to source portal
        FVector LocalOffset = PortalOwner.GetActorTransform().InverseTransformPosition(TargetActor.GetActorLocation());
        
        // Mirror the position
        LocalOffset.X = -LocalOffset.X;
        LocalOffset.Y = -LocalOffset.Y;

        // Transform to world space relative to destination portal
        return PortalComp.GetLinkedPortal().GetActorTransform().TransformPosition(LocalOffset);
    }

    private FRotator ComputeTeleportedRotation(AActor Actor)
    {
        if (!IsValid(Actor))
            return Actor.GetActorRotation();

        // Get quaternions for easy rotation math
        FQuat ActorQuat = Actor.GetActorQuat();
        FQuat SourcePortalQuat = PortalOwner.GetActorQuat();
        FQuat DestPortalQuat = PortalComp.GetLinkedPortal().GetActorQuat();

        // Calculate rotation relative to source portal
        FQuat RelativeQuat = SourcePortalQuat.Inverse() * ActorQuat;

        // Create 180-degree flip quaternion
        FQuat FlipQuat = FQuat(PortalOwner.GetActorUpVector(), PI);
        
        // Mirror the rotation
        FQuat MirroredRelativeQuat = FlipQuat * RelativeQuat;

        // Calculate new world rotation
        FQuat NewWorldQuat = DestPortalQuat * MirroredRelativeQuat;
        return NewWorldQuat.Rotator();
    }

    private FVector ComputeTeleportedVelocity(FVector OldVelocity)
    {
        // Get quaternions for source and destination portals
        FQuat SourcePortalQuat = PortalOwner.GetActorQuat();
        FQuat DestPortalQuat = PortalComp.GetLinkedPortal().GetActorQuat();

        // Convert velocity to local space
        FVector LocalVelocity = SourcePortalQuat.Inverse().RotateVector(OldVelocity);

        // Mirror velocity
        FQuat FlipQuat = FQuat(PortalOwner.GetActorUpVector(), PI);
        FVector MirroredLocalVelocity = FlipQuat.RotateVector(LocalVelocity);

        // Transform to destination portal space
        return DestPortalQuat.RotateVector(MirroredLocalVelocity);
    }
}
