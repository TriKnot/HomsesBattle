class UBTTask_EnemyAttack : UBTTask_BlueprintBase
{
    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        ASHomseEnemyBase Enemy = Cast<ASHomseEnemyBase>(ControlledPawn);

        if (Enemy == nullptr)
        {
            FinishExecute(false);
            return;
        }

        Enemy.Attack();

        FinishExecute(true);            
    }
}