class ASHomseEnemyBase : AHomseCharacterBase
{
    UPROPERTY(DefaultComponent)
    UAIPerceptionComponent AIPerceptionComponent;

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
        Print("Enemy attacks!");
    }


}