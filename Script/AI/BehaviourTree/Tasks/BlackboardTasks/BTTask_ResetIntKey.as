class UBTTask_ResetIntKey : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector IntKey;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;

        if (!IsValid(BlackboardComp))
            return;

        BlackboardComp.SetValueAsInt(IntKey.SelectedKeyName, 0);

        FinishExecute(true);
    }
}