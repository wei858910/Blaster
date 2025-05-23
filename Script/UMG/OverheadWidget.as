class UOverheadWidget : UUserWidget
{
    UPROPERTY(BindWidget)
    UTextBlock DisplayText;

    void SetDisplayText(FString TextToDisplay)
    {
        if (IsValid(DisplayText))
        {
            DisplayText.SetText(FText::FromString(TextToDisplay));
        }
    }

    void ShowPlayerNetRole(APawn InPawn)
    {
        if (IsValid(InPawn))
        {
            ENetRole LocalRole = InPawn.GetLocalRole();
            FString  Role;
            switch (LocalRole)
            {
                case ENetRole::ROLE_Authority:
                    Role = "Authority";
                    break;
                case ENetRole::ROLE_AutonomousProxy:
                    Role = "AutonomousProxy";
                    break;
                case ENetRole::ROLE_SimulatedProxy:
                    Role = "SimulatedProxy";
                    break;
                case ENetRole::ROLE_None:
                    break;
            }
            FString LocalRoleString = FString::Format("Local Role: {0}", Role);
            SetDisplayText(LocalRoleString);
        }
    }

    UFUNCTION(BlueprintOverride)
    void Destruct()
    {
        RemoveFromParent();
    }
};