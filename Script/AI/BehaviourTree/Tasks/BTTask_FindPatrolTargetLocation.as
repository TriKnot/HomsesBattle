class UBTTask_FindPatrolTargetLocation : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector PatrolTargetLocationKey;

    UPROPERTY(EditAnywhere)
    UEnvQuery EnvQuery;

    UBlackboardComponent BlackboardComp;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        BlackboardComp = OwnerController.Blackboard;
        if(!IsValid(BlackboardComp))
        {
            PrintError("No Blackboard | BTTask_FindPatrolTargetLocation->ExecuteAI");
            FinishExecute(false);
            return;
        }

        UEnvQueryInstanceBlueprintWrapper Result = UEnvQueryManager::RunEQSQuery(EnvQuery, OwnerController, EEnvQueryRunMode::RandomBest25Pct, nullptr);

        if (Result == nullptr)
        {
            PrintError("No EQS Result | BTTask_FindPatrolTargetLocation->ExecuteAI");
            FinishExecute(false);
            return;
        }

        Result.OnQueryFinishedEvent.AddUFunction(this, n"OnQueryFinished");
    }

    UFUNCTION()
    void OnQueryFinished(UEnvQueryInstanceBlueprintWrapper QueryInstance, EEnvQueryStatus QueryStatus)
    {
        TArray<FVector> Locations;

        if (!QueryInstance.GetQueryResultsAsLocations(Locations))
        {
            PrintError("No Results found | BTTask_FindPatrolTargetLocation->OnQueryFinished");
            FinishExecute(false);
            return;
        }

        BlackboardComp.SetValueAsVector(PatrolTargetLocationKey.SelectedKeyName, Locations[0]);
        FinishExecute(true);
    }


}