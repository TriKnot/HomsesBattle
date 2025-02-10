#pragma once

#include "CoreMinimal.h"
#include "Engine/CancellableAsyncAction.h"
#include "GameFramework/RootMotionSource.h"
#include "AsyncRootMovement.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FMovementEvent);

UENUM(BlueprintType)
enum class ERootMotionState : uint8
{
	Idle        UMETA(DisplayName = "Idle"),
	Ongoing     UMETA(DisplayName = "Ongoing"),
	Finished    UMETA(DisplayName = "Finished"),
	Failed      UMETA(DisplayName = "Failed"),
	Cancelled   UMETA(DisplayName = "Cancelled"),
};

UCLASS(BlueprintType)
class HOMSEBATTLEROYAL_API UAsyncRootMovement : public UCancellableAsyncAction
{
	GENERATED_BODY()

	UPROPERTY()
	TWeakObjectPtr<UWorld> ContextWorld = nullptr;
	FTimerHandle OngoingDelay;

	UPROPERTY()
	UCharacterMovementComponent* CharacterMovementComponent;
	
	bool bEnableGravity;
	
	uint16 RootMotionSourceID;

	UPROPERTY(BlueprintAssignable)
	FMovementEvent OnMovementFinished;

	UPROPERTY(BlueprintAssignable)
	FMovementEvent OnMovementFailed;

public:

	UPROPERTY(BlueprintReadOnly)
	ERootMotionState MovementState = ERootMotionState::Idle;

	UFUNCTION(ScriptCallable, Category = "RootMovement")
	static UAsyncRootMovement* ApplyConstantForce(
		UCharacterMovementComponent* MovementComponent,
		FVector WorldDirection,
		float Strength,
		float Duration,  
		bool bIsAdditive = false,  
		UCurveFloat* StrengthOverTime = nullptr,  
		bool bEnableGravity = false,  
		ERootMotionFinishVelocityMode FinishVelocityMode = ERootMotionFinishVelocityMode::MaintainLastRootMotionVelocity,  
		FVector SetVelocityOnFinish = FVector::ZeroVector,  
		float ClampVelocityOnFinish = 0.0f  
	);
	
	virtual void Cancel() override;

	virtual UWorld* GetWorld() const override
	{
		return ContextWorld.IsValid() ? ContextWorld.Get() : nullptr;
	}
	
};
