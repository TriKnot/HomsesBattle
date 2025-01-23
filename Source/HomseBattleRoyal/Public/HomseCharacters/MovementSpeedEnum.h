#pragma once

#include "CoreMinimal.h"
#include "MovementSpeedEnum.generated.h"

UENUM(BlueprintType)
enum class EMovementSpeed : uint8
{
	EMS_None			UMETA(DisplayName = "None"),
	EMS_Walk			UMETA(DisplayName = "Walk"),
	EMS_Run				UMETA(DisplayName = "Run"),
	EMS_Sprint			UMETA(DisplayName = "Sprint")	
};
