class UBTService_UpdateDistanceToTargetLocation : UBTService_BlueprintBase
{
	UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetLocationKey;

	UPROPERTY(EditAnywhere)
	FBlackboardKeySelector DistanceToTargetLocationKey;

	UBlackboardComponent BlackboardComp;

	UFUNCTION(BlueprintOverride)
	void ActivationAI(AAIController OwnerController, APawn ControlledPawn)
	{
		BlackboardComp = OwnerController.Blackboard;

		if (!IsValid(BlackboardComp))
			return;

		SetDistanceToTargetLocation(ControlledPawn);
	}

	UFUNCTION(BlueprintOverride)
	void TickAI(AAIController OwnerController, APawn ControlledPawn, float DeltaSeconds)
	{
		SetDistanceToTargetLocation(ControlledPawn);
	}

	void SetDistanceToTargetLocation(APawn ControlledPawn)
	{
		FVector ControlledPawnLocation = ControlledPawn.GetActorLocation();
		FVector TargetLocation = BlackboardComp.GetValueAsVector(TargetLocationKey.SelectedKeyName);

		float DistanceToTarget = TargetLocation.Distance(ControlledPawnLocation);

		BlackboardComp.SetValueAsFloat(DistanceToTargetLocationKey.SelectedKeyName, DistanceToTarget);
	}
};