#include "Movement/AsyncRootMovement.h"
#include "GameFramework/CharacterMovementComponent.h"


UAsyncRootMovement* UAsyncRootMovement::ApplyConstantForce(UCharacterMovementComponent* MovementComponent, const FVector& WorldDirection, const float Strength, const float Duration, const bool bIsAdditive,
	UCurveFloat* StrengthOverTime, const bool bEnableGravity, const ERootMotionFinishVelocityMode FinishVelocityMode, const FVector& SetVelocityOnFinish, const float ClampVelocityOnFinish)
{
    UAsyncRootMovement* RootMovement = NewObject<UAsyncRootMovement>();
	if (!MovementComponent)
	{
		RootMovement->MovementState = ERootMotionState::Failed;
		RootMovement->OnMovementFailed.Broadcast();
		RootMovement->Cancel();
	}

	RootMovement->CharacterMovementComponent = MovementComponent;
    RootMovement->ContextWorld = GEngine->GetWorldFromContextObject(MovementComponent, EGetWorldErrorMode::ReturnNull);
	
    if (!ensureAlwaysMsgf(IsValid(MovementComponent), TEXT("World Context was not valid.")))
    {
    	RootMovement->MovementState = ERootMotionState::Failed;
    	RootMovement->OnMovementFailed.Broadcast();
    	RootMovement->Cancel();
        return RootMovement;
    }

	TSharedPtr<FRootMotionSource_ConstantForce> ConstantForce = MakeShared<FRootMotionSource_ConstantForce>();
	ConstantForce->Priority = 5; // TODO: Evaluate how to best set this
	ConstantForce->Force = WorldDirection.GetSafeNormal() * Strength;
	ConstantForce->Duration = Duration;
	
	ConstantForce->AccumulateMode = bIsAdditive ? ERootMotionAccumulateMode::Additive : ERootMotionAccumulateMode::Override;
	ConstantForce->StrengthOverTime = StrengthOverTime;
	ConstantForce->FinishVelocityParams.Mode = FinishVelocityMode;
	ConstantForce->FinishVelocityParams.SetVelocity = SetVelocityOnFinish;
	ConstantForce->FinishVelocityParams.ClampVelocity = ClampVelocityOnFinish;
	
	if (bEnableGravity)
	{
		ConstantForce->Settings.SetFlag(ERootMotionSourceSettingsFlags::IgnoreZAccumulate);
	}
	
	RootMovement->RootMotionSourceID = MovementComponent->ApplyRootMotionSource(ConstantForce);
	RootMovement->RegisterWithGameInstance(RootMovement->ContextWorld->GetGameInstance());
	RootMovement->MovementState = ERootMotionState::Ongoing;

	FTimerManager& TimerManager = RootMovement->ContextWorld->GetTimerManager();

	TimerManager.SetTimer(
		RootMovement->OngoingDelay,
		FTimerDelegate::CreateLambda([WeakThis = TWeakObjectPtr<UAsyncRootMovement>(RootMovement)]()
	{
		if (WeakThis.IsValid() && WeakThis->IsActive())
		{
			WeakThis->MovementState = ERootMotionState::Finished;
			WeakThis->OnMovementFinished.Broadcast();
			WeakThis->Cancel();
		}
	}),
		Duration,
		false
		);
	return RootMovement;
}

void UAsyncRootMovement::Cancel()
{
    Super::Cancel();

	if (MovementState == ERootMotionState::Ongoing)
	{
		MovementState = ERootMotionState::Cancelled;
	}
	
	SetReadyToDestroy();
	 
    if (!OngoingDelay.IsValid())
    {
    	return;
    }
	
	const UWorld* World = GetWorld();
    if (!World)
    {
        return;
    }
	
    CharacterMovementComponent->RemoveRootMotionSourceByID(RootMotionSourceID);

    FTimerManager& TimerManager = World->GetTimerManager();
    TimerManager.ClearTimer(OngoingDelay);
}

bool UAsyncRootMovement::IsActive() const
{
	return Super::IsActive() && MovementState == ERootMotionState::Ongoing;
}