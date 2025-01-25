class UBTService_UpdateDistanceToTargetActor : UBTService_BlueprintBase
{
	UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetActorKey;

	UPROPERTY(EditAnywhere)
	FBlackboardKeySelector DistanceToTargetActorKey;

	UBlackboardComponent BlackboardComp;
	AActor TargetActor;

	UFUNCTION(BlueprintOverride)
	void ActivationAI(AAIController OwnerController, APawn ControlledPawn)
	{
		BlackboardComp = OwnerController.Blackboard;

		if (!IsValid(BlackboardComp))
			return;

		TargetActor = Cast<AActor>(BlackboardComp.GetValueAsObject(TargetActorKey.SelectedKeyName));
	}

	UFUNCTION(BlueprintOverride)
	void TickAI(AAIController OwnerController, APawn ControlledPawn, float DeltaSeconds)
	{
		SetDistanceToTargetActor(ControlledPawn);
	}

	void SetDistanceToTargetActor(APawn ControlledPawn)
	{
		if(!IsValid(TargetActor))
			return;

		FVector ControlledPawnLocation = ControlledPawn.GetActorLocation();
		FVector TargetLocation = TargetActor.GetActorLocation();

		float DistanceToTarget = TargetLocation.Distance(ControlledPawnLocation);

		BlackboardComp.SetValueAsFloat(DistanceToTargetActorKey.SelectedKeyName, DistanceToTarget);
	}
};