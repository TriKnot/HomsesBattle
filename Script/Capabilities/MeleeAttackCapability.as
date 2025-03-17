// class UMeleeAttackCapability : UAbilityCapability
// {
//     default Priority = ECapabilityPriority::PostInput;

//     // Components and Data
//     USphereComponent HitSphere;
//     UHomseMovementComponent MoveComp;
//     UMeleeAttackData MeleeAbilityData;

//     // State
//     float InitialVelocity;
//     TArray<AActor> HitActors;
//     UAsyncRootMovement AsyncRootMove;


//     UFUNCTION(BlueprintOverride)
//     void Setup()
//     {
//         Super::Setup();

//         HitSphere = USphereComponent::Create(Owner);
//         HitSphere.CollisionProfileName = n"Custom";
//         HitSphere.CollisionEnabled = ECollisionEnabled::QueryOnly;
//         HitSphere.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
//         HitSphere.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);
//         HitSphere.SetSphereRadius(50.0f);

//         MoveComp = UHomseMovementComponent::Get(Owner);
//     }

//     UFUNCTION(BlueprintOverride)
//     void Teardown()
//     {
//         HitSphere.DestroyComponent(HitSphere);
//     }

//     UFUNCTION(BlueprintOverride)
//     bool ShouldActivate()
//     {
//         return !AbilityComp.IsLocked() && AbilityComp.IsAbilityActive(this);
//     }

//     UFUNCTION(BlueprintOverride)
//     bool ShouldDeactivate() 
//     { 
//         return CooldownTimer.IsFinished();
//     }

//     UFUNCTION(BlueprintOverride)
//     void OnActivate()
//     {
//         // Retrieve melee ability data and initialize the cooldown timer
//         MeleeAbilityData = Cast<UMeleeAttackData>(AbilityComp.GetAbilityData(this));
//         CooldownTimer.SetDuration(MeleeAbilityData.CooldownTime);

//         // Reset hit actor list
//         HitActors.Empty();

//         // Attach hit sphere to socket defined in ability data
//         HitSphere.AttachToComponent(HomseOwner.Mesh, MeleeAbilityData.Socket);

//         // Rotate character to match camera if grounded
//         if (MoveComp.IsGrounded)
//         {
//             //AbilityHelpers::RotateActorToCameraRotation(HomseOwner);
//         }

//         // Dash in the forward direction, ignoring pitch
//         FRotator DashRotation = HomseOwner.GetActorRotation();
//         DashRotation.Pitch = 0.0f;
//         DashRotation.Normalize();
//         Dash(DashRotation.Vector());

//         // Process any actors immediately hit by the sphere
//         ProcessInitialHits();

//         // Bind overlap event to detect further hits during dash
//         HitSphere.OnComponentBeginOverlap.AddUFunction(this, n"OnHit");

//         // Reset cooldown and lock movement/ability states
//         CooldownTimer.Reset();
//         MoveComp.Lock(this);
//         AbilityComp.Lock(this);

//         // Bind finish event to unlock movement/ability states
//         AsyncRootMove.OnMovementFailed.AddUFunction(this, n"OnFinishedDashing");
//         AsyncRootMove.OnMovementFinished.AddUFunction(this, n"OnFinishedDashing");
//     }

//     UFUNCTION(BlueprintOverride)
//     void TickActive(float DeltaTime)
//     {
//         CooldownTimer.Tick(DeltaTime);
        
//         // If dash is finished, start cooldown and restore normal movement orientation
//         if (!IsValid(AsyncRootMove) || !AsyncRootMove.IsActive()) 
//         {
//             CooldownTimer.Start();
//             //MoveComp.SetOrientToMovement(true);
//             return;   
//         }
        
//         // Visualize hit sphere for debugging purposes
//         System::DrawDebugSphere(HitSphere.GetWorldLocation(), HitSphere.SphereRadius, 12, FLinearColor::Red, 0);
//     }

//     // Called when the hit sphere overlaps with another actor
//     UFUNCTION()
//     void OnHit(UPrimitiveComponent OverLappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
//     {
//         UHealthComponent HitHealthComp = UHealthComponent::Get(OtherActor);
//         if (!IsValid(HitHealthComp))
//             return;

//         DealDamageToHealthComponent(HitHealthComp);
//     }

//     // Check for immediate hit actors and apply damage
//     void ProcessInitialHits()
//     {
//         TArray<UHealthComponent> HitHealthComps;
//         if (AbilityHelpers::TryGetHitHealthComponents(Cast<UPrimitiveComponent>(HitSphere), HitHealthComps))
//         {
//             for (UHealthComponent HitHealthComp : HitHealthComps)
//             {
//                 DealDamageToHealthComponent(HitHealthComp);
//             }
//         }
//     }

//     // Deal damage to a health component and record that the actor has been hit
//     void DealDamageToHealthComponent(UHealthComponent HealthComp)
//     {
//         AActor HitActor = HealthComp.GetOwner();
//         if (HitActor == Owner || HitActors.Contains(HitActor))
//             return;

//         FDamageData DamageInstance = MeleeAbilityData.DamageData;
//         DamageInstance.SetSourceActor(Owner);
//         DamageInstance.SetDamageLocation(HitSphere.GetWorldLocation());
//         HealthComp.AddDamageInstanceData(DamageInstance);
//         HitActors.AddUnique(HitActor);
//     }

//     // Dash the character in a given direction using asynchronous root movement
//     void Dash(FVector DashDirection)
//     {
//         InitialVelocity = MoveComp.Velocity.Size();

//         AsyncRootMove = UAsyncRootMovement::ApplyConstantForce(
//             MoveComp.CharacterMovement, 
//             DashDirection, 
//             MeleeAbilityData.DashStrength, 
//             MeleeAbilityData.ActiveDuration, 
//             false, 
//             nullptr, 
//             true, 
//             ERootMotionFinishVelocityMode::ClampVelocity, 
//             FVector::ZeroVector, 
//             InitialVelocity * 2
//         );
//     }

//     UFUNCTION()
//     void OnFinishedDashing()
//     {
//         MoveComp.Unlock(this);
//         AbilityComp.Unlock(this);
//         AsyncRootMove = nullptr;
//     }
// };