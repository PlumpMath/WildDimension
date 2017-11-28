namespace Missions {

    const uint TYPE_PICKUP = 0;
    const uint TYPE_REACH_POINT = 1;
    const uint TYPE_LEAVE_POINT = 2;
    const uint TYPE_USE_ITEM = 3;

    class LaunchEvent {
        VariantMap data;
        String name;
    };

    class MissionItem {
        String name;
        String description;
        String longDescription;
        String eventName;
        String itemName;
        String placeName;
        float current;
        float target;
        bool completed;
        uint type;
        Array<LaunchEvent> launchEvents;
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
            if (item.target <= item.current) {
                return true;
            }
        }
        return false;
    }

    void SetCompleted(MissionItem& item)
    {
        item.completed = true;
        for (uint i = 0; i < item.launchEvents.length; i++) {
            SendEvent(item.launchEvents[i].name, item.launchEvents[i].data);
        }
        SendEvent("HideQuestLog");
        VariantMap data;
        data["Message"] = "Mission '" + item.name + "' completed!";
        data["Type"] = Notifications::NOTIFICATION_TYPE_GOOD;
        SendEvent("AddNotification", data);
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
        {
            item.name = "First";
            item.description = "Hmm... how did get\nhere? I should find\nmy plane...";
            item.longDescription = "Go to plane";
            item.eventName = "VisitAirplane";
            item.itemName = "";
            item.placeName = "Airplane";
            item.current = 0;
            item.target = 0;
            item.completed = false;
            item.type = TYPE_REACH_POINT;

            LaunchEvent launchEvent;
            launchEvent.name = "HourChange";
            launchEvent.data["Hour"] = 12;
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }
            {
            item.name = "Second";
            item.description = "I should find\nmy stuff!";
            item.longDescription = "Near plane is bag\nwith your stuff";
            item.eventName = "GetPassport";
            item.itemName = "Passport";
            item.placeName = "";
            item.current = 0;
            item.target = 1;
            item.completed = false;
            item.type = TYPE_PICKUP;

            LaunchEvent launchEvent;
            launchEvent.name = "ActivateTetrisSpawners";
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }

        {
            item.name = "Third";
            item.description = "I should find someone...\nThere's a smoke, maybe\nit's worth checking out.";
            item.longDescription = "Look around, there is\nsmoke, go there";
            item.eventName = "VisitCampfire";
            item.itemName = "";
            item.placeName = "Campfire";
            item.current = 0;
            item.target = 0;
            item.completed = false;
            item.type = TYPE_REACH_POINT;
            
            LaunchEvent launchEvent;
            launchEvent.name = "HourChange";
            launchEvent.data["Hour"] = 15;
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }

        {
            item.name = "Fourth";
            item.description = "Sh*t!!! There's nobody\nhere, maybe i can find\nsome tools?!";
            item.eventName = "GetAxe";
            item.itemName = "Axe";
            item.current = 0;
            item.target = 1;
            item.completed = false;
            item.type = TYPE_PICKUP;
            
            LaunchEvent launchEvent;
            launchEvent.name = "HourChange";
            launchEvent.data["Hour"] = 16;
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }

        {
            item.name = "Fifth";
            item.description = "What is this place?\nI should look around";
            item.eventName = "VisitStonehenge";
            item.itemName = "";
            item.placeName = "Stonehenge";
            item.current = 0;
            item.target = 0;
            item.completed = false;
            item.type = TYPE_REACH_POINT;

            LaunchEvent launchEvent;
            launchEvent.name = "ActivateSnakeSpawners";
            item.launchEvents.Push(launchEvent);
            launchEvent.name = "ActivatePacmanSpawners";
            item.launchEvents.Push(launchEvent);
            AddMission(item);
        }

        {
            item.name = "Sixt";
            item.description = "Good that I have an axe...\nI should get away from here!";
            item.eventName = "LeaveStonehenge";
            item.itemName = "";
            item.placeName = "Stonehenge";
            item.current = 0;
            item.target = 0;
            item.completed = false;
            item.type = TYPE_LEAVE_POINT;
            
            LaunchEvent launchEvent;
            launchEvent.name = "HourChange";
            launchEvent.data["Hour"] = 18;
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }

        {
            item.name = "Seventh";
            item.description = "I should figure out\nhow to capture them...\nIt's not safe out here";
            item.eventName = "GetTrap";
            item.itemName = "Trap";
            item.current = 0;
            item.target = 1;
            item.completed = false;
            item.type = TYPE_PICKUP;
                
            LaunchEvent launchEvent;
            launchEvent.name = "HourChange";
            launchEvent.data["Hour"] = 19;
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }

        {
            item.name = "Eight";
            item.description = "It's getting dark,\nI need to find\na place, where I\ncan build a tent.";
            item.eventName = "UseTent";
            item.itemName = "Tent";
            item.current = 0;
            item.target = 1;
            item.completed = false;
            item.type = TYPE_USE_ITEM;
            
            LaunchEvent launchEvent;
            launchEvent.name = "HourChange";
            launchEvent.data["Hour"] = 20;
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }

        {
            item.name = "Nine";
            item.description = "I should make small\ncampfire that can\nceep me warm";
            item.eventName = "UseCampfire";
            item.itemName = "Campfire";
            item.current = 0;
            item.target = 1;
            item.completed = false;
            item.type = TYPE_USE_ITEM;
            
            LaunchEvent launchEvent;
            launchEvent.name = "HourChange";
            launchEvent.data["Hour"] = 22;
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }

        {
            item.name = "Ten";
            item.description = "Now i should\nlight it up";
            item.eventName = "UseLighter";
            item.itemName = "Lighter";
            item.current = 0;
            item.target = 2;
            item.completed = false;
            item.type = TYPE_USE_ITEM;
            
            LaunchEvent launchEvent;
            launchEvent.name = "HourChange";
            launchEvent.data["Hour"] = 0;
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }

        {
            item.name = "Eleven";
            item.description = "I should place some\ntraps around the\ncamp";
            item.eventName = "UseTrap";
            item.itemName = "Trap";
            item.current = 0;
            item.target = 1;
            item.completed = false;
            item.type = TYPE_USE_ITEM;

            LaunchEvent launchEvent;
            launchEvent.name = "GameFinished";
            item.launchEvents.Push(launchEvent);

            AddMission(item);
        }

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

                GameSounds::Play(GameSounds::MISSION_COMPLETE, 0.1);
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
                if (item.eventName == name && (item.type == TYPE_USE_ITEM || item.type == TYPE_PICKUP)) {
                    item.current++;
                }
                if (item.eventName == name && item.completed == false && activeMission == item.eventName) {
                    if (CheckIfCompleted(item)) {
                        SetCompleted(item);
                        VariantMap data;
                        data["Message"] = "Mission [" + item.name +"] completed!";
                        SendEvent("UpdateEventLogGUI", data);
                        SendEvent("UpdateMissionsGUI");

                        GameSounds::Play(GameSounds::MISSION_COMPLETE, 0.1);
                        NextMission();
                    }
                }
            }
        }
    }
}