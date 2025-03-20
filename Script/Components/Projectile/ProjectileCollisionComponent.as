class UProjectileCollisionComponent : UActorComponent
{
    FHitResult MovementHitResult;
    TArray<AActor> IgnoredActors;
    bool bAllowDestroy = true;
};