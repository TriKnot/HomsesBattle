#include "HomseEnemyControllerBase.h"

#include "HomseEnemyBase.h"
#include "HomsePlayerCharacter.h"
#include "BehaviorTree/BehaviorTree.h"
#include "BehaviorTree/BehaviorTreeComponent.h"
#include "BehaviorTree/BlackboardComponent.h"
#include "BehaviorTree/Blackboard/BlackboardKeyType_Float.h"
#include "BehaviorTree/Blackboard/BlackboardKeyType_Object.h"
#include "Kismet/GameplayStatics.h"


void AHomseEnemyControllerBase::BeginPlay()
{
	Super::BeginPlay();
}

void AHomseEnemyControllerBase::OnPossess(APawn* InPawn)
{
	Super::OnPossess(InPawn);
	
	RunBehaviorTree(BehaviorTree);
}


