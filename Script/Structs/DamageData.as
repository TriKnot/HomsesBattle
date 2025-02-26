struct FDamageData 
{
    UPROPERTY()
    private float Damage;

    UPROPERTY()
    TArray<UOnHitEffectData> OnHitEffects;

    private AActor Source;
    private FVector DamageDir;
    private FVector DamageLoc;

    float GetDamageAmount() const property
    {
        return Damage;
    }

    AActor GetSourceActor() const property
    {
        return Source;
    }

    FVector GetDamageDirection() const property
    {
        return DamageLoc - Source.GetActorLocation();
    }

    FVector GetDamageLocation() const property
    {
        return DamageLoc;
    }

    void SetSourceActor(AActor InSource) 
    {
        Source = InSource;
    }

    void SetDamageLocation(FVector InDamageLoc) 
    {
        DamageLoc = InDamageLoc;
    }


}