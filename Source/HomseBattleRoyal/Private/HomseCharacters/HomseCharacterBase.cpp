#include "HomseCharacters/HomseCharacterBase.h"

#include "GameFramework/CharacterMovementComponent.h"

void AHomseCharacterBase::SetMovementSpeed(EMovementSpeed Speed)
{
	switch (Speed)
	{
	case EMovementSpeed::EMS_Walk:
		GetCharacterMovement()->MaxWalkSpeed = WalkSpeed;
		break;
	case EMovementSpeed::EMS_Run:
		GetCharacterMovement()->MaxWalkSpeed = RunSpeed;
		break;
	case EMovementSpeed::EMS_Sprint:
		GetCharacterMovement()->MaxWalkSpeed = SprintSpeed;
		break;
	default: ;
	}
}
