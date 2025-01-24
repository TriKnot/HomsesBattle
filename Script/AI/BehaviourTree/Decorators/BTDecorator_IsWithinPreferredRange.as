class UBTDecorator_IsWithinPreferredRange : UBTDecorator_BlueprintBase
{

    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector TargetActorKey;

    UPROPERTY(EditAnywhere)
    FBlackboardKeySelector PreferredRangeKey;

    UPROPERTY(EditAnywhere)
    float ErrorMargin = 50.0f;

    float PreferredDistance;

    UFUNCTION(BlueprintOverride)
    bool PerformConditionCheckAI(AAIController OwnerController, APawn ControlledPawn)
    {
        UBlackboardComponent BlackboardComp = OwnerController.Blackboard;

        if (!IsValid(BlackboardComp))
            return false;

        PreferredDistance = BlackboardComp.GetValueAsFloat(PreferredRangeKey.SelectedKeyName);

        AActor TargetActor = Cast<AActor>(BlackboardComp.GetValueAsObject(TargetActorKey.SelectedKeyName));

        if (!IsValid(TargetActor))
            return false;

        FVector ControlledPawnLocation = ControlledPawn.GetActorLocation();

        FVector TargetLocation = TargetActor.GetActorLocation();

        float DistanceToTarget = DistanceToTargetSquared(TargetLocation, ControlledPawnLocation);

        DistanceToTarget = Math::Sqrt(DistanceToTarget);

        return DistanceToTarget - ErrorMargin <= PreferredDistance;
    }


    float DistanceToTargetSquared(FVector TargetLocation, FVector ControlledPawnLocation)
	{
		return 
		(TargetLocation.X-ControlledPawnLocation.X)*(TargetLocation.X-ControlledPawnLocation.X) 
		+ (TargetLocation.Y-ControlledPawnLocation.Y)*(TargetLocation.Y-ControlledPawnLocation.Y) 
		+ (TargetLocation.Z-ControlledPawnLocation.Z)*(TargetLocation.Z-ControlledPawnLocation.Z);
	}

}