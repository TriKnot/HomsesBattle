#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "DuplicateObjectBlueprintLibrary.generated.h"


UCLASS()
class HOMSEBATTLEROYAL_API UDuplicateObjectBlueprintLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
public:
	UFUNCTION(BlueprintCallable, Category = "Utilities")
	static UObject* DuplicateObjectBlueprint(UObject* SourceObject, UObject* Outer);
};
