
class UPortalClipActorCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    UPortalComponent PortalComp;
    TArray<AActor> ClippedActors;

    FName OriginParamName("PortalPlaneOrigin");
    FName NormalParamName("PortalPlaneNormal");
    FName ClipParamName("EnablePortalClip");

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PortalComp = UPortalComponent::GetOrCreate(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return !PortalComp.GetTrackedTeleportComponents().IsEmpty();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return PortalComp.GetTrackedTeleportComponents().IsEmpty();
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivate()
    {
        for (AActor Actor : ClippedActors)
        {
            if (!IsValid(Actor))
                continue;

            UTeleportActorComponent TeleportedActorComp = UTeleportActorComponent::Get(Actor);
            if(!IsValid(TeleportedActorComp))
                continue;

            ResetOriginalMaterials(Actor, TeleportedActorComp);
            DisableNiagaraSystems(Actor);
            TeleportedActorComp.bSetUpNewPortal = false;
        }
        ClippedActors.Empty();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        TArray<AActor> TrackedActorsAndDuplicates;
        for (UTeleportActorComponent Component : PortalComp.GetTrackedTeleportComponents())
        {
            if(!IsValid(Component) || Component.GetActivePortal() != Owner)
                continue;

            AActor OriginalActor = Component.Owner;
            AActor DuplicateActor = Component.GetDuplicateActor();

            if (!IsValid(OriginalActor) || !IsValid(DuplicateActor))
                continue;
            
            TrackedActorsAndDuplicates.Add(OriginalActor);
            TrackedActorsAndDuplicates.Add(DuplicateActor);

            UTeleportActorComponent TeleportedActorComp = UTeleportActorComponent::GetOrCreate(OriginalActor);

            if(!TeleportedActorComp.bSetUpNewPortal)
                continue;

            ApplyOrUpdateMaterial(OriginalActor, DuplicateActor);
            AddIntersectionNiagaraSystem(OriginalActor, DuplicateActor);
            TeleportedActorComp.bSetUpNewPortal = false;
            ClippedActors.Add(OriginalActor);
        }

        for (int i = ClippedActors.Num() - 1; i >= 0; i--)
        {
            AActor Actor = ClippedActors[i];
            if (!IsValid(Actor))
                continue;

            if (TrackedActorsAndDuplicates.Contains(Actor))
                continue;

            UTeleportActorComponent TeleportedActorComp = UTeleportActorComponent::GetOrCreate(Actor);
            if(TeleportedActorComp.GetActivePortal() != Owner)
                continue;

            ResetOriginalMaterials(Actor, TeleportedActorComp);
            DisableNiagaraSystems(Actor);
            ClippedActors.RemoveAt(i);
        }
    }

    void AddIntersectionNiagaraSystem(AActor Actor, AActor DuplicateActor)
    {
        if(!IsValid(Actor) || !IsValid(PortalComp) || !IsValid(PortalComp.IntersectionNiagaraSystem_SkeletalMesh))
            return;

        UTeleportActorComponent TeleportedActorComp = UTeleportActorComponent::GetOrCreate(Actor);

        TArray<USkeletalMeshComponent> SkeletalMeshComponents;
        Actor.GetComponentsByClass(USkeletalMeshComponent::StaticClass(), SkeletalMeshComponents);
        TArray<USkinnedMeshComponent> DuplicateSkeletalMeshComponents;
        DuplicateActor.GetComponentsByClass(USkinnedMeshComponent::StaticClass(), DuplicateSkeletalMeshComponents);

        for (USkeletalMeshComponent SkeletalMeshComponent : SkeletalMeshComponents)
        {
            if(!IsValid(SkeletalMeshComponent))
                continue;

            UNiagaraComponent NiagaraComponent; 

            if(!TeleportedActorComp.IntersectionNiagaraComponents.Find(SkeletalMeshComponent, NiagaraComponent))
            {
                if(!IsValid(NiagaraComponent))
                {
                    NiagaraComponent = UNiagaraComponent::Create(Actor);
                    TeleportedActorComp.IntersectionNiagaraComponents.Add(SkeletalMeshComponent, NiagaraComponent);
                    NiagaraComponent.SetAsset(PortalComp.IntersectionNiagaraSystem_SkeletalMesh);
                    Niagara::OverrideSystemUserVariableSkeletalMeshComponent(NiagaraComponent, FString(PortalComp.SkeletalMeshSampleParamName), SkeletalMeshComponent);
                    NiagaraComponent.SetColorParameter(n"Color", PortalComp.HighlightColor);
                }
            }

            NiagaraComponent.SetVectorParameter(PortalComp.OriginParamName, PortalComp.GetPortalPlane().GetOrigin() + PortalComp.GetPortalPlane().GetNormal() * PortalComp.ClipIntersectionOffset);
            NiagaraComponent.SetVectorParameter(PortalComp.NormalParamName, PortalComp.GetPortalPlane().GetNormal());
            NiagaraComponent.SetFloatParameter(PortalComp.IntersectionThicknessParamName, PortalComp.ClipIntersetionThickness);
            NiagaraComponent.Activate();

            UNiagaraComponent DuplicateNiagaraComponent = UNiagaraComponent::Create(DuplicateActor);
            DuplicateNiagaraComponent.SetAsset(PortalComp.OffsetIntersectionNiagaraSystem_SkeletalMesh);
            Niagara::OverrideSystemUserVariableSkeletalMeshComponent(DuplicateNiagaraComponent, FString(PortalComp.SkeletalMeshSampleParamName), SkeletalMeshComponent);

            DuplicateNiagaraComponent.SetVectorParameter(PortalComp.OriginParamName, PortalComp.GetPortalPlane().GetOrigin() + -PortalComp.GetPortalPlane().GetNormal() * PortalComp.ClipIntersectionOffset);
            DuplicateNiagaraComponent.SetVectorParameter(PortalComp.NormalParamName, -PortalComp.GetPortalPlane().GetNormal());
            DuplicateNiagaraComponent.SetFloatParameter(PortalComp.IntersectionThicknessParamName, PortalComp.ClipIntersetionThickness);

            FVector PortalALocation = Owner.GetActorLocation();
            FVector PortalBLocation = PortalComp.GetLinkedPortal().GetActorLocation();
            FQuat PortalARotation = Owner.GetActorRotation().Quaternion();
            FQuat PortalBRotation = PortalComp.GetLinkedPortal().GetActorRotation().Quaternion();
            DuplicateNiagaraComponent.SetVectorParameter(n"PortalALocation", PortalALocation);
            DuplicateNiagaraComponent.SetVectorParameter(n"PortalBLocation", PortalBLocation);
            DuplicateNiagaraComponent.SetVariableQuat(n"PortalARotation", PortalARotation);
            DuplicateNiagaraComponent.SetVariableQuat(n"PortalBRotation", PortalBRotation);
            DuplicateNiagaraComponent.SetActorParameter(n"PortalA", Owner);
            DuplicateNiagaraComponent.SetColorParameter(n"Color", PortalComp.HighlightColor);
            DuplicateNiagaraComponent.Activate();
        }

        for (USkinnedMeshComponent SkinnedMeshComponent : DuplicateSkeletalMeshComponents)
        {
            if(!IsValid(SkinnedMeshComponent))
                continue;

            UNiagaraComponent NiagaraComponent; 

            if(!TeleportedActorComp.IntersectionNiagaraComponents.Find(SkinnedMeshComponent, NiagaraComponent))
            {
                if(!IsValid(NiagaraComponent))
                {
                    NiagaraComponent = UNiagaraComponent::Create(DuplicateActor);
                    NiagaraComponent.SetAsset(PortalComp.IntersectionNiagaraSystem_SkeletalMesh);
                    NiagaraComponent.SetVariableObject(PortalComp.SkeletalMeshSampleParamName, SkinnedMeshComponent.SkinnedAsset);
                    NiagaraComponent.SetColorParameter(n"Color", PortalComp.HighlightColor);
                }
            }

            NiagaraComponent.SetVectorParameter(PortalComp.OriginParamName, PortalComp.GetPortalPlane().GetOrigin() + PortalComp.GetPortalPlane().GetNormal() * PortalComp.ClipIntersectionOffset);
            NiagaraComponent.SetVectorParameter(PortalComp.NormalParamName, PortalComp.GetPortalPlane().GetNormal());
            NiagaraComponent.SetFloatParameter(PortalComp.IntersectionThicknessParamName, PortalComp.ClipIntersetionThickness);
            NiagaraComponent.Activate();
        }

        TArray<UStaticMeshComponent> Components;
        Actor.GetComponentsByClass(UStaticMeshComponent::StaticClass(), Components);
        TArray<UStaticMeshComponent> DuplicateComponents;
        DuplicateActor.GetComponentsByClass(UStaticMeshComponent::StaticClass(), DuplicateComponents);

        for (UStaticMeshComponent MeshComponent : Components)
        {
            if(!IsValid(MeshComponent))
                continue;

            UNiagaraComponent NiagaraComponent;
            if(!TeleportedActorComp.IntersectionNiagaraComponents.Find(MeshComponent, NiagaraComponent))
            {
                if(!IsValid(NiagaraComponent))
                {
                    NiagaraComponent = UNiagaraComponent::Create(Actor);
                    TeleportedActorComp.IntersectionNiagaraComponents.Add(MeshComponent, NiagaraComponent);
                    NiagaraComponent.SetVariableStaticMesh(PortalComp.StaticMeshSampleParamName, MeshComponent.StaticMesh);
                    NiagaraComponent.SetAsset(PortalComp.IntersectionNiagaraSystem_StaticMesh);
                    NiagaraComponent.SetColorParameter(n"Color", PortalComp.HighlightColor);
                }
            }

            NiagaraComponent.SetVectorParameter(PortalComp.OriginParamName, PortalComp.GetPortalPlane().GetOrigin() + PortalComp.GetPortalPlane().GetNormal() * PortalComp.ClipIntersectionOffset);
            NiagaraComponent.SetVectorParameter(PortalComp.NormalParamName, PortalComp.GetPortalPlane().GetNormal());
            NiagaraComponent.SetFloatParameter(PortalComp.IntersectionThicknessParamName, PortalComp.ClipIntersetionThickness);
            NiagaraComponent.SetColorParameter(n"Color", PortalComp.HighlightColor);
            NiagaraComponent.Activate();

        }

        for (UStaticMeshComponent MeshComponent : DuplicateComponents)
        {
            if(!IsValid(MeshComponent))
                continue;

            UNiagaraComponent NiagaraComponent;

            if(!TeleportedActorComp.IntersectionNiagaraComponents.Find(MeshComponent, NiagaraComponent))
            {
                if(!IsValid(NiagaraComponent))
                {
                    NiagaraComponent = UNiagaraComponent::Create(DuplicateActor);
                    NiagaraComponent.SetVariableStaticMesh(PortalComp.StaticMeshSampleParamName, MeshComponent.StaticMesh);
                    NiagaraComponent.SetAsset(PortalComp.IntersectionNiagaraSystem_StaticMesh);
                }
            }

            NiagaraComponent.SetVectorParameter(PortalComp.OriginParamName, PortalComp.GetLinkedPortal().PortalComponent.GetPortalPlane().GetOrigin() + PortalComp.GetLinkedPortal().PortalComponent.GetPortalPlane().GetNormal() * PortalComp.ClipIntersectionOffset);
            NiagaraComponent.SetVectorParameter(PortalComp.NormalParamName, PortalComp.GetLinkedPortal().PortalComponent.GetPortalPlane().GetNormal());
            NiagaraComponent.SetFloatParameter(PortalComp.IntersectionThicknessParamName, PortalComp.ClipIntersetionThickness);
            NiagaraComponent.Activate();
        }

        
    }

    void DisableNiagaraSystems(AActor Actor)
    {
        if(!IsValid(Actor))
            return;

        UTeleportActorComponent TeleportedActorComp = UTeleportActorComponent::GetOrCreate(Actor);
        for(auto& Pair : TeleportedActorComp.IntersectionNiagaraComponents)
        {
            if(!IsValid(Pair.Value))
                continue;

            Pair.Value.Deactivate();
        }
    }

    void ApplyOrUpdateMaterial(AActor OriginalActor, AActor DuplicateActor)
    {
        UTeleportActorComponent OriginalTeleportedActorComp = UTeleportActorComponent::GetOrCreate(OriginalActor);

        // Find all components with materials
        TArray<UMeshComponent> Components;
        OriginalActor.GetComponentsByClass(UMeshComponent::StaticClass(), Components);
        TArray<UMeshComponent> DuplicateComponents;
        DuplicateActor.GetComponentsByClass(UMeshComponent::StaticClass(), DuplicateComponents);
        
        for (int i = 0; i < Components.Num(); i++)
        {
            UMeshComponent Component = Components[i];
            int NumMaterials = Component.GetNumMaterials();

            // Check if there's already original materials saved
            FMaterialInstanceCollection Collection;
            if(!OriginalTeleportedActorComp.OriginalMaterials.Find(Component, Collection))
            {
                Collection.OriginalMaterials.SetNum(NumMaterials);
                OriginalTeleportedActorComp.OriginalMaterials.Add(Component, Collection);
            }
            
            for (int j = 0; j < NumMaterials; j++)
            {
                UMaterialInterface& OriginalMaterial = Collection.OriginalMaterials[j];
                if(!IsValid(OriginalMaterial))
                {
                    // Save the Original material
                    OriginalMaterial = Component.GetMaterial(j);
                    if(!IsValid(OriginalMaterial))
                        continue;
                    Collection.OriginalMaterials[j] = OriginalMaterial;
                }

                // Get the material instance
                UMaterialInstanceDynamic MaterialInstance = Cast<UMaterialInstanceDynamic>(Component.GetMaterial(j));

                // Create a new material instance if it doesn't exist
                if(!IsValid(MaterialInstance))
                {
                    MaterialInstance = Material::CreateDynamicMaterialInstance(OriginalMaterial, FName(f"DynamicMaterialInstance_{OriginalMaterial.GetName()}"), EMIDCreationFlags::Transient);
                }

                // Set the parameters for the material instance
                if(IsValid(MaterialInstance))
                {
                    FLinearColor Origin = FLinearColor((PortalComp.GetPortalPlane().GetOrigin() + PortalComp.GetPortalPlane().GetNormal() * -PortalComp.ClipOffset));
                    FLinearColor Normal = FLinearColor(PortalComp.GetPortalPlane().GetNormal());
                    MaterialInstance.SetScalarParameterValue(ClipParamName, 1.0f);
                    MaterialInstance.SetVectorParameterValue(OriginParamName, Origin);
                    MaterialInstance.SetVectorParameterValue(NormalParamName, Normal);

                    // Set the material instance to the component
                    Component.SetMaterial(j, MaterialInstance);
                }

                // Process duplicate actor
                UMaterialInstanceDynamic DuplicateMaterialInstance = Material::CreateDynamicMaterialInstance(OriginalMaterial, FName(f"DynamicMaterialInstance_{OriginalMaterial.GetName()}"), EMIDCreationFlags::Transient);
            
                if(IsValid(DuplicateMaterialInstance))
                {
                    FLinearColor Origin = FLinearColor((PortalComp.GetLinkedPortal().PortalComponent.GetPortalPlane().GetOrigin() + PortalComp.GetPortalPlane().GetNormal() * PortalComp.ClipOffset));
                    FLinearColor Normal = FLinearColor(PortalComp.GetLinkedPortal().PortalComponent.GetPortalPlane().GetNormal());
                    DuplicateMaterialInstance.SetScalarParameterValue(ClipParamName, 1.0f);
                    DuplicateMaterialInstance.SetVectorParameterValue(OriginParamName, Origin);
                    DuplicateMaterialInstance.SetVectorParameterValue(NormalParamName, Normal);

                    // Set the material instance to the component
                    DuplicateComponents[i].SetMaterial(j, DuplicateMaterialInstance);
                }
            }

            // Add the material collection to the teleported actor component
            if(!OriginalTeleportedActorComp.OriginalMaterials.Contains(Component))
            {
                OriginalTeleportedActorComp.OriginalMaterials.Add(Component, Collection);
            }
            else
            {
                OriginalTeleportedActorComp.OriginalMaterials[Component] = Collection;
            }
        }
    }

    void ResetOriginalMaterials(AActor Actor, UTeleportActorComponent TeleportedActorComp)
    {
        // Find all components with materials
        TArray<UMeshComponent> Components;
        Actor.GetComponentsByClass(UMeshComponent::StaticClass(), Components);
        for (UMeshComponent Component : Components)
        {
            FMaterialInstanceCollection Collection;
            if(!TeleportedActorComp.OriginalMaterials.Find(Component, Collection))
                continue;

            for (int i = 0; i < Component.GetNumMaterials(); i++)
            {
                UMaterialInterface& Material = Collection.OriginalMaterials[i];
                if (IsValid(Material))
                {
                    Component.SetMaterial(i, Material);
                }
            }
            // Remove the original materials from the collection
            TeleportedActorComp.OriginalMaterials.Remove(Component);
        }
    }

}

struct FMaterialInstanceCollection
{
    TArray<UMaterialInterface> OriginalMaterials;
}
