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

        Character.SetMovementSpeed(TargetMovementSpeed);


        FinishExecute(true);            
    }

}