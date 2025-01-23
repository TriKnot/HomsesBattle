class UBTTask_ClearFocus : UBTTask_BlueprintBase
{
    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        OwnerController.ClearFocus();
        FinishExecute(true);            
    }

}