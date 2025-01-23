#include "HomseEnemyBase.h"
#include "AIController.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Perception/AIPerceptionComponent.h"

AHomseEnemyBase::AHomseEnemyBase()
{
	PrimaryActorTick.bCanEverTick = true;
	Controller = Cast<AAIController>(GetController());

	AIPerceptionComponent = CreateDefaultSubobject<UAIPerceptionComponent>(TEXT("AIPerceptionComponent"));
}

void AHomseEnemyBase::BeginPlay()
{
	Super::BeginPlay();

	AIController = Cast<AAIController>(GetController());
}

void AHomseEnemyBase::Attack()
{
	UKismetSystemLibrary::PrintString(this, "Attack Player");
}
