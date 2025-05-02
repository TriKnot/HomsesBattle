#pragma once

#include "CoreMinimal.h"
#include "SceneCaptureLibrary.generated.h"

struct FSceneViewProjectionData;

UCLASS()
class USceneCaptureLibrary : public UBlueprintFunctionLibrary {
	GENERATED_BODY()
 
public:
 
	UFUNCTION(BlueprintCallable, Category = "Camera|Projection", DisplayName = "Project World To Screen (Full Viewport)")
	static bool ProjectWorldToScreen(const USceneCaptureComponent2D* CaptureComponent, const FVector& WorldPosition, FVector2D& OutScreenPosition,
		float FarClipPlaneDistance = 10000.0f, bool bShouldCalcOutsideViewPosition = false);
 
private:
	static bool CreateBaseProjectionData(const USceneCaptureComponent2D* CaptureComponent, FSceneViewProjectionData& OutProjectionData,
		float NearClipPlane = 1.0f, float FarClipPlane = 10000.0f);
    
};
