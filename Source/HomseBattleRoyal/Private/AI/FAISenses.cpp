#include "AI/FAISenses.h"
#include "Perception/AISense_Damage.h"
#include "Perception/AISense_Hearing.h"
#include "Perception/AISense_Sight.h"
#include "Perception/AISense_Touch.h"

// Check if any sense has been used
bool FAISensesReport::HasAnySenseBeenUsed() const
{
	return bSightUsed || bHearingUsed || bDamageUsed || bTouchUsed;
}

// Reset all senses to unused
void FAISensesReport::ResetSenses()
{
	bSightUsed = false;
	bHearingUsed = false;
	bDamageUsed = false;
	bTouchUsed = false;
}

void FAISensesReport::AddStimulus(const FAIStimulus& Stimulus, AActor* Actor, const FVector& Location)
{
	if(Stimulus.Type == UAISense::GetSenseID<UAISense_Sight>())
	{
		LastSensedSightStimulus = Stimulus;
		MarkSenseUsed(EAISenses::EAS_Sight);
	}
	if(Stimulus.Type == UAISense::GetSenseID<UAISense_Hearing>())
	{
		LastSensedHearingStimulus = Stimulus;
		MarkSenseUsed(EAISenses::EAS_Hearing);
	}
	if(Stimulus.Type == UAISense::GetSenseID<UAISense_Damage>())
	{
		LastSensedDamageStimulus = Stimulus;
		MarkSenseUsed(EAISenses::EAS_Damage);
	}
	if(Stimulus.Type == UAISense::GetSenseID<UAISense_Touch>())
	{
		LastSensedTouchStimulus = Stimulus;
		MarkSenseUsed(EAISenses::EAS_Touch);
	}

	LastSensedActor = Actor;
	LastSensedLocation = Location;
}

// Mark a specific sense as used
void FAISensesReport::MarkSenseUsed(const EAISenses Sense)
{
	if (Sense == EAISenses::EAS_Sight)
	{
		bSightUsed = true;
	}
	else if (Sense == EAISenses::EAS_Hearing)
	{
		bHearingUsed = true;
	}
	else if (Sense == EAISenses::EAS_Damage)
	{
		bDamageUsed = true;
	}
	else if (Sense == EAISenses::EAS_Touch)
	{
		bTouchUsed = true;
	}
}


bool FAISensesReport::IsSenseUsed(const EAISenses Sense) const
{
	if (Sense == EAISenses::EAS_Sight)
	{
		return bSightUsed;
	}
	if (Sense == EAISenses::EAS_Hearing)
	{
		return bHearingUsed;
	}
	if (Sense == EAISenses::EAS_Damage)
	{
		return bDamageUsed;
	}
	if (Sense == EAISenses::EAS_Touch)
	{
		return bTouchUsed;
	}
	return false;
}

void FAISensesReport::CombineWith(const FAISensesReport& Other)
{
	bSightUsed |= Other.bSightUsed;
	bHearingUsed |= Other.bHearingUsed;
	bDamageUsed |= Other.bDamageUsed;
	bTouchUsed |= Other.bTouchUsed;
}


//////////////////////////////////////////////////////////////////////////
///////////////////////	Blueprint Library ////////////////////////////////
//////////////////////////////////////////////////////////////////////////

bool UAISensesReportLibrary::HasAnySenseBeenUsed(const FAISensesReport& Report)
{
	return Report.HasAnySenseBeenUsed();
}

void UAISensesReportLibrary::ResetSenses(FAISensesReport& Report)
{
	Report.ResetSenses();
}

void UAISensesReportLibrary::AddStimulus(FAISensesReport& Report, const FAIStimulus& Stimulus, AActor* Actor, const FVector& Location)
{
	Report.AddStimulus(Stimulus, Actor, Location);
}

void UAISensesReportLibrary::MarkSenseUsed(FAISensesReport& Report, EAISenses Sense)
{
	Report.MarkSenseUsed(Sense);
}

bool UAISensesReportLibrary::IsSenseUsed(const FAISensesReport& Report, EAISenses Sense)
{
	return Report.IsSenseUsed(Sense);
}

void UAISensesReportLibrary::CombineWith(FAISensesReport& Report, const FAISensesReport& Other)
{
	Report.CombineWith(Other);
}