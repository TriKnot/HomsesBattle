#include "AI/BehaviorTree/Tasks/BTT_EnemyAttack.h"
#include "Kismet/KismetSystemLibrary.h"


EBTNodeResult::Type UBTT_EnemyAttack::ExecuteTask(UBehaviorTreeComponent& OwnerComp, uint8* NodeMemory)
{
	UKismetSystemLibrary::PrintString(this, "Attack Player");

	return EBTNodeResult::Type();
}
