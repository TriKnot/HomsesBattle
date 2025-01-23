#pragma once
#include "CoreMinimal.h"
#include "AIController.h"
#include "HomseEnemyControllerBase.generated.h"

UCLASS()
class AHomseEnemyControllerBase : public AAIController
{
	GENERATED_BODY()

public:

	virtual void BeginPlay() override;
	
	virtual void OnPossess(APawn* InPawn) override;

public:
	UPROPERTY(EditDefaultsOnly, Category = "AI")
	TObjectPtr<UBehaviorTree> BehaviorTree;
	
};
