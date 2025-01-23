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

	float DistanceToTargetSquared(FVector TargetLocation, FVector ControlledPawnLocation)
	{
		return 
		(TargetLocation.X-ControlledPawnLocation.X)*(TargetLocation.X-ControlledPawnLocation.X) 
		+ (TargetLocation.Y-ControlledPawnLocation.Y)*(TargetLocation.Y-ControlledPawnLocation.Y) 
		+ (TargetLocation.Z-ControlledPawnLocation.Z)*(TargetLocation.Z-ControlledPawnLocation.Z);
	}

	void SetDistanceToTargetLocation(APawn ControlledPawn)
	{
		FVector ControlledPawnLocation = ControlledPawn.GetActorLocation();
		FVector TargetLocation = BlackboardComp.GetValueAsVector(TargetLocationKey.SelectedKeyName);

		float DistanceToTarget = DistanceToTargetSquared(TargetLocation, ControlledPawnLocation);
		DistanceToTarget = Math::Sqrt(DistanceToTarget);

		BlackboardComp.SetValueAsFloat(DistanceToTargetLocationKey.SelectedKeyName, DistanceToTarget);
	}
};