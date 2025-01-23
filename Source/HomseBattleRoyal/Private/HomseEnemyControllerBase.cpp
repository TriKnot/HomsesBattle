#include "HomseEnemyControllerBase.h"


void AHomseEnemyControllerBase::BeginPlay()
{
	Super::BeginPlay();
}

void AHomseEnemyControllerBase::OnPossess(APawn* InPawn)
{
	Super::OnPossess(InPawn);
	
	RunBehaviorTree(BehaviorTree);
}


