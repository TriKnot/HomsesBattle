class UProjectileDamageComponent : UActorComponent
{
    FHitResult MovementHitResult;
    TArray<AActor> IgnoredActors;
    UProjectileDamageData DamageDataAsset;
};