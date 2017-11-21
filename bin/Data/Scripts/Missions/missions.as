namespace Missions {

    const uint TYPE_PICKUP = 0;
    const uint TYPE_REACH_POINT = 1;
    const uint TYPE_USE_ITEM = 2;

    class MissionItem {
        String name;
        String description;
        String shortDescription;
        String eventName;
        String itemName;
        String placeName;
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
            if (item.placeName == Player::destination) {
                return true;
            }
        } else if (item.type == TYPE_USE_ITEM) {
            log.Warning("CheckIfCompleted item " + item.name);
            log.Warning("CheckIfCompleted current " + item.current);
            log.Warning("CheckIfCompleted target " + item.target);
            if (item.target <= item.current) {
                return true;
            }
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
                    item.completed = true;
                    SendEvent("UpdateMissionsGUI");
                    NextMission();
                    return; 
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

        item.name = "Find airplane";
        item.description = "I need to find my\nairplane!";
        item.shortDescription = "Find airplane";
        item.eventName = "VisitAirplane";
        item.itemName = "";
        item.placeName = "Airplane";
        item.current = 0;
        item.target = 0;
        item.completed = false;
        item.type = TYPE_REACH_POINT;
        AddMission(item);

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

        item.name = "Use Axe";
        item.description = "Let's try the axe!";
        item.shortDescription = "Use axe";
        item.eventName = "UseAxe";
        item.itemName = "";
        item.placeName = "";
        item.current = 0;
        item.target = 1;
        item.completed = false;
        item.type = TYPE_USE_ITEM;
        AddMission(item);

        item.name = "Find pyramid";
        item.description = "I need to explore\npyramids!";
        item.shortDescription = "Find pyramid";
        item.eventName = "VisitPyramid";
        item.itemName = "";
        item.placeName = "Pyramid";
        item.current = 0;
        item.target = 0;
        item.completed = false;
        item.type = TYPE_REACH_POINT;
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
                    item.current++;
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