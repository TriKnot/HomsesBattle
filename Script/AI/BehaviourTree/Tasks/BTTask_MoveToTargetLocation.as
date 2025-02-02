class UBTTask_MoveToTargetLocation : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetLocationKey;

    UPROPERTY(EditAnywhere)
    float AcceptanceRadius = 100.0f;

    AAIController Controller;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;

        if (!IsValid(BlackboardComp))
        {
            PrintError("No Blackboard | BTTask_MoveToTargetLocation->ExecuteAI");
            FinishExecute(false);
            return;
        }

        FVector TargetLocation = BlackboardComp.GetValueAsVector(TargetLocationKey.SelectedKeyName);

        EPathFollowingRequestResult requestResult = 
        OwnerController.MoveToLocation(TargetLocation, AcceptanceRadius, true, true, false);
        
        if (requestResult == EPathFollowingRequestResult::Failed)
        {
            requestResult = OwnerController.MoveToLocation(TargetLocation, AcceptanceRadius, true, false, false);
            if(requestResult == EPathFollowingRequestResult::Failed)
            {
                PrintError("MoveToTargetLocation request failed | BTTask_MoveToTargetLocation->ExecuteAI");
                FinishExecute(false);
                return;
            }
        }
        
        if (requestResult == EPathFollowingRequestResult::AlreadyAtGoal)
        {
            FinishExecute(true);
            return;
        }

        Controller = OwnerController;
            
        OwnerController.ReceiveMoveCompleted.AddUFunction(this, n"OnMoveCompleted");
    }

    UFUNCTION()
    void OnMoveCompleted(FAIRequestID RequestID, EPathFollowingResult Result)
    {
        Controller.ReceiveMoveCompleted.Clear();
        if (Result == EPathFollowingResult::Success)
        {
            FinishExecute(true);
        }
        else
        {
            FinishExecute(false);
        }
    }

	UFUNCTION(BlueprintOverride)
	void AbortAI(AAIController OwnerController, APawn ControlledPawn)
    {
        OwnerController.ReceiveMoveCompleted.Clear();
        OwnerController.StopMovement();
        FinishAbort();
    }

}