class UBTDecorator_CanSeeTarget : UBTDecorator_BlueprintBase
{

    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetActorKey;

    UFUNCTION(BlueprintOverride)
    bool PerformConditionCheckAI(AAIController OwnerController, APawn ControlledPawn)
    {
        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;

        if (!IsValid(BlackboardComp))
            return false;

        AActor TargetActor = Cast<AActor>(BlackboardComp.GetValueAsObject(TargetActorKey.SelectedKeyName));

        if (!IsValid(TargetActor))
            return false;

        UAIPerceptionComponent PerceptionComponent = OwnerController.GetAIPerceptionComponent();
        ASHomseEnemyAIControllerBase AIController = Cast<ASHomseEnemyAIControllerBase>(OwnerController);

        if (!IsValid(AIController) || !IsValid(PerceptionComponent))
            return false;

        FActorPerceptionBlueprintInfo Info;
        PerceptionComponent.GetActorsPerception(TargetActor, Info);

        FAISensesReport SenseReport;

        if(AIController.CanSenseActor(TargetActor, Info, SenseReport) && SenseReport.bSightUsed)
            return true;

        return false;
    }
}