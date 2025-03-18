class UOrientToControllerRotationAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere, Category="Orientation")
    bool bEnableOnActivation = false;

    UPROPERTY(EditAnywhere, Category="Orientation")
    bool bEnableDuringWarmUp = false;

    UPROPERTY(EditAnywhere, Category="Orientation")
    bool bEnableDuringActive = false;

    UPROPERTY(EditAnywhere, Category="Orientation")
    bool bEnableOnCooldown = false;

    UHomseMovementComponent MoveComp;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        if(!IsValid(Ability))
            return;

        MoveComp = UHomseMovementComponent::Get(Ability.Owner);
        if(!IsValid(MoveComp))
            return;
        
        MoveComp.SetOrientRotationToMovement(!bEnableOnActivation);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityDeactivate(UAbilityCapability Ability)
    {
        if(!IsValid(MoveComp))
            return;

        MoveComp.SetOrientRotationToMovement(true);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityWarmUpTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(MoveComp))
            return;

        MoveComp.SetOrientRotationToMovement(!bEnableDuringWarmUp);        
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityActiveTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(MoveComp))
            return;

        MoveComp.SetOrientRotationToMovement(!bEnableDuringActive);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityCooldownTick(UAbilityCapability Ability, float DeltaTime)
    {
        if(!IsValid(MoveComp))
            return;

        MoveComp.SetOrientRotationToMovement(!bEnableOnCooldown);
    }

}
