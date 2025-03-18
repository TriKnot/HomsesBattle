class ASHomseEnemyBase : AHomseCharacterBase
{
    UPROPERTY()
    ASHomseEnemyAIControllerBase AIController;

    UPROPERTY()
    UBehaviorTree BehaviorTree;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        AIController = Cast<ASHomseEnemyAIControllerBase>(GetController());
    }

    UFUNCTION()
    void Attack()
    {
        Print("BOOP!");
    }


}