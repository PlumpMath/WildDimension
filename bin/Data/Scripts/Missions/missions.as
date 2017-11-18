namespace Missions {

    const uint TYPE_PICKUP = 0;
    const uint TYPE_REACH_POINT = 1;

    class MissionItem {
        String name;
        String description;
        String shortDescription;
        String eventName;
        String itemName;
        float current;
        float target;
        bool completed;
        uint type;
    };

    String activeMission;

    Array<MissionItem> missionList;

    void AddMission(MissionItem item)
    {
        log.Info("Adding mission " + item.name);
        missionList.Push(item);
        SendEvent("UpdateMissionsGUI");
    }

    bool CheckIfCompleted(MissionItem item)
    {
        if (item.type == TYPE_PICKUP) {
            if (Inventory::GetItemCount(item.itemName) >= item.target) {
                return true;
            }
        } else if (item.type == TYPE_REACH_POINT) {

        }
        return false;
    }

    void NextMission()
    {
        for (uint i = 0; i < missionList.length; i++) {
            MissionItem@ item = missionList[i];
            if (item.completed == false) {
                activeMission = item.eventName;
                log.Info("Your next mission: " + activeMission);
                log.Info("Description: " + item.description);
                if (CheckIfCompleted(item)) {
                    VariantMap data;
                    data["Name"] = item.eventName;
                    SendEvent("MissionCompleted", data);    
                } else {
                    Array<Variant> parameters;
                    parameters.Push(Variant(item.description));
                    DelayedExecute(1.0, false, "void Missions::ShowTip(String)", parameters);
                }
                return;
            }
        }
    }

    void ShowTip(String description)
    {
        VariantMap data;
        data["MESSAGE"] = description;
        SendEvent("ShowTip", data);

        //Array<Variant> parameters;
        //parameters.Push(Variant(description));
        //DelayedExecute(10.0, false, "void Missions::ShowTip(String)", parameters);
    }

    void Init()
    {
        MissionItem item;
        item.name = "Survivalist";
        item.description = "I need to find\nsome tools!";
        item.shortDescription = "Get axe";
        item.eventName = "GetAxe";
        item.itemName = "Axe";
        item.current = 0;
        item.target = 1;
        item.completed = false;
        item.type = TYPE_PICKUP;
        AddMission(item);

        item.name = "Defense";
        item.description = "I need to create\n a trap";
        item.shortDescription = "Get trap";
        item.eventName = "GetTrap";
        item.itemName = "Trap";
        item.current = 0;
        item.target = 1;
        item.completed = false;
        item.type = TYPE_PICKUP;
        AddMission(item);

        item.name = "Woodchopper";
        item.description = "Wood is always\n useful, I should\n gather some!";
        item.shortDescription = "Gather 5 branches";
        item.eventName = "GetWood";
        item.itemName = "Wood";
        item.current = 0;
        item.target = 5;
        item.completed = false;
        item.type = TYPE_PICKUP;
        AddMission(item);

        NextMission();
    }

    void Subscribe()
    {
        SubscribeToEvent("MissionCompleted", "Missions::HandleMission");
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

    void HandleMission(StringHash eventType, VariantMap& eventData)
    {
        if (eventData.Contains("Name") && eventData["Name"].type == VAR_STRING) {
            String name = eventData["Name"].GetString();
            for (uint i = 0; i < missionList.length; i++) {
                MissionItem@ item = missionList[i];
                if (item.eventName == name && item.completed == false && activeMission == item.eventName) {
                    if (CheckIfCompleted(item)) {
                        item.completed = true;
                        VariantMap data;
                        data["Message"] = "Mission [" + item.name +"] completed!";
                        SendEvent("UpdateEventLogGUI", data);
                        SendEvent("UpdateMissionsGUI");

                        GameSounds::Play(GameSounds::MISSION_COMPLETE);
                        NextMission();
                    }
                }
            }
        }
    }
}