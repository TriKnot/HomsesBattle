class UPlayerInputComponent : ULockableComponent
{
    ASPlayerController PlayerController;
    UCapabilityComponent CapabilityComponent;

    TMap<FKey, FKeyToActions> KeyToActions;

    void BindKeys(ASPlayerController inController)
    {
        PlayerController = inController;
        CapabilityComponent = PlayerController.ControlledPawnRef.CapabilityComponent;

        // Bind movement keys
        BindKey(InputActions::MovementUp, EKeys::W);
        BindKey(InputActions::MovementDown, EKeys::S);
        BindKey(InputActions::MovementRight, EKeys::D);
        BindKey(InputActions::MovementLeft, EKeys::A);

        // Bind mouse axis
        PlayerController.InputComponent.BindAxis(n"Yaw", FInputAxisHandlerDynamicSignature(this, n"OnMouseX"));
        PlayerController.InputComponent.BindAxis(n"Pitch", FInputAxisHandlerDynamicSignature(this, n"OnMouseY"));
        
        // Bind action keys
        BindKey(InputActions::Jump, EKeys::SpaceBar);
        BindKey(InputActions::Dash, EKeys::LeftShift);
        BindKey(InputActions::Test, EKeys::LeftAlt);
        BindKey(InputActions::PrimaryAttack, EKeys::LeftMouseButton);
        BindKey(InputActions::SecondaryAttack, EKeys::RightMouseButton);

    }

    private void BindKey(FName Action, FKey Key)
    {
        auto& KeyToAction = KeyToActions.FindOrAdd(Key);
        if(!KeyToAction.Actions.AddUnique(Action))
        {
            PrintError("Action already bound to key | UInputComponent.BindKey");
        }

        FInputActionHandlerDynamicSignature DownKeyDelegate;
        DownKeyDelegate.BindUFunction(this, n"OnKeyDown");
        PlayerController.InputComponent.BindKey(Key, EInputEvent::IE_Pressed, DownKeyDelegate);

        FInputActionHandlerDynamicSignature UpKeyDelegate;
        UpKeyDelegate.BindUFunction(this, n"OnKeyUp");
        PlayerController.InputComponent.BindKey(Key, EInputEvent::IE_Released, UpKeyDelegate);
    }

    UFUNCTION()
    private void OnKeyDown(FKey Key)
    {
        if(KeyToActions.Contains(Key))
        {
            for(const FName& Action : KeyToActions[Key].Actions)
            {
                CapabilityComponent.Actions.FindOrAdd(Action) = true;
            }
        }
    }

    UFUNCTION()
    private void OnKeyUp(FKey Key)
    {
        if(KeyToActions.Contains(Key))
        {
            for(const FName& Action : KeyToActions[Key].Actions)
            {
                CapabilityComponent.Actions.FindOrAdd(Action) = false;
            }
        }
    }

    UFUNCTION()
    bool GetKeyDown(FName Action)
    {
        return CapabilityComponent.Actions.FindOrAdd(Action);
    }

    UFUNCTION()
    private void OnMouseX(float32 Value)
    {
        CapabilityComponent.MouseInputDelta.X = Value; 
    }

    UFUNCTION()
    private void OnMouseY(float32 Value)
    {
        CapabilityComponent.MouseInputDelta.Y = Value; 
    }

}

struct FKeyToActions
{
    TArray<FName> Actions;
};