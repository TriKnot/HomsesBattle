#pragma once

#include "CoreMinimal.h"
#include "HomseCharacters/HomseCharacterBase.h"
#include "HomseEnemyBase.generated.h"

UCLASS()
class AHomseEnemyBase : public AHomseCharacterBase
{
public:
	GENERATED_BODY()

	AHomseEnemyBase();

	virtual void BeginPlay() override;

public:

	UFUNCTION(BlueprintCallable)
	void Attack();

public:

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI")
	TObjectPtr<class UAIPerceptionComponent> AIPerceptionComponent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI")
	TObjectPtr<class AAIController> AIController;
	
	UPROPERTY(EditDefaultsOnly, Category = "AI")
	TObjectPtr<class UBehaviorTree> BehaviorTree;


};
