class UCapabilityComponent : UActorComponent
{
    UPROPERTY()
    TArray<TSubclassOf<UCapability>> CapabilitiesTypes;

    UPROPERTY(NotEditable)
    private TArray<UCapability> Capabilities;

    access ActionProtection = protected, UPlayerInputComponent;
    access:ActionProtection TMap<FName, bool> Actions;
    
    access MouseDeltaProtection = protected, UPlayerInputComponent;
    access:MouseDeltaProtection FVector2D MouseInputDelta;

    TArray<TSubclassOf<UCapability>> AddCapabilityQueue;
    TArray<TSubclassOf<UCapability>> RemoveCapabilityQueue;

    bool bShouldInitialize = true;
    bool bIsInEndPlay = false;

    bool GetActionStatus(FName Action) property
    {
        return Actions.FindOrAdd(Action);
    }

    FVector2D GetMouseDelta() property
    {
        return MouseInputDelta;
    }

    FVector2D GetMovementInput() property
    {
        FVector2D MoveInput = FVector2D::ZeroVector;
        if(GetActionStatus(InputActions::MovementDown))
            MoveInput.Y -= 1.0f;
        if(GetActionStatus(InputActions::MovementUp))
            MoveInput.Y += 1.0f;

        if(GetActionStatus(InputActions::MovementLeft))
            MoveInput.X -= 1.0f;
        if(GetActionStatus(InputActions::MovementRight))
            MoveInput.X += 1.0f;

        return MoveInput.GetSafeNormal();
    }

    UCapability GetCapability(TSubclassOf<UCapability> CapabilityType)
    {
        for(UCapability& Capability : Capabilities)
        {
            if (Capability.Class == CapabilityType)
            {
                return Capability;
            }
        }

        return nullptr;
    }

    bool AddCapability(TSubclassOf<UCapability> CapabilityType)
    {
        if (bIsInEndPlay) // Exit early if we are in EndPlay
        {
            return false;
        }

        // Check if the capability is already added
        for(auto& Capability : Capabilities)
        {
            if (Capability.Class == CapabilityType)
            {
                return false;
            }
        }

        // Check if the capability is already in the queue to be added
        if (AddCapabilityQueue.Contains(CapabilityType))
        {
            return false;
        }

        AddCapabilityQueue.Add(CapabilityType);

        return true;
    }

    bool RemoveCapability(TSubclassOf<UCapability> CapabilityType)
    {
        if (bIsInEndPlay) // Exit early if we are in EndPlay
        {
            return false;
        }

        // Check if the capability is already in the queue to be removed
        if (RemoveCapabilityQueue.Contains(CapabilityType))
        {
            return false;
        }

        // Check if a capability of this type exists to be removed
        for(int i = 0; i < Capabilities.Num(); i++)
        {
            UCapability& Capability = Capabilities[i];
            if (Capability.Class == CapabilityType)
            {
                RemoveCapabilityQueue.Add(CapabilityType);
                return true;
            }
        }

        return false;
    }

    private void ProcessAddCapabilityQueue()
    {
        while (!AddCapabilityQueue.IsEmpty())
        {
            TSubclassOf<UCapability> CapabilityType = AddCapabilityQueue[0];
            AddCapabilityQueue.RemoveAt(0);

            UCapability Capability = Cast<UCapability>(NewObject(this, CapabilityType));
            Capability.Initialize(this, Owner);
            bool added = false;
            for(int i = 0; i < Capabilities.Num(); i++)
            {
                if (Capability.Priority < Capabilities[i].Priority)
                {
                    Capabilities.Insert(Capability, i);
                    added = true;
                    break;
                }
            }
            if (!added)
            {
                Capabilities.Add(Capability);
            }
            Capability.Setup();
        }
    }

    private void ProcessRemoveCapabilityQueue()
    {
        while (!RemoveCapabilityQueue.IsEmpty())
        {
            TSubclassOf<UCapability> CapabilityType = RemoveCapabilityQueue[0];
            RemoveCapabilityQueue.RemoveAt(0);

            for(int i = 0; i < Capabilities.Num(); i++)
            {
                UCapability& Capability = Capabilities[i];
                if (Capability.Class == CapabilityType)
                {
                    if(Capability.bIsActive && !Capability.bIsBlocked)
                    {
                        Capability.OnDeactivate();
                    }

                    Capability.Teardown();
                    Capabilities.RemoveAt(i);
                    break;
                }
            }
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(bShouldInitialize)
        {
            Initialize();
        }

        // Activate
        for(UCapability& Capability : Capabilities)
        {
            if(!Capability.bIsActive && !Capability.bIsBlocked && Capability.ShouldActivate())
            {
                Capability.bIsActive = true;
                Capability.OnActivate();
            }

            if(Capability.bIsActive && !Capability.bIsBlocked)
            {
                Capability.TickActive(DeltaSeconds);
            }
        }

        // Deactivate
        for(UCapability& Capability : Capabilities)
        {
            if(Capability.bIsActive && Capability.ShouldDeactivate())
            {
                Capability.bIsActive = false;
                Capability.OnDeactivate();
            }
        }

        ProcessAddCapabilityQueue();
        ProcessRemoveCapabilityQueue();
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        bIsInEndPlay = true;
        for(UCapability& Capability : Capabilities)
        {
            if(Capability.bIsActive && !Capability.bIsBlocked)
            {
                Capability.bIsActive = false;
                Capability.OnDeactivate();
            }
            Capability.Teardown();
        }
        if(!Owner.IsActorBeingDestroyed())
            Capabilities.Empty();
    }

    private void Initialize()
    {
        bShouldInitialize = false;

        for(int i = 0; i < int(ECapabilityPriority::MAX); i++)
        {
            ECapabilityPriority Priority = ECapabilityPriority(i);
            for(TSubclassOf<UCapability>& CapabilityType : CapabilitiesTypes)
            {
                if (Cast<UCapability>(CapabilityType.Get().DefaultObject).Priority != Priority)
                    continue;

                UCapability Capability = Cast<UCapability>(NewObject(this, CapabilityType));
                if(Capability == nullptr)
                    continue;
                
                Capability.Initialize(this, Owner);
                Capabilities.Add(Capability);
                Capability.Setup();
            }
        }

    }
}