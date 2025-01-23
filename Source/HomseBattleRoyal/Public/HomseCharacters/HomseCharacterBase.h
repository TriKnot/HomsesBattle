#pragma once

#include "CoreMinimal.h"
#include "MovementSpeedEnum.h"
#include "GameFramework/Character.h"
#include "HomseCharacterBase.generated.h"


UCLASS()
class AHomseCharacterBase : public ACharacter
{
	GENERATED_BODY()
	
public:

	UFUNCTION(BlueprintCallable)
	void SetMovementSpeed(EMovementSpeed Speed);


public:
	UPROPERTY(EditAnywhere, Category = "Movement")
	float WalkSpeed = 300.0f;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float RunSpeed = 600.0f;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float SprintSpeed = 900.0f;
};
