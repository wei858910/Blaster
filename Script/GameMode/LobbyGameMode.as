class ALobbyGameMode : AGameModeBase
{
    UFUNCTION(BlueprintOverride)
    void OnPostLogin(APlayerController NewPlayer)
    {
        int32 NumberOfPlayers = GetNumPlayers();
        PrintWarning(f"Number of players: {NumberOfPlayers}", 10.0);

        APlayerState PlayerState = NewPlayer.PlayerState;
        if (IsValid(PlayerState))
        {
            FString PlayerName = PlayerState.PlayerName;
            PrintWarning(f"Player {PlayerName} has joined the game.", 10.0);
        }
    }

    UFUNCTION(BlueprintOverride)
    void OnLogout(AController ExitingController)
    {
        APlayerController PlayerController = Cast<APlayerController>(ExitingController);
        if (IsValid(PlayerController))
        {
            APlayerState PlayerState = PlayerController.PlayerState;
            if (IsValid(PlayerState))
            {
                FString PlayerName = PlayerState.PlayerName;
                PrintWarning(f"Player {PlayerName} has left the game.", 10.0);
            }
        }
    }
};