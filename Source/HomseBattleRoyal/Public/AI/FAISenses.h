#pragma once

#include "CoreMinimal.h"
#include "Perception/AIPerceptionComponent.h"
#include "Perception/AIPerceptionTypes.h"
#include "FAISenses.generated.h"

// Enum to represent the different senses an AI can have
UENUM(BlueprintType)
enum class EAISenses : uint8
{
	EAS_None		UMETA(DisplayName = "None"),
	EAS_Sight		UMETA(DisplayName = "Sight"),
	EAS_Hearing		UMETA(DisplayName = "Hearing"),
	EAS_Damage		UMETA(DisplayName = "Damage"),
	EAS_Touch		UMETA(DisplayName = "Touch")
};

// Struct to track which senses have been used
USTRUCT(BlueprintType)
struct FAISensesReport
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI Senses Report")
	bool bSightUsed;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI Senses Report")
	bool bHearingUsed;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI Senses Report")
	bool bDamageUsed;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI Senses Report")
	bool bTouchUsed;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI Senses Report")
	FAIStimulus LastSensedSightStimulus;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI Senses Report")
	FAIStimulus LastSensedHearingStimulus;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI Senses Report")
	FAIStimulus LastSensedDamageStimulus;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI Senses Report")
	FAIStimulus LastSensedTouchStimulus;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI Senses Report")
	FActorPerceptionBlueprintInfo LastSensedPerceptionInfo;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI Senses Report")
	TObjectPtr<AActor> LastSensedActor;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI Senses Report")
	FVector LastSensedLocation;
	

	FAISensesReport()
		: bSightUsed(false), bHearingUsed(false), bDamageUsed(false), bTouchUsed(false)	{}

	bool HasAnySenseBeenUsed() const;
	void ResetSenses();
	void AddStimulus(const FAIStimulus& Stimulus, AActor* Actor, const FVector& Location);
	void MarkSenseUsed(const EAISenses Sense);
	bool IsSenseUsed(const EAISenses Sense) const;

	// Combine with another FAISensesReport
	void CombineWith(const FAISensesReport& Other);
};


// Utility class to expose FAISensesReport functionality to Blueprints
UCLASS(Blueprintable, BlueprintType)
class UAISensesReportLibrary : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "AI Senses Report")
	static bool HasAnySenseBeenUsed(const FAISensesReport& Report);

	UFUNCTION(BlueprintCallable, Category = "AI Senses Report")
	static void ResetSenses(FAISensesReport& Report);

	UFUNCTION(BlueprintCallable, Category = "AI Senses Report")
	static void AddStimulus(FAISensesReport& Report, const FAIStimulus& Stimulus, AActor* Actor, const FVector& Location);

	UFUNCTION(BlueprintCallable, Category = "AI Senses Report")
	static void MarkSenseUsed(FAISensesReport& Report, EAISenses Sense);

	UFUNCTION(BlueprintCallable, Category = "AI Senses Report")
	static bool IsSenseUsed(const FAISensesReport& Report, EAISenses Sense);

	UFUNCTION(BlueprintCallable, Category = "AI Senses Report")
	static void CombineWith(FAISensesReport& Report, const FAISensesReport& Other);
};
