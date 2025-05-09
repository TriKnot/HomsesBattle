class UPortalDuplicateActorCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    private UPortalComponent PortalComp;

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
        return PortalComp.GetTrackedActors().Num() > 0 && IsValid(PortalComp.GetLinkedPortal());
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return !IsValid(PortalComp.GetLinkedPortal()) || PortalComp.GetTrackedActors().Num() == 0;
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
        float CurrentTime = System::GetGameTimeInSeconds();

        TArray<AActor> CompletedTransitions;
        const TMap<AActor, FDuplicateInfo>& DuplicatedActorsMap = PortalComp.GetDuplicatedActors();
        
        for (const auto& Pair : DuplicatedActorsMap)
        {
            AActor OriginalActor = Pair.Key;
            const FDuplicateInfo& DuplicateInfo = Pair.Value;
            
            if (DuplicateInfo.bInTransition)
            {
                if (IsValid(OriginalActor) && IsValid(DuplicateInfo.DuplicateActor))
                {
                    UpdateDuplicateVisuals(OriginalActor, DuplicateInfo.DuplicateActor);
                }
                
                // If the transition time has passed, we can consider this transition complete
                if (CurrentTime - DuplicateInfo.TransitionStartTime > PortalComp.DuplicateTransitionTime)
                {
                    CompletedTransitions.Add(OriginalActor);
                }
            }
        }
        
        // The duplicate is now fully managed by the other portal's capability.
        // This portal should stop tracking it.
        // Note: This does not destroy the duplicate actor, this just stops this portal from tracking it.
        for (AActor Actor : CompletedTransitions)
        {
            PortalComp.RemoveDuplicate(Actor);
        }
    }

    private void ProcessTeleportedActors()
    {
        // Process recently teleported actors
        const TArray<AActor> TeleportedActorsCopy = PortalComp.GetTeleportedActors();
        
        for (AActor TeleportedActor : TeleportedActorsCopy)
        {
            if(!IsValid(TeleportedActor))
                continue;

            // Check if this actor has a duplicate by this portal
            if (PortalComp.GetDuplicatedActors().Contains(TeleportedActor))
            {               
                // If teleported, we need to move the duplicate to the other portal
                if (!PortalComp.IsActorTeleported(TeleportedActor))
                {
                    AActor DuplicateActor = PortalComp.GetDuplicateActor(TeleportedActor);
                    if (IsValid(DuplicateActor))
                    {
                        SwitchDuplicateToOtherPortal(TeleportedActor, DuplicateActor);
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
        FVector LocalOffset = PortalComp.GetLinkedPortal().GetActorTransform().InverseTransformPosition(OriginalLocation);
        
        // Mirror the position
        LocalOffset.X = -LocalOffset.X;
        LocalOffset.Y = -LocalOffset.Y;

        // Transform to world space relative to this portal
        return Owner.GetActorTransform().TransformPosition(LocalOffset);
    }

    private FRotator ComputeReversedTransformedRotation(const FRotator& OriginalRotation)
    {
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
            if (!IsValid(Actor) || Actor == Owner)
                continue;
                
            // Check if actor is intersecting the portal plane
            if (PortalTransformHelpers::IsActorIntersectingPlane(Actor, Owner.GetActorTransform(), PortalComp.SpawnDuplicateBufferDistance))
            {
                // Create duplicate if needed
                if (!PortalComp.GetDuplicatedActors().Contains(Actor))
                {
                    AActor DuplicateActor = CreateDuplicateActor(Actor);
                    if (IsValid(DuplicateActor))
                    {
                        // Register the duplicate in the component
                        PortalComp.RegisterDuplicate(Actor, DuplicateActor, false);
                    }
                }
            }
        }
    }

    private void UpdateExistingDuplicates()
    {
        // Access the duplicates via the PortalComponent
        const TMap<AActor, FDuplicateInfo>& DuplicatedActorsMap = PortalComp.GetDuplicatedActors();
        
        for (auto& Pair : DuplicatedActorsMap)
        {
            const FDuplicateInfo& DuplicateInfo = Pair.Value;
            AActor DuplicateActor = DuplicateInfo.DuplicateActor;
            AActor OriginalActor = Pair.Key;
            
            if (IsValid(OriginalActor) && IsValid(DuplicateActor))
            {
                // If the actor has been teleported, we use reversed transform logic
                if (DuplicateInfo.bOriginalWasTeleported)
                {
                    FVector NewLocation = ComputeReversedTransformedLocation(OriginalActor.GetActorLocation());
                    FRotator NewRotation = ComputeReversedTransformedRotation(OriginalActor.GetActorRotation());
                    
                    DuplicateActor.SetActorLocationAndRotation(NewLocation, NewRotation);
                    DuplicateActor.SetActorScale3D(OriginalActor.GetActorScale3D());
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
        const TMap<AActor, FDuplicateInfo>& DuplicatedActorsMap = PortalComp.GetDuplicatedActors();
        
        for (const auto& Pair : DuplicatedActorsMap)
        {
            AActor OriginalActor = Pair.Key;
            const FDuplicateInfo& DuplicateInfo = Pair.Value;

            // Skip duplicates in transition state
            if (DuplicateInfo.bInTransition)
                continue;
            
            if (!IsValid(OriginalActor) || !IsValid(DuplicateInfo.DuplicateActor))
            {
                ActorsToRemove.Add(OriginalActor);
                continue;
            }

            if(DuplicateInfo.bOriginalWasTeleported) // Original is at linked portal
            {
                if (!PortalTransformHelpers::IsActorIntersectingPlane(OriginalActor, PortalComp.GetLinkedPortal().GetActorTransform(), PortalComp.RemoveDuplicateBufferDistance))
                {
                     ActorsToRemove.Add(OriginalActor);
                }
            }
            else // Original is at this portal
            {
                if (!PortalTransformHelpers::IsActorIntersectingPlane(OriginalActor, Owner.GetActorTransform(), PortalComp.RemoveDuplicateBufferDistance))
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
            } 
            PortalComp.RemoveDuplicate(ActorToRemove);
        }
    }
    
    private void CleanupAllDuplicates()
    {
        const TMap<AActor, FDuplicateInfo>& DuplicatedActorsMap = PortalComp.GetDuplicatedActors();
        
        for (const auto& Pair : DuplicatedActorsMap)
        {
            AActor DuplicateActor = Pair.Value.DuplicateActor;
            if (IsValid(DuplicateActor))
            {
                DuplicateActor.DestroyActor();
            }
        }
        
        // Clear all duplicate entries in the component
        PortalComp.EmptyDuplicatedActors();
    }

    private AActor CreateDuplicateActor(AActor OriginalActor)
    {
        if (!IsValid(OriginalActor))
            return nullptr;
        
        // Calculate the transformed position for the duplicate
        FVector NewLocation = ComputeTransformedLocation(OriginalActor.GetActorLocation());
        FRotator NewRotation = ComputeTransformedRotation(OriginalActor.GetActorRotation());
        
        // Spawn the duplicate actor as an empty container       
        AActor DuplicateActor = SpawnActor(AActor::StaticClass(), NewLocation, NewRotation, FName(f"{OriginalActor.GetName()}_Duplicate"));
        
        if (IsValid(DuplicateActor))
        {           
            USceneComponent RootComponent = Cast<USceneComponent>(NewObject(DuplicateActor, OriginalActor.GetRootComponent().GetClass(), FName(f"{OriginalActor.GetName()}_RootComponent")));
            DuplicateActor.RootComponent = RootComponent;
            
            // Create components for the duplicate based on the original actor
            SetupDuplicateVisualComponents(OriginalActor, DuplicateActor);
            DuplicateActor.SetActorScale3D(OriginalActor.GetActorScale3D());
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
            else
            {
                Log(n"Warning", f"Original mesh or duplicate mesh is not valid: {OriginalMesh}, {DuplicateMesh}");
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
                for (int32 MatId = 0; MatId < NumMaterials; MatId++)
                {
                    UMaterialInstanceDynamic OriginalDynMat = Cast<UMaterialInstanceDynamic>(OriginalMesh.GetMaterial(MatId));
                    if (IsValid(OriginalDynMat))
                    {
                        // If original has a dynamic material, create or update one for the duplicate
                        UMaterialInstanceDynamic DuplicateDynMat = Cast<UMaterialInstanceDynamic>(DuplicateMesh.GetMaterial(MatId));
                        if (!IsValid(DuplicateDynMat))
                        {
                            DuplicateDynMat = DuplicateMesh.CreateDynamicMaterialInstance(MatId, OriginalDynMat.BaseMaterial);

                            DuplicateMesh.SetMaterial(MatId, DuplicateDynMat);
                            DuplicateDynMat.CopyMaterialInstanceParameters(OriginalDynMat);
                        }
                    }
                    else
                    {
                        // If original has a static material, set it on the duplicate
                        UMaterialInterface OriginalMat = OriginalMesh.GetMaterial(MatId);
                        if (IsValid(OriginalMat))
                        {
                            DuplicateMesh.SetMaterial(MatId, OriginalMat);
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

    FVector ComputeTransformedLocation(const FVector& OriginalLocationAtThisPortal) const
    {
        const FTransform& ThisPortalTransform = Owner.GetActorTransform();
        const FTransform& LinkedPortalTransform = PortalComp.GetLinkedPortal().GetActorTransform();
        
        FVector LocalOffsetAtThis = ThisPortalTransform.InverseTransformPosition(OriginalLocationAtThisPortal);
        return PortalTransformHelpers::TransformLocalPointToWorldMirrored(LocalOffsetAtThis, LinkedPortalTransform);
    }

    FRotator ComputeTransformedRotation(const FRotator& OriginalRotationAtThisPortal) const
    {
        const FQuat ActorQuat = OriginalRotationAtThisPortal.Quaternion();
        const FQuat ThisPortalQuat = Owner.GetActorQuat(); // Source of transform
        const FQuat LinkedPortalQuat = PortalComp.GetLinkedPortal().GetActorQuat(); // Destination of transform
        // Flip axis for normal duplication is Linked Portal's Up
        const FVector FlipAxis = PortalComp.GetLinkedPortal().GetActorUpVector(); 

        const FQuat RelativeQuat = ThisPortalQuat.Inverse() * ActorQuat;
        return PortalTransformHelpers::TransformLocalRotationToWorldFlipped(RelativeQuat, LinkedPortalQuat, FlipAxis);
    }
}