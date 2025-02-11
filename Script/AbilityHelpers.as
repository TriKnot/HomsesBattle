namespace AbilityHelpers
{
    // Get all the health components of actors that are hit by a given component
    bool TryGetHitHealthComponents(UPrimitiveComponent&in Component, TArray<UHealthComponent>&out OutHealthComponents)
    {
        TArray<AActor> OverlapActors;
        Component.GetOverlappingActors(OverlapActors, TSubclassOf<AHomseCharacterBase>());
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

    // Rotate the given Homse to the camera rotation
    // SnapToRotation: If true, the actor will snap to the camera rotation
    void RotateActorToCameraRotation(AHomseCharacterBase Homse, bool SnapToRotation = false)
    {
        if (Homse == nullptr || Homse.HomseMovementComponent == nullptr)
            return;

        FRotator NewRotation = Homse.GetControlRotation();
        NewRotation.Pitch = 0.0f;
        NewRotation.Normalize();

        Homse.HomseMovementComponent.SetOrientToMovement(false);

        if (SnapToRotation)
            Homse.SetActorRotation(NewRotation);
    }
}