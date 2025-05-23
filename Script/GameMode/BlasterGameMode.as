class ABlasterGameMode : AGameModeBase
{
    default DefaultPawnClass = ABlasterCharacter;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
    }
};