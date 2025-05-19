
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
            ClippedActors.RemoveAt(i);
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
                    MaterialInstance.SetScalarParameterValue(ClipParamName, 1.0f);
                    MaterialInstance.SetVectorParameterValue(OriginParamName, FLinearColor(PortalComp.GetPortalPlane().GetOrigin()));
                    MaterialInstance.SetVectorParameterValue(NormalParamName, FLinearColor(PortalComp.GetPortalPlane().GetNormal()));

                    // Set the material instance to the component
                    Component.SetMaterial(j, MaterialInstance);
                }

                // Process duplicate actor
                UMaterialInstanceDynamic DuplicateMaterialInstance = Material::CreateDynamicMaterialInstance(OriginalMaterial, FName(f"DynamicMaterialInstance_{OriginalMaterial.GetName()}"), EMIDCreationFlags::Transient);
            
                if(IsValid(DuplicateMaterialInstance))
                {
                    DuplicateMaterialInstance.SetScalarParameterValue(ClipParamName, 1.0f);
                    DuplicateMaterialInstance.SetVectorParameterValue(OriginParamName, FLinearColor(PortalComp.GetLinkedPortal().PortalComponent.GetPortalPlane().GetOrigin()));
                    DuplicateMaterialInstance.SetVectorParameterValue(NormalParamName, FLinearColor(PortalComp.GetLinkedPortal().PortalComponent.GetPortalPlane().GetNormal()));

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
