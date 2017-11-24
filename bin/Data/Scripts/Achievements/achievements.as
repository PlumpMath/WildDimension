namespace Achievements {

    class AchievementItem {
        String name;
        String eventName;
        float current;
        float target;
        bool completed;
    };

    Array<AchievementItem> achievementList;

    void AddAchievement(Array<AchievementItem> list)
    {
        for (uint i = 0; i < list.length; i++) {
            achievementList.Push(list[i]);
        }
    }

    void Init()
    {
        AddAchievement(AchievementsAxe::GetAchievments());
        AddAchievement(AchievementsTrap::GetAchievments());
        AddAchievement(AchievementsHit::GetAchievments());
        AddAchievement(AchievementsBranch::GetAchievments());
        AddAchievement(AchievementsPlaces::GetAchievments());
    }

    void Subscribe()
    {
        SubscribeToEvent("UnlockAchievement", "Achievements::HandleAchievement");
        SubscribeToEvent("AchievementStatistics", "Achievements::HandleAchievementStatistics");
    }

    void RegisterConsoleCommands()
    {
        
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "achievments";
        data["CONSOLE_COMMAND_EVENT"] = "AchievementStatistics";
        SendEvent("ConsoleCommandAdd", data);
        
    }

    void UnlockAchievement(String eventName, float value)
    {
        for (uint i = 0; i < achievementList.length; i++) {
            AchievementItem@ item = achievementList[i];
            if (item.eventName == eventName) {
                item.current += value;
                if (item.target <= item.current && item.completed == false) {
                    item.completed = true;
                    VariantMap data;
                    data["Message"] = "Achievement [" + item.name +"] unlocked!";
                    SendEvent("UpdateEventLogGUI", data);

                    GameSounds::Play(GameSounds::ACHIEVEMENT_UNLOCKED, 0.1);
                }
            }
        }
    }

    void HandleAchievement(StringHash eventType, VariantMap& eventData)
    {
        SendEvent("MissionCompleted", eventData);
        if (eventData.Contains("Name") && eventData["Name"].type == VAR_STRING) {
            String name = eventData["Name"].GetString();
            Array<Variant> parameters;
            parameters.Push(Variant(name));
            parameters.Push(Variant(1.0f));
            DelayedExecute(1.0, false, "void Achievements::UnlockAchievement(String, float)", parameters);
        }
    }

    void HandleAchievementStatistics(StringHash eventType, VariantMap& eventData)
    {
        float completed = 0;
        for (uint i = 0; i < achievementList.length; i++) {
            if (achievementList[i].completed) {
                completed+=1;
            }
        }
        log.Info("------ Achievments ------");
        float ratio = completed / achievementList.length;
        log.Info("Completed/Total: " + completed + "/" + achievementList.length + "(" + ratio * 100 + "%)");
        log.Info("-------------------------");
    }

    uint GetTotalAchievementsCount()
    {
        return achievementList.length;
    }

    uint GetCompletedAchievementsCount()
    {
        int completed = 0;
        for (uint i = 0; i < achievementList.length; i++) {
            if (achievementList[i].completed) {
                completed++;
            }
        }
        return completed;
    }
}