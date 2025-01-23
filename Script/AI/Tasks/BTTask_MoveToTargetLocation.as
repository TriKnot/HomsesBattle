class UBTTask_MoveToTargetLocation : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetLocationKey;

    UPROPERTY(EditAnywhere)
    float AcceptanceRadius = 100.0f;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;

        if (!IsValid(BlackboardComp))
        {
            FinishExecute(false);
            return;
        }

        FVector TargetLocation = BlackboardComp.GetValueAsVector(TargetLocationKey.SelectedKeyName);

        EPathFollowingRequestResult requestResult = 
        OwnerController.MoveToLocation(TargetLocation, AcceptanceRadius, true, true, false);
        
        if (requestResult == EPathFollowingRequestResult::Failed)
        {
            FinishExecute(false);
            return;
        }
        
        if (requestResult == EPathFollowingRequestResult::AlreadyAtGoal)
        {
            FinishExecute(true);
            return;
        }
            
    }

    UFUNCTION(BlueprintOverride)
	void TickAI(AAIController OwnerController, APawn ControlledPawn, float DeltaSeconds)
    {
        if (OwnerController.GetMoveStatus() == EPathFollowingStatus::Idle)
        {
            FinishExecute(true);
        }
    }

	UFUNCTION(BlueprintOverride)
	void AbortAI(AAIController OwnerController, APawn ControlledPawn)
    {
        OwnerController.StopMovement();

        FinishExecute(false);
    }

}