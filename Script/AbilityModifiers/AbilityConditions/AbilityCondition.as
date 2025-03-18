UCLASS(Abstract, Blueprintable, EditInlineNew)
class UAbilityCondition : UObject
{
    UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category="Condition")
    EConditionEvaluationType EvaluationType = EConditionEvaluationType::ECE_AND;
        
    UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category="Condition")
    bool bInvertCondition = false;

    UFUNCTION(BlueprintEvent, Category="Condition")
    bool IsConditionMet(const UAbilityCapability Ability) const 
    { 
        if (!IsValid(Ability))
            return false;

        if(!IsValid(Ability.AbilityComp))
            return false;

        return true;
    }
}

enum EConditionEvaluationType
{
    ECE_AND,
    ECE_OR
}