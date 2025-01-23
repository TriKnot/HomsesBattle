class UBTTask_MoveToTargetActor : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetActorKey;

    UPROPERTY(EditAnywhere)
    float AcceptanceRadius = 50.0f;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;

        if (!IsValid(BlackboardComp))
        {
            FinishExecute(false);
            return;
        }

        auto TargetActor = Cast<AActor>(BlackboardComp.GetValueAsObject(TargetActorKey.SelectedKeyName));

        if (!IsValid(TargetActor))
        {
            FinishExecute(false);
            return;
        }
        
        EPathFollowingRequestResult requestResult = 
        OwnerController.MoveToActor(TargetActor, AcceptanceRadius, true, true, false);

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