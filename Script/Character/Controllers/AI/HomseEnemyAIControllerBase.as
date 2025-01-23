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
    FName StateKeyName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI")
    EAIState StartingState = EAIState::EAIState_Patrol;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        AIPerceptionComponent.OnPerceptionUpdated.AddUFunction(this, n"OnPerceptionUpdated");
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

    bool CanSenseActor(const AActor Actor, const FActorPerceptionBlueprintInfo Info, FAISensesReport& SenseReport)
    {
        bool bCanSenseActor = false;
        for (FAIStimulus SenseInfo : Info.LastSensedStimuli)
        {
            if(Info.Target != Actor || !SenseInfo.bSuccessfullySensed)
                continue;

            AISensesReport::AddStimulus(SenseReport, SenseInfo, Info.Target, SenseInfo.StimulusLocation);
            bCanSenseActor = true;
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

    void OnNoActorSensed(AActor Actor)
    {
        if (Actor == nullptr)
            return;

        ClearTargetActor();

        EAIState CurrentState = GetState();

        if(CurrentState == EAIState::EAIState_Chasing)
        {
            SetState(EAIState::EAIState_Searching);
            return;
        }   

        //SetState(EAIState::EAIState_Patrol);
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
        Blackboard.SetValueAsObject(TargetActorKeyName, Actor);
    }

    void ClearTargetActor()
    {
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

}