class UBTService_UpdateTargetLocationToTargetActor : UBTService_BlueprintBase
{
	UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetLocationKey;

	UPROPERTY(EditAnywhere)
	FBlackboardKeySelector TargetActorKey;

	UBlackboardComponent BlackboardComp;

	UFUNCTION(BlueprintOverride)
	void ActivationAI(AAIController OwnerController, APawn ControlledPawn)
	{
		BlackboardComp = OwnerController.Blackboard;

		if (!IsValid(BlackboardComp))
			return;

		UpdateTargetLocationKey();
	}

	UFUNCTION(BlueprintOverride)
	void TickAI(AAIController OwnerController, APawn ControlledPawn, float DeltaSeconds)
	{
		UpdateTargetLocationKey();
	}

	void UpdateTargetLocationKey()
    {
        AActor TargetActor = Cast<AActor>(BlackboardComp.GetValueAsObject(TargetActorKey.SelectedKeyName));

        if (!IsValid(TargetActor))
            return;

        FVector TargetLocation = TargetActor.GetActorLocation();
        FVector NavLocation;
        ANavigationData NadData;
        FVector QueryExtent = FVector(250.0f, 250.0f, 3500.0f);

        UNavigationSystemV1::ProjectPointToNavigation(TargetLocation, NavLocation, NadData, nullptr, QueryExtent);
        System::DrawDebugSphere(NavLocation, 50.0f, 12, FLinearColor::Green, 5, 10.0f);

        BlackboardComp.SetValueAsVector(TargetLocationKey.SelectedKeyName, NavLocation);
    }
};