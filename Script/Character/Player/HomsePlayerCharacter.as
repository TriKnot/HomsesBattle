class ASHomsePlayerCharacter : AHomsePlayerCharacter
{

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Print("Hello World!");
    }
}