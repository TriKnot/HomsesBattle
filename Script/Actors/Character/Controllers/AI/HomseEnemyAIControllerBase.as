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

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Senses")
    FVector EyeHeightOffset = FVector(0.0f, 0.0f, 45.0f);


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
                OnActorNotSensed(Actor);
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

    bool HasLineOfSight(const AActor Target)
    {
        if (Target == nullptr)
            return false;
        
        APawn Pawn = GetControlledPawn();
        if (Pawn == nullptr)
            return false;

        // Get Target's center and extent.
        FVector TargetCenter, TargetExtent;
        Target.GetActorBounds(true, TargetCenter, TargetExtent);
        float TargetWidth  = TargetExtent.X * 2.0f;  // full width
        float TargetHeight = TargetExtent.Z * 2.0f;  // full height

        // Get Pawn's location and direction to target.
        FVector PawnLocation = Pawn.GetActorLocation();
        FVector DirToTarget = (TargetCenter - PawnLocation).GetSafeNormal();
        
        // Set Target point behind the target.
        const float OffsetDistance = 250.0f; // adjust as needed
        FVector BasePoint = TargetCenter + DirToTarget * OffsetDistance;
        
        // Find up and right directions relative to the target.
        FVector UpDir = FVector(0, 0, 1);
        FVector RightDir = DirToTarget.CrossProduct(UpDir).GetSafeNormal();
        UpDir = RightDir.CrossProduct(DirToTarget).GetSafeNormal();
        
        // Set up the line trace parameters
        const int GridResultion = 5;  
        TArray<AActor> ActorsToIgnore;
        ActorsToIgnore.Add(Pawn);
        
        // Loop over rows and columns and line to sample points in a grid.
        for (int32 row = 0; row < GridResultion; ++row)
        {
            // Calculate the height of the row.
            float RowHeight = 1.0f - (2.0f * row / (GridResultion - 1));
            
            for (int32 col = 0; col < GridResultion; ++col)
            {
                // Calculate the width of the column.
                float ColumnWidth = -1.0f + (2.0f * col / (GridResultion - 1));
                
                // Calculate the sample point.
                FVector SamplePoint = BasePoint 
                                    + RightDir * (ColumnWidth * TargetWidth * 0.5f)
                                    + UpDir    * (RowHeight * TargetHeight * 0.5f);
                
                FHitResult HitResult;
                System::LineTraceSingleByProfile(
                    PawnLocation + EyeHeightOffset,
                    SamplePoint,
                    n"Visibility",
                    false,
                    ActorsToIgnore,
                    EDrawDebugTrace::None, 
                    HitResult,
                    true,
                    FLinearColor::Red,
                    FLinearColor::Green,
                    10.0f
                );
                
                // If we hit the target, we have line of sight.
                if (HitResult.bBlockingHit && HitResult.GetActor() == Target)
                {
                    // System::DrawDebugBox(
                    //     TargetCenter,
                    //     TargetExtent,
                    //     FLinearColor::Green,
                    //     FRotator::ZeroRotator,
                    //     10.0f,
                    //     3.0f
                    // );
                    return true; // Exit early if we hit the target.
                }
            }
        }
        
        return false; // No line of sight.
    }


}
