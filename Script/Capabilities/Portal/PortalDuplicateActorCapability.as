class UPortalDuplicateActorCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    private UPortalComponent PortalComp;

    // Configuration
    UPROPERTY(EditDefaultsOnly, Category = "Portal|Duplication")
    float DuplicateBufferDistance = 150.0f;
    
    UPROPERTY(EditDefaultsOnly, Category = "Portal|Duplication")
    float RemovalBufferDistance = 150.0f;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PortalComp = UPortalComponent::Get(Owner);
        if(!IsValid(PortalComp))
        {
            Log(n"PortalDuplicateActorCapability::Error", f"PortalComponent is not valid");
        }
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return PortalComp.GetTrackedActors().Num() > 0;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        if(!IsValid(PortalComp.GetLinkedPortal()))
        {
            Print(f"Linked portal is not valid, disabling PortalDuplicateActorCapability for {Owner.GetName()}", 5, FLinearColor::Red);
            return true;
        }
        if(PortalComp.GetTrackedActors().Num() == 0)
        {
            Print(f"Tracked actors are empty, disabling PortalDuplicateActorCapability for {Owner.GetName()}", 5, FLinearColor::Red);
            return true;
        }

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        // Make sure to clean up any existing duplicates when activating
        CleanupAllDuplicates();
    }
    
    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        CleanupAllDuplicates();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        UpdateDuplicatedActors();
    }

    private void UpdateDuplicatedActors()
    {           
        ProcessTeleportedActors();
        
        ProcessOverlappingActors();
        
        UpdateExistingDuplicates();
        
        HandleTransitionDuplicates();
        
        CleanupDistantDuplicates();
    }

    private void HandleTransitionDuplicates()
    {
        const float TransitionDuration = 0.1f; // 100ms transition window
        float CurrentTime = System::GetGameTimeInSeconds();
        TArray<AActor> CompletedTransitions;
        
        TMap<AActor, FDuplicateInfo>& DuplicatedActorsMap = PortalComp.GetDuplicatedActors();
        
        for (auto& Pair : DuplicatedActorsMap)
        {
            AActor OriginalActor = Pair.Key;
            FDuplicateInfo& DuplicateInfo = Pair.Value;
            
            if (DuplicateInfo.bInTransition)
            {
                if (IsValid(OriginalActor) && IsValid(DuplicateInfo.DuplicateActor))
                {
                    UpdateDuplicateVisuals(OriginalActor, DuplicateInfo.DuplicateActor);
                }
                
                if (CurrentTime - DuplicateInfo.TransitionStartTime > TransitionDuration)
                {
                    CompletedTransitions.Add(OriginalActor);
                }
            }
        }
        
        // Remove duplicates that have completed their transition
        for (AActor Actor : CompletedTransitions)
        {
            PortalComp.RemoveDuplicate(Actor);
        }
    }

    private void ProcessTeleportedActors()
    {
        // Process recently teleported actors
        TArray<AActor> TeleportedActorsCopy = PortalComp.GetTeleportedActors();
        
        for (AActor TeleportedActor : TeleportedActorsCopy)
        {
            // Check if this actor has a duplicate in our portal
            if (PortalComp.GetDuplicatedActors().Contains(TeleportedActor))
            {
                // The duplicate will be handled through the PortalComponent's TransferDuplicateToLinkedPortal
                // which was called during teleportation
                
                // If teleported, we need to switch the duplicate's rendering to the other portal
                if (!PortalComp.IsActorTeleported(TeleportedActor))
                {
                    AActor DuplicateActor = PortalComp.GetDuplicateActor(TeleportedActor);
                    if (IsValid(DuplicateActor))
                    {
                        // Update to show it correctly at this portal
                        SwitchDuplicateToOtherPortal(TeleportedActor, DuplicateActor);
                        Print(f"Switched duplicate actor to other portal: {DuplicateActor.GetName()}");
                    }
                }
            }
            
            // Remove from teleported list after processing
            PortalComp.RemoveTeleportedActor(TeleportedActor);
        }
    }

    private void SwitchDuplicateToOtherPortal(AActor OriginalActor, AActor DuplicateActor)
    {
        if (!IsValid(OriginalActor) || !IsValid(DuplicateActor))
            return;
            
        // Use reversed transform logic
        FVector NewLocation = ComputeReversedTransformedLocation(OriginalActor.GetActorLocation());
        FRotator NewRotation = ComputeReversedTransformedRotation(OriginalActor.GetActorRotation());
        
        // Update the duplicate's transform
        DuplicateActor.SetActorLocationAndRotation(NewLocation, NewRotation);
    }

    private FVector ComputeReversedTransformedLocation(const FVector& OriginalLocation)
    {
        if (!IsValid(PortalComp) || !IsValid(PortalComp.GetLinkedPortal()))
            return OriginalLocation;

        // Convert from the destination portal (linked portal) to this portal
        // This is the reverse of the normal transformation
        FVector LocalOffset = PortalComp.GetLinkedPortal().GetActorTransform().InverseTransformPosition(OriginalLocation);
        
        // Mirror the position
        LocalOffset.X = -LocalOffset.X;
        LocalOffset.Y = -LocalOffset.Y;

        // Transform to world space relative to this portal
        return Owner.GetActorTransform().TransformPosition(LocalOffset);
    }

    private FRotator ComputeReversedTransformedRotation(const FRotator& OriginalRotation)
    {
        if (!IsValid(PortalComp) || !IsValid(PortalComp.GetLinkedPortal()))
            return OriginalRotation;

        FQuat ActorQuat = OriginalRotation.Quaternion();
        FQuat SourcePortalQuat = PortalComp.GetLinkedPortal().GetActorQuat();
        FQuat DestPortalQuat = Owner.GetActorQuat();

        FQuat RelativeQuat = SourcePortalQuat.Inverse() * ActorQuat;
        FQuat FlipQuat = FQuat(Owner.GetActorUpVector(), PI);
        FQuat MirroredRelativeQuat = FlipQuat * RelativeQuat;

        // Calculate new world rotation relative to this portal
        FQuat NewWorldQuat = DestPortalQuat * MirroredRelativeQuat;
        return NewWorldQuat.Rotator();
    }

    private void ProcessOverlappingActors()
    {
        // Get actors overlapping the trigger volume
        TArray<AActor> OverlappingActors;
        PortalComp.TeleportTriggerVolume.GetOverlappingActors(OverlappingActors);
        OverlappingActors.Remove(Owner);
        
        for (AActor Actor : OverlappingActors)
        {
            if (!IsValid(Actor))
                continue;
                
            // Check if actor is intersecting the portal plane
            if (IsActorIntersectingPortalPlane(Actor, DuplicateBufferDistance))
            {
                // Create duplicate if needed
                if (!PortalComp.GetDuplicatedActors().Contains(Actor))
                {
                    AActor DuplicateActor = CreateDuplicateActor(Actor);
                    if (IsValid(DuplicateActor))
                    {
                        // Register the duplicate in the component
                        PortalComp.RegisterDuplicate(Actor, DuplicateActor, false);
                        Print(f"Created duplicate actor: {DuplicateActor.GetName()}");
                    }
                }
            }
        }
    }

    private void UpdateExistingDuplicates()
    {
        // Access the duplicates via the PortalComponent
        TMap<AActor, FDuplicateInfo>& DuplicatedActorsMap = PortalComp.GetDuplicatedActors();
        TArray<AActor> OriginalActors;
        DuplicatedActorsMap.GetKeys(OriginalActors);
        
        for (AActor OriginalActor : OriginalActors)
        {
            FDuplicateInfo& DuplicateInfo = DuplicatedActorsMap[OriginalActor];
            AActor DuplicateActor = DuplicateInfo.DuplicateActor;
            
            if (IsValid(OriginalActor) && IsValid(DuplicateActor))
            {
                // If the actor has been teleported, we use reversed transform logic
                if (DuplicateInfo.bOriginalWasTeleported)
                {
                    FVector NewLocation = ComputeReversedTransformedLocation(OriginalActor.GetActorLocation());
                    FRotator NewRotation = ComputeReversedTransformedRotation(OriginalActor.GetActorRotation());
                    
                    DuplicateActor.SetActorLocationAndRotation(NewLocation, NewRotation);
                }
                else
                {
                    // Normal transform logic for pre-teleport duplicates
                    UpdateDuplicateTransform(OriginalActor, DuplicateActor);
                }
                
                // Update visuals regardless of teleport state
                UpdateDuplicateVisuals(OriginalActor, DuplicateActor);
            }
        }
    }
    
    private void CleanupDistantDuplicates()
    {
        TArray<AActor> ActorsToRemove;
        TMap<AActor, FDuplicateInfo>& DuplicatedActorsMap = PortalComp.GetDuplicatedActors();
        
        for (auto& Pair : DuplicatedActorsMap)
        {
            AActor OriginalActor = Pair.Key;
            FDuplicateInfo& DuplicateInfo = Pair.Value;

            // Skip duplicates in transition state
            if (DuplicateInfo.bInTransition)
                continue;
            
            if (!IsValid(OriginalActor) || !IsValid(DuplicateInfo.DuplicateActor))
            {
                ActorsToRemove.Add(OriginalActor);
                continue;
            }
            
            // If the original actor is not intersecting any of the two linked portal planes, we can remove the duplicate
            if(!IsActorIntersectingPortalPlane(OriginalActor, RemovalBufferDistance))
            {
                if (!DuplicateInfo.bOriginalWasTeleported || 
                    !IsActorIntersectingLinkedPortalPlane(OriginalActor, RemovalBufferDistance))
                {
                    ActorsToRemove.Add(OriginalActor);
                }
            }
        }
        
        for (AActor ActorToRemove : ActorsToRemove)
        {
            AActor DuplicateActor = PortalComp.GetDuplicateActor(ActorToRemove);
            if (IsValid(DuplicateActor))
            {
                DuplicateActor.DestroyActor();
                Print(f"Removed duplicate actor: {DuplicateActor.GetName()}", 5, FLinearColor::Red);
            }
            PortalComp.RemoveDuplicate(ActorToRemove);
        }
    }

    private bool IsActorIntersectingLinkedPortalPlane(AActor Actor, float BufferDistance = 0.0f)
    {
        if (!IsValid(Actor) || !IsValid(PortalComp.GetLinkedPortal()))
            return false;
        
        // Get the actor's bounds
        FVector Location;
        FVector Extent;
        Actor.GetActorBounds(true, Location, Extent);
        FBox ActorBounds = FBox(Location - Extent, Location + Extent);
        
        // Portal plane information for the linked portal
        FVector PortalLocation = PortalComp.GetLinkedPortal().GetActorLocation();
        FVector PortalNormal = PortalComp.GetLinkedPortal().GetActorForwardVector();
        
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
    
    private void CleanupAllDuplicates()
    {
        Print(f"Cleaning up all duplicate actors", 2, FLinearColor::Yellow);
        TMap<AActor, FDuplicateInfo>& DuplicatedActorsMap = PortalComp.GetDuplicatedActors();
        
        for (auto& Pair : DuplicatedActorsMap)
        {
            AActor DuplicateActor = Pair.Value.DuplicateActor;
            if (IsValid(DuplicateActor))
            {
                DuplicateActor.DestroyActor();
            }
        }
        
        // Clear all duplicate entries in the component
        DuplicatedActorsMap.Empty();
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
        FVector PortalLocation = Owner.GetActorLocation();
        FVector PortalNormal = Owner.GetActorForwardVector();
        
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

    private AActor CreateDuplicateActor(AActor OriginalActor)
    {
        if (!IsValid(OriginalActor) || !IsValid(PortalComp) || !IsValid(PortalComp.GetLinkedPortal()))
            return nullptr;
        
        // Calculate the transformed position for the duplicate
        FVector NewLocation = ComputeTransformedLocation(OriginalActor.GetActorLocation());
        FRotator NewRotation = ComputeTransformedRotation(OriginalActor.GetActorRotation());
        
        // Spawn the duplicate actor as an empty container       
        AActor DuplicateActor = SpawnActor(AActor::StaticClass(), NewLocation, NewRotation, FName(f"{OriginalActor.GetName()}_Duplicate"));
        DuplicateActor.Owner = PortalComp.GetLinkedPortal();
        
        if (IsValid(DuplicateActor))
        {           
            USceneComponent RootComponent = Cast<USceneComponent>(NewObject(DuplicateActor, OriginalActor.GetRootComponent().GetClass(), FName(f"{OriginalActor.GetName()}_RootComponent")));
            DuplicateActor.RootComponent = RootComponent;
            
            // Create components for the duplicate based on the original actor
            SetupDuplicateVisualComponents(OriginalActor, DuplicateActor);
        }
        
        return DuplicateActor;
    }

    private void SetupDuplicateVisualComponents(AActor OriginalActor, AActor DuplicateActor)
    {
        if (!IsValid(OriginalActor) || !IsValid(DuplicateActor))
            return;
            
        // Find all skeletal mesh components in the original actor
        TArray<USkeletalMeshComponent> SkeletalMeshes;
        OriginalActor.GetComponentsByClass(USkeletalMeshComponent::StaticClass(), SkeletalMeshes);
        
        // Find all static mesh components in the original actor
        TArray<UStaticMeshComponent> StaticMeshes;
        OriginalActor.GetComponentsByClass(UStaticMeshComponent::StaticClass(), StaticMeshes);
        
        // Create corresponding poseable mesh components for each skeletal mesh
        for (USkeletalMeshComponent OriginalMesh : SkeletalMeshes)
        {
            if (!IsValid(OriginalMesh))
                continue;
                
            // Create a poseable mesh component
            UPoseableMeshComponent PoseableMesh = UPoseableMeshComponent::Create(DuplicateActor, FName(f"PoseableMesh_{OriginalMesh.GetName()}"));
            
            // Set the skeletal mesh asset
            PoseableMesh.SetSkinnedAssetAndUpdate(OriginalMesh.SkinnedAsset, false);
            
            // Set relative transform to match the original
            PoseableMesh.SetRelativeLocationAndRotation(OriginalMesh.GetRelativeLocation(), OriginalMesh.GetRelativeRotation());
            PoseableMesh.SetRelativeScale3D(OriginalMesh.GetRelativeScale3D());
            
            // Copy materials
            int32 MaterialCount = OriginalMesh.GetNumMaterials();
            for (int32 i = 0; i < MaterialCount; i++)
            {
                UMaterialInterface Material = OriginalMesh.GetMaterial(i);
                if (IsValid(Material))
                {
                    PoseableMesh.SetMaterial(i, Material);
                }
            }
            
            // Copy visibility settings
            PoseableMesh.SetVisibility(OriginalMesh.IsVisible());
            PoseableMesh.SetCastShadow(OriginalMesh.CastShadow);

            // Disable physics and collision
            PoseableMesh.SetSimulatePhysics(false);
            PoseableMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            
            // Register the component
            PoseableMesh.AttachToComponent(DuplicateActor.GetRootComponent());
        }
        
        // Duplicate static mesh components
        for (UStaticMeshComponent OriginalMesh : StaticMeshes)
        {
            if (!IsValid(OriginalMesh))
                continue;
                
            // Create a static mesh component
            UStaticMeshComponent DuplicateMesh = UStaticMeshComponent::Create(DuplicateActor, FName(f"DuplicateMesh_{OriginalMesh.GetName()}"));
            
            // Set the static mesh asset
            DuplicateMesh.SetStaticMesh(OriginalMesh.StaticMesh);
            
            // Set relative transform to match the original
            DuplicateMesh.SetRelativeLocationAndRotation(OriginalMesh.GetRelativeLocation(), OriginalMesh.GetRelativeRotation());
            DuplicateMesh.SetRelativeScale3D(OriginalMesh.GetRelativeScale3D());
            
            // Copy materials
            int32 MaterialCount = OriginalMesh.GetNumMaterials();
            for (int32 i = 0; i < MaterialCount; i++)
            {
                UMaterialInterface Material = OriginalMesh.GetMaterial(i);
                if (IsValid(Material))
                {
                    DuplicateMesh.SetMaterial(i, Material);
                }
            }
            
            // Copy visibility settings
            DuplicateMesh.SetVisibility(OriginalMesh.IsVisible());
            DuplicateMesh.SetCastShadow(OriginalMesh.CastShadow);
            
            // Disable physics and collision
            DuplicateMesh.SetSimulatePhysics(false);
            DuplicateMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            
            // Register the component
            DuplicateMesh.AttachToComponent(DuplicateActor.GetRootComponent());
        }
    }

    private void UpdateDuplicateTransform(AActor OriginalActor, AActor DuplicateActor)
    {
        if (!IsValid(OriginalActor) || !IsValid(DuplicateActor))
            return;
            
        // Calculate the transformed position and rotation
        FVector NewLocation = ComputeTransformedLocation(OriginalActor.GetActorLocation());
        FRotator NewRotation = ComputeTransformedRotation(OriginalActor.GetActorRotation());
        
        // Update the duplicate's transform
        DuplicateActor.SetActorLocationAndRotation(NewLocation, NewRotation);
        
        // Match scale
        DuplicateActor.SetActorScale3D(OriginalActor.GetActorScale3D());
    }

    private void UpdateDuplicateVisuals(AActor OriginalActor, AActor DuplicateActor)
    {
        if (!IsValid(OriginalActor) || !IsValid(DuplicateActor))
            return;
            
        // Update skeletal mesh animation
        UpdateSkeletalMeshAnimation(OriginalActor, DuplicateActor);
        
        // // Update material parameters if needed
        UpdateMaterialParameters(OriginalActor, DuplicateActor);
        
        // // Update particle effects
        UpdateParticleEffects(OriginalActor, DuplicateActor);
    }

    private void UpdateSkeletalMeshAnimation(AActor OriginalActor, AActor DuplicateActor)
    {
        // Find skeletal mesh components in both actors
        TArray<USkeletalMeshComponent> OriginalMeshes;
        OriginalActor.GetComponentsByClass(USkeletalMeshComponent::StaticClass(), OriginalMeshes);
        
        TArray<UPoseableMeshComponent> DuplicateMeshes;
        DuplicateActor.GetComponentsByClass(UPoseableMeshComponent::StaticClass(), DuplicateMeshes);
        
        // Match components by name and update animation
        for (int i = 0; i < OriginalMeshes.Num() && i < DuplicateMeshes.Num(); i++)
        {
            USkeletalMeshComponent OriginalMesh = OriginalMeshes[i];
            UPoseableMeshComponent DuplicateMesh = DuplicateMeshes[i];
            
            if (IsValid(OriginalMesh) && IsValid(DuplicateMesh))
            {
                // Copy pose snapshot from original to duplicate
                DuplicateMesh.CopyPoseFromSkeletalComponent(OriginalMesh);
            }
        }
    }

    private void UpdateMaterialParameters(AActor OriginalActor, AActor DuplicateActor)
    {
        // Find mesh components in both actors
        TArray<UMeshComponent> OriginalMeshes;
        OriginalActor.GetComponentsByClass(UMeshComponent::StaticClass(), OriginalMeshes);
        
        TArray<UMeshComponent> DuplicateMeshes;
        DuplicateActor.GetComponentsByClass(UMeshComponent::StaticClass(), DuplicateMeshes);
        
        // Match components by index and update materials
        for (int i = 0; i < OriginalMeshes.Num() && i < DuplicateMeshes.Num(); i++)
        {
            UMeshComponent OriginalMesh = OriginalMeshes[i];
            UMeshComponent DuplicateMesh = DuplicateMeshes[i];
            
            if (IsValid(OriginalMesh) && IsValid(DuplicateMesh))
            {
                // Copy dynamic material instances or create them if needed
                int32 NumMaterials = OriginalMesh.GetNumMaterials();
                for (int32 MatIdx = 0; MatIdx < NumMaterials; MatIdx++)
                {
                    UMaterialInstanceDynamic OriginalDynMat = Cast<UMaterialInstanceDynamic>(OriginalMesh.GetMaterial(MatIdx));
                    if (IsValid(OriginalDynMat))
                    {
                        // If original has a dynamic material, create or update one for the duplicate
                        UMaterialInstanceDynamic DuplicateDynMat = Cast<UMaterialInstanceDynamic>(DuplicateMesh.GetMaterial(MatIdx));
                        if (!IsValid(DuplicateDynMat))
                        {
                            DuplicateDynMat = DuplicateMesh.CreateDynamicMaterialInstance(MatIdx, OriginalDynMat.BaseMaterial);

                            DuplicateMesh.SetMaterial(MatIdx, DuplicateDynMat);
                            DuplicateDynMat.CopyMaterialInstanceParameters(OriginalDynMat);
                        }
                    }
                }
            }
        }
    }
    
    private void UpdateParticleEffects(AActor OriginalActor, AActor DuplicateActor)
    {
        // Find particle system components in both actors
        TArray<UParticleSystemComponent> OriginalParticles;
        OriginalActor.GetComponentsByClass(UParticleSystemComponent::StaticClass(), OriginalParticles);
        
        TArray<UParticleSystemComponent> DuplicateParticles;
        DuplicateActor.GetComponentsByClass(UParticleSystemComponent::StaticClass(), DuplicateParticles);
        
        // Match components by index and update particle states
        for (int i = 0; i < OriginalParticles.Num() && i < DuplicateParticles.Num(); i++)
        {
            UParticleSystemComponent OriginalParticle = OriginalParticles[i];
            UParticleSystemComponent DuplicateParticle = DuplicateParticles[i];
            
            if (IsValid(OriginalParticle) && IsValid(DuplicateParticle))
            {
                // Match active state
                if (OriginalParticle.IsActive() && !DuplicateParticle.IsActive())
                {
                    DuplicateParticle.Activate(true); // Activate and reset
                }
                else if (!OriginalParticle.IsActive() && DuplicateParticle.IsActive())
                {
                    DuplicateParticle.Deactivate();
                }
            }
        }
    }
    
    private void CopyVisualProperties(AActor OriginalActor, AActor DuplicateActor)
    {
        // Copy mesh-related properties
        TArray<UMeshComponent> OriginalMeshes;
        OriginalActor.GetComponentsByClass(UMeshComponent::StaticClass(), OriginalMeshes);

        TArray<UMeshComponent> DuplicateMeshes;
        DuplicateActor.GetComponentsByClass(UMeshComponent::StaticClass(), DuplicateMeshes);
        
        // Match components by index and copy properties
        for (int i = 0; i < OriginalMeshes.Num() && i < DuplicateMeshes.Num(); i++)
        {
            UMeshComponent OriginalMesh = OriginalMeshes[i];
            UMeshComponent DuplicateMesh = DuplicateMeshes[i];
            
            if (IsValid(OriginalMesh) && IsValid(DuplicateMesh))
            {
                // Copy materials
                int32 NumMaterials = OriginalMesh.GetNumMaterials();
                for (int32 MatIdx = 0; MatIdx < NumMaterials; MatIdx++)
                {
                    UMaterialInterface OriginalMat = OriginalMesh.GetMaterial(MatIdx);
                    if (IsValid(OriginalMat))
                    {
                        DuplicateMesh.SetMaterial(MatIdx, OriginalMat);
                    }
                }
                
                // Copy visibility state
                DuplicateMesh.SetVisibility(OriginalMesh.IsVisible());
            }
        }
    }

    private FVector ComputeTransformedLocation(const FVector& OriginalLocation)
    {
        if (!IsValid(PortalComp) || !IsValid(PortalComp.GetLinkedPortal()))
            return OriginalLocation;

        // Convert to local space relative to source portal
        FVector LocalOffset = Owner.GetActorTransform().InverseTransformPosition(OriginalLocation);
        
        // Mirror the position
        LocalOffset.X = -LocalOffset.X;
        LocalOffset.Y = -LocalOffset.Y;

        // Transform to world space relative to destination portal
        return PortalComp.GetLinkedPortal().GetActorTransform().TransformPosition(LocalOffset);
    }

    private FRotator ComputeTransformedRotation(const FRotator& OriginalRotation)
    {
        if (!IsValid(PortalComp) || !IsValid(PortalComp.GetLinkedPortal()))
            return OriginalRotation;

        // Get quaternions for easy rotation math
        FQuat ActorQuat = OriginalRotation.Quaternion();
        FQuat SourcePortalQuat = Owner.GetActorQuat();
        FQuat DestPortalQuat = PortalComp.GetLinkedPortal().GetActorQuat();

        // Calculate rotation relative to source portal
        FQuat RelativeQuat = SourcePortalQuat.Inverse() * ActorQuat;

        // Create 180-degree flip quaternion
        FQuat FlipQuat = FQuat(PortalComp.GetLinkedPortal().GetActorUpVector(), PI);
        
        // Mirror the rotation
        FQuat MirroredRelativeQuat = FlipQuat * RelativeQuat;

        // Calculate new world rotation
        FQuat NewWorldQuat = DestPortalQuat * MirroredRelativeQuat;
        return NewWorldQuat.Rotator();
    }
}

    
// Track duplicate actors with additional information about their state
struct FDuplicateInfo
{
    AActor DuplicateActor;
    bool bOriginalWasTeleported;  // Tracks if the original has been teleported
    bool bInTransition = false;   // Tracks if the duplicate is being transferred
    float TransitionStartTime = 0.0f; // When the transition started
}