class APortalActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UPortalComponent PortalComponent;

    UPROPERTY(DefaultComponent)
    UCapabilityComponent CapabilityComponent;
    default CapabilityComponent.AddCapability(UPortalRenderCapability::StaticClass());
    default CapabilityComponent.AddCapability(UPortalTeleporterCapability::StaticClass());
    default CapabilityComponent.AddCapability(UPortalDuplicateActorCapability::StaticClass());
    
    default CapabilityComponent.SetTickGroup(ETickingGroup::TG_LastDemotable); // TODO: Change this once we have a central system for ticking capabilities

}
