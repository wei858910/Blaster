class ALobbyGameMode : AGameModeBase
{
    default DefaultPawnClass = ABlasterCharacter;

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

        if (NumberOfPlayers == 2)
        {
            bUseSeamlessTravel = true;
            if (IsValid(World))
            {
                World.ServerTravel("/Game/Maps/BlasterMap?listen", false, false);
            }
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