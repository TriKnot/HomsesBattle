#include "Libraries/DuplicateObjectBlueprintLibrary.h"

UObject* UDuplicateObjectBlueprintLibrary::DuplicateObjectBlueprint(UObject* SourceObject, UObject* Outer)
{
	// Basic validation: if either parameter is null, return null.
	if (!SourceObject || !Outer)
	{
		return nullptr;
	}
	// Duplicate the object using Unreal's built-in DuplicateObject.
	return DuplicateObject(SourceObject, Outer);
}