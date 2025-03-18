class ASPlayerController : APlayerController
{
    default OverridePlayerInputClass = UEnhancedPlayerInput::StaticClass();
    default bShowMouseCursor = false;

    UPROPERTY(Category = "Input", DefaultComponent)
    UEnhancedInputComponent InputComponent;

    UPROPERTY(Category = "Input", DefaultComponent)
    UPlayerInputComponent PlayerInputComponent;

    access InputControlProtection = private, UPlayerInputComponent;
    access:InputControlProtection AHomseCharacterBase ControlledPawnRef;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PushInputComponent(InputComponent);
        ControlledPawnRef = Cast<AHomseCharacterBase>(ControlledPawn);

        PlayerInputComponent.BindKeys(this);
    }
}