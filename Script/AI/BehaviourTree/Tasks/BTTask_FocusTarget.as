class UBTTask_FocusTarget : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetActorKey;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;

        if (!IsValid(BlackboardComp))
        {           
            FinishExecute(false); 
            return;
        }
        AActor FocusTargetActor = Cast<AActor>(BlackboardComp.GetValueAsObject(TargetActorKey.SelectedKeyName));

        if (!IsValid(FocusTargetActor))
        {
            FinishExecute(false);
            return;
        }

        OwnerController.SetFocus(FocusTargetActor);
        FinishExecute(true);            
    }

}