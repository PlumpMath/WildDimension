namespace Missions {

    const uint TYPE_PICKUP = 0;
    const uint TYPE_REACH_POINT = 1;
    const uint TYPE_LEAVE_POINT = 2;
    const uint TYPE_USE_ITEM = 3;

    class MissionItem {
        String name;
        String description;
        String eventName;
        String itemName;
        String placeName;
        float current;
        float target;
        bool completed;
        uint type;
        String launchEvent;
        VariantMap eventData;
    };

    String activeMission;

    Array<MissionItem> missionList;

    void AddMission(MissionItem item)
    {
        log.Info("Adding mission " + item.name);
        missionList.Push(item);
        SendEvent("UpdateMissionsGUI");
    }

    MissionItem GetActiveMission()
    {
        for (uint i = 0; i < missionList.length; i++) {
            if (missionList[i].eventName == activeMission) {
                return missionList[i];
            }
        }
        MissionItem mission;
        return mission;
    }

    bool IsMissionCompletedByEventName(String name)
    {
        for (uint i = 0; i < missionList.length; i++) {
            if (missionList[i].eventName == name) {
                if (missionList[i].completed == true) {
                    return true;
                }
            }
        }
        return false;
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
        } else if (item.type == TYPE_LEAVE_POINT) {
            if (item.placeName != Player::destination) {
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

    void SetCompleted(MissionItem& item)
    {
        item.completed = true;
        if (item.launchEvent.length > 0) {
            SendEvent(item.launchEvent, item.eventData);
        }
    }

    void NextMission()
    {
        for (uint i = 0; i < missionList.length; i++) {
            MissionItem@ item = missionList[i];
            if (item.completed == false) {
                activeMission = item.eventName;
                log.Info("Your next mission: " + activeMission);
                log.Info("Description: " + item.description);
                SendEvent("UpdateMissionsGUI");
                if (CheckIfCompleted(item)) {
                    SetCompleted(item);
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

        item.name = "First";
        item.description = "Hmm... how did get\nhere? I should find\nmy plane...";
        item.eventName = "VisitAirplane";
        item.itemName = "";
        item.placeName = "Airplane";
        item.current = 0;
        item.target = 0;
        item.completed = false;
        item.type = TYPE_REACH_POINT;
        item.launchEvent = "HourChange";
        item.eventData["Hour"] = 12;
        AddMission(item);

        item.name = "Second";
        item.description = "I should find\nmy stuff!";
        item.eventName = "GetPassport";
        item.itemName = "Passport";
        item.placeName = "";
        item.current = 0;
        item.target = 1;
        item.completed = false;
        item.type = TYPE_PICKUP;
        item.launchEvent = "HourChange";
        item.eventData["Hour"] = 13;
        AddMission(item);

        item.name = "Third";
        item.description = "I should find someone...\nThere's a smoke, maybe\nit's worth checking out.";
        item.eventName = "VisitCampfire";
        item.itemName = "";
        item.placeName = "Campfire";
        item.current = 0;
        item.target = 0;
        item.completed = false;
        item.type = TYPE_REACH_POINT;
        item.launchEvent = "HourChange";
        item.eventData["Hour"] = 15;
        AddMission(item);

        item.name = "Fourth";
        item.description = "Sh*t!!! There's nobody\nhere, maybe i can find\nsome tools?!";
        item.eventName = "GetAxe";
        item.itemName = "Axe";
        item.current = 0;
        item.target = 1;
        item.completed = false;
        item.type = TYPE_PICKUP;
        item.launchEvent = "HourChange";
        item.eventData["Hour"] = 16;
        AddMission(item);

        item.name = "Fifth";
        item.description = "What is this place?\nI should look around";
        item.eventName = "VisitStonehenge";
        item.itemName = "";
        item.placeName = "Stonehenge";
        item.current = 0;
        item.target = 0;
        item.completed = false;
        item.launchEvent = "ActivateSnakeSpawners";
        item.type = TYPE_REACH_POINT;
        AddMission(item);

        item.name = "Sixt";
        item.description = "Good that I have an axe...\nI should get away from here!";
        item.eventName = "LeaveStonehenge";
        item.itemName = "";
        item.placeName = "Stonehenge";
        item.current = 0;
        item.target = 0;
        item.completed = false;
        item.type = TYPE_LEAVE_POINT;
        item.launchEvent = "HourChange";
        item.eventData["Hour"] = 18;
        AddMission(item);

        item.name = "Seventh";
        item.description = "I should figure out\nhow to capture them...\nIt's not safe out here";
        item.eventName = "GetTrap";
        item.itemName = "Trap";
        item.current = 0;
        item.target = 1;
        item.completed = false;
        item.type = TYPE_PICKUP;
        item.launchEvent = "HourChange";
        item.eventData["Hour"] = 19;
        AddMission(item);

        item.name = "Eight";
        item.description = "I need to find\na place, where I\ncan build a tent.";
        item.eventName = "UseTent";
        item.itemName = "Tent";
        item.current = 0;
        item.target = 1;
        item.completed = false;
        item.type = TYPE_USE_ITEM;
        item.launchEvent = "HourChange";
        item.eventData["Hour"] = 20;
        AddMission(item);

        item.name = "Nine";
        item.description = "I should make small\ncampfire that can\nceep me warm";
        item.eventName = "GetCampfire";
        item.itemName = "Campfire";
        item.current = 0;
        item.target = 1;
        item.completed = false;
        item.type = TYPE_PICKUP;
        item.launchEvent = "HourChange";
        item.eventData["Hour"] = 23;
        AddMission(item);

        item.name = "Ten";
        item.description = "Now i should\nlight it up";
        item.eventName = "UseLighter";
        item.itemName = "Lighter";
        item.current = 0;
        item.target = 2;
        item.completed = false;
        item.type = TYPE_USE_ITEM;
        item.launchEvent = "GameFinished";
        AddMission(item);

        NextMission();

        Subscribe();
        RegisterConsoleCommands();
    }

    void Subscribe()
    {
        SubscribeToEvent("MissionCompleted", "Missions::HandleMission");
        SubscribeToEvent("CompleteCurrentMission", "Missions::HandleCompleteCurrentMission");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "mission_complete";
        data["CONSOLE_COMMAND_EVENT"] = "CompleteCurrentMission";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandleCompleteCurrentMission(StringHash eventType, VariantMap& eventData)
    {
        for (uint i = 0; i < missionList.length; i++) {
            MissionItem@ item = missionList[i];
            if (activeMission == item.eventName) {
                missionList[i].current = missionList[i].target;
                SetCompleted(missionList[i]);
                VariantMap data;
                data["Message"] = "Mission [" + item.name +"] completed!";
                SendEvent("UpdateEventLogGUI", data);
                SendEvent("UpdateMissionsGUI");

                GameSounds::Play(GameSounds::MISSION_COMPLETE);
                NextMission();
                return;
            }
        }
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
                        SetCompleted(item);
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