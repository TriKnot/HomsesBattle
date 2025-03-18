class UBTTask_ClearBlackboardKey : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector KeyToClear;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        OwnerController.Blackboard.ClearValue(KeyToClear.SelectedKeyName);

        FinishExecute(true);            
    }

}