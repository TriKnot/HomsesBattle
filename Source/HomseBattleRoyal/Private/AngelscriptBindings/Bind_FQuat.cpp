#pragma once
#include "AngelscriptBindings/Bind_FQuat.h"

#include "Math/Quat.h"
#include "AngelscriptBinds.h"

AS_FORCE_LINK const FAngelscriptBinds::FBind Bind_FQuat((int32)FAngelscriptBinds::EOrder::Normal, []
{
	auto QuatBind = FAngelscriptBinds::ValueClass<FQuat>("FQuat", { .bPOD = true });

	// Binding Rotator() method from FQuat
	QuatBind.Method("FRotator Rotator() const", METHOD_TRIVIAL(FQuat, Rotator));
});
