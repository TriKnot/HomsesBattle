class UBTTask_IncreaseIntKey : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector IntKey;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;

        if (!IsValid(BlackboardComp))
            return;

        int IntValue = BlackboardComp.GetValueAsInt(IntKey.SelectedKeyName);
        IntValue++;
        BlackboardComp.SetValueAsInt(IntKey.SelectedKeyName, IntValue);

        FinishExecute(true);
    }
}