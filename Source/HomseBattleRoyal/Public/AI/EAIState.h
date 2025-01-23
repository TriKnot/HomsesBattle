#pragma once

#include "CoreMinimal.h"
#include "EAIState.generated.h"

UENUM(BlueprintType)
enum class EAIState : uint8
{
	EAIS_None					UMETA(DisplayName = "None"),
	EAIS_Idle					UMETA(DisplayName = "Idle"),
	EAIState_Patrol				UMETA(DisplayName = "Patrol"),
	EAIState_Attacking			UMETA(DisplayName = "Attacking"),
	EAIState_Chasing			UMETA(DisplayName = "Chasing"),
	EAIState_Searching			UMETA(DisplayName = "Searching"),
	EAIState_Dead				UMETA(DisplayName = "Dead")
};
