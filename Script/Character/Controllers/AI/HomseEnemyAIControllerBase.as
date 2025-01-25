class ASHomseEnemyAIControllerBase : AHomseEnemyControllerBase
{
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Blackboard|Keys")
	FName SelfActorKeyName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Blackboard|Keys")
	FName TargetActorKeyName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Blackboard|Keys")
	FName DistanceToTargetKeyName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Blackboard|Keys")
	FName TargetLocationKeyName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Blackboard|Keys")
	FName PointOfInterestKeyName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Blackboard|Keys")
    FName AttackRangeKeyName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Blackboard|Keys")
    FName DefenceRangeKeyName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Blackboard|Keys")
    FName StateKeyName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI")
    EAIState StartingState = EAIState::EAIState_Patrol;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI")
    AActor TargetActor;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI")
    float AttackRange = 100.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI")
    float DefenceRange = 500.0f;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        AIPerceptionComponent.OnPerceptionUpdated.AddUFunction(this, n"OnPerceptionUpdated");

        Blackboard.SetValueAsFloat(AttackRangeKeyName, AttackRange);
        Blackboard.SetValueAsFloat(DefenceRangeKeyName, DefenceRange);

        SetState(StartingState);
    }

    UFUNCTION()
    void OnPerceptionUpdated(const TArray<AActor>&in UpdatedActors)
    {
        for (AActor Actor : UpdatedActors)
        {
            FActorPerceptionBlueprintInfo Info;
            AIPerceptionComponent.GetActorsPerception(Actor, Info);
            FAISensesReport SenseReport;
            if(CanSenseActor(Actor, Info, SenseReport)){
                OnActorSensed(Actor, SenseReport);
            }
            else
            {
                OnNoActorSensed(Actor);
            }

        }
    }

    UFUNCTION()
    bool CanSenseActor(const AActor Actor, const FActorPerceptionBlueprintInfo Info, FAISensesReport& SenseReport)
    {
        bool bCanSenseActor = false;
        for (FAIStimulus SenseInfo : Info.LastSensedStimuli)
        {
            if(Info.Target != Actor || !SenseInfo.bSuccessfullySensed)
                continue;

            AISensesReport::AddStimulus(SenseReport, SenseInfo, Info.Target, SenseInfo.StimulusLocation);

            if(SenseReport.bSightUsed)
            {
                if(HasLineOfSight(Actor))
                {
                    bCanSenseActor = true;
                }
            }
            else
            {
                bCanSenseActor = true;
            }
        }


        return bCanSenseActor;
    }

    void OnActorSensed(AActor Actor, FAISensesReport& SenseReport)
    {
        if (Actor == nullptr)
            return;

        if(SenseReport.bSightUsed)
        {
            HandleSensedSight(Actor, SenseReport);
        }
        else if(SenseReport.bHearingUsed)
        {
            HandleHeardNoise(Actor, SenseReport);
        }
    }

    void OnActorNotSensed(AActor Actor)
    {
        if (Actor == nullptr)
            return;

        EAIState CurrentState = GetState();

        if(CurrentState == EAIState::EAIState_Chasing)
        {
            SetState(EAIState::EAIState_Searching);
            return;
        }   

    }

    void HandleSensedSight(AActor Actor, FAISensesReport& SenseReport)
    {
        if (Actor == nullptr)
            return;

        SetTargetActor(Actor);
        SetState(EAIState::EAIState_Chasing);
    }

    void HandleHeardNoise(AActor Actor, FAISensesReport& SenseReport)
    {
        if (Actor == nullptr)
            return;

        Blackboard.SetValueAsVector(PointOfInterestKeyName, SenseReport.LastSensedLocation);
        SetState(EAIState::EAIState_Searching);
    }

    void SetTargetActor(AActor Actor)
    {
        TargetActor = Actor;
        Blackboard.SetValueAsObject(TargetActorKeyName, Actor);
    }

    void ClearTargetActor()
    {
        TargetActor = nullptr;
        Blackboard.ClearValue(TargetActorKeyName);
    }

    UFUNCTION()
    void SetState(EAIState State)
    {
        Blackboard.SetValueAsEnum(StateKeyName, uint8(State));
    }

    EAIState GetState()
    {
        return EAIState(Blackboard.GetValueAsEnum(StateKeyName));
    }

    bool HasLineOfSight(const AActor Actor)
    {
        if (Actor == nullptr)
            return false;

        FHitResult HitResult;
        FCollisionQueryParams CollisionParams;
        APawn Pawn = GetControlledPawn();
        CollisionParams.AddIgnoredActor(Pawn);
        FVector StartLocation = Pawn.GetActorLocation();
        FVector EndLocation = Actor.GetActorLocation();
        TArray<AActor> ActorsToIgnore;
        ActorsToIgnore.Add(Pawn);
        System::LineTraceSingleByProfile(StartLocation, EndLocation, n"Visibility", false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);

        return !HitResult.bBlockingHit || HitResult.GetActor() == Actor;
    }

}