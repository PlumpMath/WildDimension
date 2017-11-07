namespace Achievements {

    VariantMap achievementList;

    void Init()
    {
        achievementList["GetAxe"] = false;
        achievementList["GetTrap"] = false;
    }

    void Subscribe()
    {
        SubscribeToEvent("UnlockAchievement", "Achievements::HandleAchievement");
    }

    void RegisterConsoleCommands()
    {
        /*
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "get_axe";
        data["CONSOLE_COMMAND_EVENT"] = "GetAxe";
        SendEvent("ConsoleCommandAdd", data);
        */
    }

    void HandleAchievement(StringHash eventType, VariantMap& eventData)
    {
        if (eventData.Contains("Name") && eventData["Name"].type == VAR_STRING) {
            String name = eventData["Name"].GetString();
            if (achievementList.Contains(name)) {
                if (achievementList[name] == false) {
                    log.Info("Achievement [" + name +"] unlocked!");
                    
                    VariantMap data;
                    data["Message"] = "Achievement [" + name +"] unlocked!";
                    SendEvent("UpdateEventLogGUI", data);
                }
                achievementList[name] = true;
            }
        }
    }
}