class UBTTask_MoveToTargetActor : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetActorKey;

    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector AcceptanceRadiusKey;

    AAIController Controller;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {

        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;

        if (!IsValid(BlackboardComp))
        {
            PrintError("No Blackboard | BTTask_MoveToTargetActor->ExecuteAI");
            FinishExecute(false);
            return;
        }

        AActor TargetActor = Cast<AActor>(BlackboardComp.GetValueAsObject(TargetActorKey.SelectedKeyName));

        if (!IsValid(TargetActor))
        {
            PrintError("No TargetActor | BTTask_MoveToTargetActor->ExecuteAI");
            FinishExecute(false);
            return;
        }

        Controller = OwnerController;

        float AcceptanceRadius = BlackboardComp.GetValueAsFloat(AcceptanceRadiusKey.SelectedKeyName);
        
        EPathFollowingRequestResult requestResult = Controller.MoveToActor(TargetActor, AcceptanceRadius, true, true, false);

        if (requestResult == EPathFollowingRequestResult::Failed)
        {
            Controller.MoveToActor(TargetActor, AcceptanceRadius, true, false, false);
            if(requestResult == EPathFollowingRequestResult::Failed)
            {            
                PrintError("MoveToTargetActor request failed | BTTask_MoveToTargetActor->ExecuteAI");
                FinishExecute(false);
                return;
            }
        }
        
        if (requestResult == EPathFollowingRequestResult::AlreadyAtGoal)
        {
            FinishExecute(true);
            return;
        }
        
        Controller.ReceiveMoveCompleted.AddUFunction(this, n"OnMoveCompleted");
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