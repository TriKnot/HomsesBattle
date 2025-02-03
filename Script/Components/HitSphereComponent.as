class UHitSphereComponent : USphereComponent
{
    default CollisionProfileName = n"Custom";
    default CollisionEnabled = ECollisionEnabled::QueryOnly;
    default CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
    default SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);

    bool TryGetHitHealthComponents(TArray<UHealthComponent>&out OutHealthComponents)
    {
        TArray<AActor> OverlapActors;
        GetOverlappingActors(OverlapActors, TSubclassOf<AHomseCharacterBase>());
        for(AActor OverlapActor : OverlapActors)
        {
            UHealthComponent HealthComp = Cast<AHomseCharacterBase>(OverlapActor).HealthComponent;
            if(HealthComp != nullptr)
            {
                OutHealthComponents.Add(HealthComp);
            }
        }
        return OutHealthComponents.Num() > 0;
    } 

};