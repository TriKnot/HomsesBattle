class UBTTask_FindPatrolTargetLocation : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector PatrolTargetLocationKey;

    UPROPERTY(EditAnywhere)
    UEnvQuery EnvQuery;

    UBlackboardComponent BlackboardComp;
    int QueryID;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        BlackboardComp = OwnerController.Blackboard;
        if(!IsValid(BlackboardComp))
        {
            FinishExecute(false);
            return;
        }

        UEnvQueryInstanceBlueprintWrapper Result = UEnvQueryManager::RunEQSQuery(EnvQuery, OwnerController, EEnvQueryRunMode::RandomBest25Pct, nullptr);

        if (Result == nullptr)
        {
            PrintError("No EQS Result");
            FinishExecute(false);
            return;
        }

        Result.OnQueryFinishedEvent.AddUFunction(this, n"OnQueryFinished");
    }

    UFUNCTION()
    void OnQueryFinished(UEnvQueryInstanceBlueprintWrapper QueryInstance, EEnvQueryStatus QueryStatus)
    {
        TArray<FVector> Locations;

        if (!QueryInstance.GetQueryResultsAsLocations(Locations) && Locations.Num() > 0)
        {
            PrintError("No Results found");
            FinishExecute(false);
            return;
        }

        // Get Random Location from the array
        FVector RandomLocation = Locations[Math::RandRange(0, Locations.Num() - 1)];

        BlackboardComp.SetValueAsVector(PatrolTargetLocationKey.SelectedKeyName, RandomLocation);

        FinishExecute(true);
    }


}