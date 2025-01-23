class UBTTask_SetState : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector StateKey;

    UPROPERTY(EditAnywhere)
    EAIState NewState;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;
        if (!IsValid(BlackboardComp))
        {
            FinishExecute(false); 
            return;
        }

        BlackboardComp.SetValueAsEnum(StateKey.SelectedKeyName, uint8(NewState));

        FinishExecute(true);            
    }

}