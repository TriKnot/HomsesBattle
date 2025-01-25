class UBTTask_FindCoverLocation : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetLocationKey;

    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetActorKey;

    UPROPERTY(EditAnywhere)
    UEnvQuery EnvQuery;

    UBlackboardComponent BlackboardComp;
    APawn Pawn;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        BlackboardComp = OwnerController.Blackboard;
        if(!IsValid(BlackboardComp))
        {
            FinishExecute(false);
            return;
        }

        UEnvQueryInstanceBlueprintWrapper Result = UEnvQueryManager::RunEQSQuery(EnvQuery, OwnerController, EEnvQueryRunMode::AllMatching, nullptr);

        if (Result == nullptr)
        {
            PrintError("No EQS Result");
            FinishExecute(false);
            return;
        }

        Pawn = ControlledPawn;
        Result.OnQueryFinishedEvent.AddUFunction(this, n"OnQueryFinished");       
    }

    UFUNCTION()
    void OnQueryFinished(UEnvQueryInstanceBlueprintWrapper QueryInstance, EEnvQueryStatus QueryStatus)
    {
        TArray<FVector> Locations;

        if (!QueryInstance.GetQueryResultsAsLocations(Locations) || Locations.Num() == 0)
        {
            PrintError("No Results found");
            FinishExecute(false);
            return;
        }

        // Sort the locations by distance to the Querying Pawn
        FVector PawnLocation = Pawn.GetActorLocation();
        SortLocationsByDistance(Locations, PawnLocation);

        // Find the closest location that does not result in a pathfinding path that goes towards the target
        AActor TargetActor = Cast<AActor>(BlackboardComp.GetValueAsObject(TargetActorKey.SelectedKeyName));
        FVector TargetActorLocation = TargetActor.GetActorLocation();

        for (FVector Location : Locations)
        {
            UNavigationPath Path = UNavigationSystemV1::FindPathToLocationSynchronously(PawnLocation, Location);
            if(IsValid(Path) && !DoesPathGoTowardsLocation(Path, TargetActorLocation, PawnLocation))
            {
                BlackboardComp.SetValueAsVector(TargetLocationKey.SelectedKeyName, Location);
                FinishExecute(true);
                return;
            }
        }

        BlackboardComp.SetValueAsVector(TargetLocationKey.SelectedKeyName, Locations[0]);
        
        FinishExecute(true);
    }

    void SortLocationsByDistance(TArray<FVector> &inout Locations, const FVector &in PawnLocation)
    {
        if(Locations.Num() < 2)
        {
            return;
        }

        int Count = Locations.Num();
        for (int i = 0; i < Count - 1; i++)
        {
            for (int j = i + 1; j < Count; j++)
            {
                // Compare distances
                if ((Locations[j] - PawnLocation).SizeSquared() < (Locations[i] - PawnLocation).SizeSquared())
                {
                    // Swap the two locations
                    FVector Temp = Locations[i];
                    Locations[i] = Locations[j];
                    Locations[j] = Temp;
                }
            }
        }
    }

    bool DoesPathGoTowardsLocation(const UNavigationPath &in Path, const FVector &in TargetLocation, const FVector &in ActorLocation)
    {
        if (Path.PathPoints.Num() < 2)
        {
            return false;
        }

        FVector PathDirection = (Path.PathPoints[1] - Path.PathPoints[0]).GetSafeNormal();
        FVector TargetDirection = (TargetLocation - ActorLocation).GetSafeNormal();

        float DotProduct = PathDirection.DotProduct(TargetDirection);

        return DotProduct > 0.7f; 
    }

    
}