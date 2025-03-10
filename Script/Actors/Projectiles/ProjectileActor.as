class AProjectileActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent Root;

    UPROPERTY(DefaultComponent)
    UCapabilityComponent CapabilityComponent;

    UProjectileMeshData MeshDataAsset;
    AActor SourceActor;
    TArray<AActor> IgnoredActors;
    bool bActivated = false;

    default Root.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    default Root.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
    default Root.SetGenerateOverlapEvents(true);

    void SetMeshData(UProjectileMeshData InMeshData)
    {
        MeshDataAsset = InMeshData;
        if (IsValid(MeshDataAsset) && IsValid(MeshDataAsset.ProjectileMesh))
        {
            Root.SetStaticMesh(MeshDataAsset.ProjectileMesh);
            SetActorScale3D(MeshDataAsset.Scale);
        }
    }

    void SetSourceActor(AActor InSource)
    {
        SourceActor = InSource;
    }

    void Fire()
    {
        bActivated = true;
    }

};