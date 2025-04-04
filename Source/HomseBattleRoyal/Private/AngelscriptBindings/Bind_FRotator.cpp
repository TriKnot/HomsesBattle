#pragma once
#include "AngelscriptBindings/Bind_FRotator.h"

#include "Math/Rotator.h"
#include "AngelscriptBinds.h"

AS_FORCE_LINK const FAngelscriptBinds::FBind Bind_FRotator((int32)FAngelscriptBinds::EOrder::Early, []
{
	FAngelscriptBinds::ValueClass<FRotator>("FRotator", { .bPOD = true });
});

