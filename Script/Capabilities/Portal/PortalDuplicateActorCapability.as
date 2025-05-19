class UPortalDuplicateActorCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    private UPortalComponent PortalComp;
    TArray<AActor> ActiveDuplicates;

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
        if(!IsValid(PortalComp.GetLinkedPortal()))
            return false;

        if(PortalComp.GetTrackedTeleportComponents().IsEmpty())
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        if(!IsValid(PortalComp.GetLinkedPortal()))
            return true;

        if(!PortalComp.GetTrackedTeleportComponents().IsEmpty())
            return false;

        return true;
    }
    
    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        CleanupAllDuplicateActorsManagedByThis();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!IsValid(PortalComp) || !IsValid(PortalComp.GetLinkedPortal()))
            return;

        UpdateDuplicatedActors();
    }

    private void UpdateDuplicatedActors()
    {
        ProcessOverlappingActorsNearThisPortal(); // Create new duplicates for actors near THIS portal
        UpdateTrackedDuplicates();              // Update transform and visuals of existing duplicates
        CleanupStaleDuplicates();               // Remove duplicates that are no longer needed
    }

    void ProcessOverlappingActorsNearThisPortal()
    {
        for (UTeleportActorComponent Component : PortalComp.GetTrackedTeleportComponents())
        {
            if (!IsValid(Component) || !IsValid(Component.Owner) || Component.Owner == Owner) 
                continue;

            // Only update duplicates handles by this portal
            if(Component.GetActivePortal() != Owner)
                continue;

            // If duplicate actor already exists, skip
            if (IsValid(Component.GetDuplicateActor()))
                continue;

            // Check if the actor is overlapping the portal plane or is within the buffer distance
            if (!Portal::IsActorIntersectingPlane(Component.Owner, Owner.GetActorTransform(), PortalComp.SpawnDuplicateBufferDistance))
                continue;

            AActor DuplicateActor = CreateDuplicateActorVisuals(Component.Owner);
            if (IsValid(DuplicateActor))
            {
                // Original is near this portal, duplicate is for the view through to linked.
                Component.SetDuplicateActor(DuplicateActor);
                ActiveDuplicates.Add(DuplicateActor);
            }
        }    
    }

    void UpdateTrackedDuplicates()
    {
        for (UTeleportActorComponent Component : PortalComp.GetTrackedTeleportComponents())
        {
            if (!IsValid(Component) || !IsValid(Component.Owner) || Component.Owner == Owner) 
                continue;

            // Update transform based on state
            UpdateDuplicateTransform(Component);

            // Update visuals (skeletal animation, particles)
            // Material parameter updates are now handled by UPortalClipActorCapability
            UpdateDuplicateVisuals(Component);
        }
    }

    void CleanupStaleDuplicates()
    {
        TArray<AActor> DuplicatesToRemove = ActiveDuplicates;

        // Check if the duplicates are still valid and not in transition
        for (UTeleportActorComponent Component : PortalComp.GetTrackedTeleportComponents())
        {
            if (!IsValid(Component) || !IsValid(Component.GetDuplicateActor()))
                continue;

            if(ActiveDuplicates.Contains(Component.GetDuplicateActor()))
            {
                DuplicatesToRemove.Remove(Component.GetDuplicateActor());
            }
        }

        for (AActor DuplicateActor : DuplicatesToRemove)
        {
            if (IsValid(DuplicateActor))
            {
                DuplicateActor.DestroyActor();
                ActiveDuplicates.Remove(DuplicateActor);
            }
        }
    }

    void CleanupAllDuplicateActorsManagedByThis()
    {
        for (UTeleportActorComponent Component : PortalComp.GetTrackedTeleportComponents())
        {
            if (!IsValid(Component) || !IsValid(Component.GetDuplicateActor()))
                continue;

            if(!ActiveDuplicates.Contains(Component.GetDuplicateActor()))
                continue;
            
            Component.GetDuplicateActor().DestroyActor();
        }
        ActiveDuplicates.Empty();
    }

    private AActor CreateDuplicateActorVisuals(AActor OriginalActor)
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
            CreateDuplicateActorVisuals(OriginalActor, DuplicateActor);
            DuplicateActor.SetActorScale3D(OriginalActor.GetActorScale3D());
        }
        return DuplicateActor;
    }

    private void CreateDuplicateActorVisuals(AActor OriginalActor, AActor DuplicateActor)
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
                UMaterialInterface Material = Material::CreateDynamicMaterialInstance(OriginalMesh.GetMaterial(i));
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


    private void UpdateDuplicateTransform(UTeleportActorComponent TeleportComponent)
    {
        if (!IsValid(TeleportComponent.GetDuplicateActor()))
            return;

        FVector NewLocation;
        FRotator NewRotation;

        if (TeleportComponent.GetActivePortal() == Owner)
        {      // Original is near THIS portal, duplicate is for view TO linked portal
            NewLocation = ComputeTransformedLocation(TeleportComponent.Owner.GetActorLocation());
            NewRotation = ComputeTransformedRotation(TeleportComponent.Owner.GetActorRotation());
        }
        else
        {
            return;
        }
        
        // Update the duplicate's transform
        TeleportComponent.GetDuplicateActor().SetActorLocationAndRotation(NewLocation, NewRotation);
        
        // Match scale
        TeleportComponent.GetDuplicateActor().SetActorScale3D(TeleportComponent.Owner.GetActorScale3D());
    }

    private void UpdateDuplicateVisuals(UTeleportActorComponent TeleportComponent)
    {
        if (!IsValid(TeleportComponent.Owner) || !IsValid(TeleportComponent.GetDuplicateActor()))
            return;
            
        // Update skeletal mesh animation
        UpdateSkeletalMeshAnimation(TeleportComponent.Owner, TeleportComponent.GetDuplicateActor());
       
        // Update particle effects
        UpdateParticleEffects(TeleportComponent.Owner, TeleportComponent.GetDuplicateActor());

        // Note: Material parameters are handled by UPortalClipActorCapability
    }
    
    private void UpdateSkeletalMeshAnimation(const AActor OriginalActor, AActor DuplicateActor)
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

    private void UpdateParticleEffects(const AActor OriginalActor, AActor DuplicateActor)
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
        return Portal::TransformLocalPointToWorldMirrored(LocalOffsetAtThis, LinkedPortalTransform);
    }

    FRotator ComputeTransformedRotation(const FRotator& OriginalRotationAtThisPortal) const
    {
        const FQuat ActorQuat = OriginalRotationAtThisPortal.Quaternion();
        const FQuat ThisPortalQuat = Owner.GetActorQuat(); // Source of transform
        const FQuat LinkedPortalQuat = PortalComp.GetLinkedPortal().GetActorQuat(); // Destination of transform
        // Flip axis for normal duplication is Linked Portal's Up
        const FVector FlipAxis = PortalComp.GetLinkedPortal().GetActorUpVector(); 

        const FQuat RelativeQuat = ThisPortalQuat.Inverse() * ActorQuat;
        return Portal::TransformLocalRotationToWorldFlipped(RelativeQuat, LinkedPortalQuat, FlipAxis);
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

}