#pragma once
#include "AngelscriptBindings/Bind_UTextureRenderTarget2D.h"

#include "Engine/TextureRenderTarget2D.h"
#include "GameFramework/Actor.h"

#include "UObject/UObjectIterator.h"

#include "AngelscriptBinds.h"

#include "StartAngelscriptHeaders.h"
#include "EndAngelscriptHeaders.h"

AS_FORCE_LINK const FAngelscriptBinds::FBind Bind_TextureRenderTarget2D((int32)FAngelscriptBinds::EOrder::Normal, []
{
	auto TextureRenderTarget2D_ = FAngelscriptBinds::ExistingClass("UTextureRenderTarget2D");

	TextureRenderTarget2D_.Method(
		"void InitCustomFormat(uint32 InSizeX, uint32 InSizeY, EPixelFormat InOverrideFormat, bool bInForceLinearGamma)",
		METHOD(UTextureRenderTarget2D, InitCustomFormat)
	);

	TextureRenderTarget2D_.Method(
		"void InitAutoFormat(uint32 InSizeX, uint32 InSizeY)",
		METHOD(UTextureRenderTarget2D, InitAutoFormat)
	);

	TextureRenderTarget2D_.Method(
		"void ResizeTarget(uint32 InSizeX, uint32 InSizeY)",
		METHOD(UTextureRenderTarget2D, ResizeTarget)
	);
});