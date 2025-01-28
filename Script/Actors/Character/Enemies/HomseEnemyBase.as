class ASHomseEnemyBase : AHomseCharacterBase
{
    UPROPERTY()
    ASHomseEnemyAIControllerBase AIController;

    UPROPERTY()
    UBehaviorTree BehaviorTree;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        AIController = Cast<ASHomseEnemyAIControllerBase>(GetController());
    }

    UFUNCTION()
    void Attack()
    {
        Print("BOOP!");
    }


}