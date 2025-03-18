class UBTTask_SetMovementSpeedAS : UBTTask_BlueprintBase
{
    UPROPERTY(EditAnywhere)
    EMovementSpeed TargetMovementSpeed;

    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        AHomseCharacterBase Character = Cast<AHomseCharacterBase>(ControlledPawn);
        if (!IsValid(Character))
        {
            FinishExecute(false);
            return;
        }

        UHomseMovementComponent MovementComponent = Character.HomseMovementComponent;

        if (!IsValid(MovementComponent))
        {
            FinishExecute(false);
            return;
        }

        MovementComponent.SetMovementSpeed(TargetMovementSpeed);

        FinishExecute(true);            
    }

}