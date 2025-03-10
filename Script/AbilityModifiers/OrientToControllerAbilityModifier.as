class UOrientToControllerRotationAbilityModifier : UAbilityModifier
{
    UPROPERTY(EditAnywhere)
    bool bOnActivation = false;

    UPROPERTY(EditAnywhere)
    bool bOnDeactivation = false;

    UPROPERTY(EditAnywhere)
    bool bDuringTick = false;

    UPROPERTY(EditAnywhere)
    bool bOnFire = false;

    UHomseMovementComponent MoveComp;

    UFUNCTION(BlueprintOverride)
    void OnAbilityActivate(UAbilityCapability Ability)
    {
        if (!IsValid(Ability))
            return;

        MoveComp = UHomseMovementComponent::Get(Ability.Owner);
        if (!IsValid(MoveComp))
            return;
        
        MoveComp.SetOrientRotationToMovement(!bOnActivation);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityDeactivate(UAbilityCapability Ability)
    {
        if (!IsValid(MoveComp))
            return;

        MoveComp.SetOrientRotationToMovement(!bOnDeactivation);
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityTick(UAbilityCapability Ability, float DeltaTime)
    {
        if (!IsValid(MoveComp))
            return;
        
        MoveComp.SetOrientRotationToMovement(!bDuringTick);    
    }

    UFUNCTION(BlueprintOverride)
    void OnAbilityFire(UAbilityCapability Ability)
    {
        if (!IsValid(MoveComp))
            return;

        MoveComp.SetOrientRotationToMovement(!bOnFire);    
    }
}
