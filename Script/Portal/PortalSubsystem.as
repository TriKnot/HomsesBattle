class UPortalSubsystem : UScriptWorldSubsystem
{
    TArray<APortalActor> ActivePortals;
    const int MaxPortalCount = 2;
    ACharacter PlayerCharacter;

    UFUNCTION(BlueprintOverride)
    void OnWorldBeginPlay()
    {
        PlayerCharacter = Gameplay::GetPlayerCharacter(0);
    }


    void RegisterPortal(APortalActor PortalActor)
    {
        if (ActivePortals.Num() >= MaxPortalCount)
        {
            ActivePortals[0].DestroyActor();
            ActivePortals.RemoveAt(0);
        }
        ActivePortals.Add(PortalActor);

        if(ActivePortals.Num() == 2)
        {
            ActivePortals[0].SetLinkedPortalActor(ActivePortals[1]);
            ActivePortals[1].SetLinkedPortalActor(ActivePortals[0]);
        }
        else if(ActivePortals.Num() == 1)
        {
            ActivePortals[0].SetLinkedPortalActor(nullptr);
        }
    }

    void UnregisterPortal(APortalActor PortalActor)
    {
        ActivePortals.Remove(PortalActor);
    }   
}