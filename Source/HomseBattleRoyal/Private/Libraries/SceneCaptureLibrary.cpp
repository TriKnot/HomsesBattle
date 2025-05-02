#include "Libraries/SceneCaptureLibrary.h"
#include "Engine/TextureRenderTarget2D.h"
#include "Components/SceneCaptureComponent2D.h"

bool USceneCaptureLibrary::CreateBaseProjectionData(const USceneCaptureComponent2D* CaptureComponent, FSceneViewProjectionData& OutProjectionData, float NearClipPlane /* = 1.0f */, float FarClipPlane /* = 10000.0f */)
{
    if (!IsValid(CaptureComponent))
    {
    	UE_LOG(LogTemp, Warning, TEXT("UCameraExtensionsLibrary::CreateBaseProjectionData: CaptureComponent is invalid."));
    	return false;
    }
	
    UTextureRenderTarget2D* RenderTarget = CaptureComponent->TextureTarget;
    if (!IsValid(RenderTarget) || RenderTarget->SizeX <= 0 || RenderTarget->SizeY <= 0)
    {
	    UE_LOG(LogTemp, Warning, TEXT("UCameraExtensionsLibrary::CreateBaseProjectionData: RenderTarget is invalid or has zero size."));
    	return false;
    }
	
    int32 ViewportWidth = RenderTarget->SizeX;
	int32 ViewportHeight = RenderTarget->SizeY;
    float const AspectRatio = static_cast<float>(ViewportWidth) / static_cast<float>(ViewportHeight);
    if (AspectRatio <= 0.0f)
    {
    	UE_LOG(LogTemp, Warning, TEXT("UCameraExtensionsLibrary::CreateBaseProjectionData: Aspect ratio is invalid."));
    	return false;
    }
	
    float ActualNearClipPlane = CaptureComponent->bOverride_CustomNearClippingPlane ? CaptureComponent->CustomNearClippingPlane : NearClipPlane;
    if (ActualNearClipPlane <= 0.0f)
    	ActualNearClipPlane = 1.0f;
	
    float ActualFarClipPlane = FarClipPlane;
    OutProjectionData.ViewOrigin = CaptureComponent->GetComponentLocation();
    OutProjectionData.ViewRotationMatrix =
    	FInverseRotationMatrix(CaptureComponent->GetComponentRotation()) *
    	FMatrix(
    		FPlane(0, 0, 1, 0),
    		FPlane(1, 0, 0, 0),
    		FPlane(0, 1, 0, 0),
    		FPlane(0, 0, 0, 1)
    	);
	
	if (CaptureComponent->ProjectionType == ECameraProjectionMode::Type::Perspective)
	{
         float HalfFOVRadians = FMath::DegreesToRadians(CaptureComponent->FOVAngle * 0.5f);
         OutProjectionData.ProjectionMatrix = FPerspectiveMatrix(HalfFOVRadians, AspectRatio, ActualNearClipPlane, ActualFarClipPlane);
    }
	else
	{
         float const OrthoWidth = CaptureComponent->OrthoWidth; float const OrthoHeight = OrthoWidth / AspectRatio;
         OutProjectionData.ProjectionMatrix = FOrthoMatrix(OrthoWidth, OrthoHeight, ActualNearClipPlane, ActualFarClipPlane);
    }
	
    FIntRect FullViewRect(0, 0, ViewportWidth, ViewportHeight);
    OutProjectionData.SetViewRectangle(FullViewRect);
    return OutProjectionData.IsValidViewRectangle();
}

bool USceneCaptureLibrary::ProjectWorldToScreen(const USceneCaptureComponent2D* CaptureComponent, const FVector& WorldPosition, FVector2D& OutScreenPosition, float FarClipPlaneDistance /* = 10000.0f) */, bool bShouldCalcOutsideViewPosition /* = false */){
     FSceneViewProjectionData BaseProjectionData;
     if (CreateBaseProjectionData(CaptureComponent, BaseProjectionData, CaptureComponent->bOverride_CustomNearClippingPlane ? CaptureComponent->CustomNearClippingPlane : 1.0f, FarClipPlaneDistance)) {
         const FMatrix BaseViewProjectionMatrix = BaseProjectionData.ComputeViewProjectionMatrix();
         return FSceneView::ProjectWorldToScreen(
             WorldPosition,
             BaseProjectionData.GetConstrainedViewRect(),
             BaseViewProjectionMatrix,
             OutScreenPosition,
             bShouldCalcOutsideViewPosition
         );
     }
     return false;
}
