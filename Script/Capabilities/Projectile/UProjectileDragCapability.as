class UProjectileDragCapability : UCapability
{
    default Priority = ECapabilityPriority::PostMovement;

    AProjectileActor ProjectileOwner;
    UProjectileMoveComponent MoveComponent;

    float CrossSectionalArea = 0.01f;
    
    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ProjectileOwner = Cast<AProjectileActor>(Owner);
        MoveComponent = UProjectileMoveComponent::GetOrCreate(ProjectileOwner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate()
    {
        return ProjectileOwner.bActivated 
            && !MoveComponent.ProjectileVelocity.IsNearlyZero();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate()
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivate()
    {
        CrossSectionalArea = GetCalculatedCrossSectionalAreaFromMesh();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FVector VelocityCm = MoveComponent.ProjectileVelocity;
        float SpeedCm = VelocityCm.Size();

        if (SpeedCm <= KINDA_SMALL_NUMBER)
            return;

        float SpeedM = SpeedCm / 100.f;
        FVector VelocityM = VelocityCm / 100.f;

        float DragMagnitude = 0.5f * MoveComponent.DragCoefficient * CrossSectionalArea * MoveComponent.FluidDensity * SpeedM * SpeedM;
        FVector DragForce = -VelocityM.GetSafeNormal() * DragMagnitude;
        FVector Acceleration = DragForce * 100.f;  

        FVector DeltaVelocityCm = Acceleration * DeltaTime;

        if (DeltaVelocityCm.SizeSquared() >= VelocityCm.SizeSquared())
        {
            MoveComponent.ProjectileVelocity = FVector::ZeroVector;
        }
        else
        {
            MoveComponent.ProjectileVelocity += DeltaVelocityCm;
        }
    }

    float GetCalculatedCrossSectionalAreaFromMesh()
    {
        UStaticMeshComponent MeshComp = ProjectileOwner.Root;
        if (IsValid(MeshComp) && IsValid(MeshComp.StaticMesh))
        {
            // Get bounding sphere radius (simple approximation)
            float RadiusMeters = (MeshComp.Bounds.SphereRadius * ProjectileOwner.GetActorScale3D().GetAbsMax()) / 100.f;

            // Cross-sectional area (sphere): A = πr²
            return PI * RadiusMeters * RadiusMeters;
        }
        return 0.01f;
    }
};
