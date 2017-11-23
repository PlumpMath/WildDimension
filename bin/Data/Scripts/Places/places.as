class Visitor : ScriptObject
{
    void Start()
    {
        // Subscribe physics collisions that concern this scene node
        SubscribeToEvent(node, "NodeCollisionStart", "HandleNodeCollisionStart");
        SubscribeToEvent(node, "NodeCollisionEnd", "HandleNodeCollisionEnd");
    }

    void HandleNodeCollisionStart(StringHash eventType, VariantMap& eventData)
    {
        Node@ otherNode = eventData["OtherNode"].GetPtr();
        if (otherNode.HasTag("Player")) {
            Player::destination = node.name;
            log.Info("Player [" + otherNode.id + "] reached place " + node.name);
            VariantMap data;
            data["Name"] = "Visit" + node.name;
            SendEvent("UnlockAchievement", data);

            data["Message"] = "Player [" + otherNode.id + "] reached place " + node.name;
            SendEvent("UpdateEventLogGUI", data);
        }
    }

    void HandleNodeCollisionEnd(StringHash eventType, VariantMap& eventData)
    {
        Node@ otherNode = eventData["OtherNode"].GetPtr();
        if (otherNode.HasTag("Player")) {
            Player::destination = "";
            log.Info("Player [" + otherNode.id + "] leaved place " + node.name);
            VariantMap data;
            data["Name"] = "Leave" + node.name;
            SendEvent("UnlockAchievement", data);

            data["Message"] = "Player [" + otherNode.id + "] leaved place " + node.name;
            SendEvent("UpdateEventLogGUI", data);
        }
    }
}

namespace Places {

	Array<Node@> places;

	void Init()
	{
		Subscribe();
		RegisterConsoleCommands();

		SearchPlaces();
	}

	void SearchPlaces()
	{
		places = scene_.GetChildrenWithTag("Visit", true);
		for (uint i = 0; i < places.length; i++) {
			log.Info("Found place " + places[i].name + "[" + places[i].id + "]");
			places[i].CreateScriptObject(scriptFile, "Visitor");
		}
	}

	void Subscribe()
    {
        SubscribeToEvent("SearchPlaces", "Places::HandleSearchPlaces");
        //DelayedExecute(5.0, false, "void Pickable::DisableFurthestObjects()");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "search_places";
        data["CONSOLE_COMMAND_EVENT"] = "SearchPlaces";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandleSearchPlaces(StringHash eventType, VariantMap& eventData)
    {
    	SearchPlaces();
    }

    Vector3 getPlacePosition(String name)
    {
        for (uint i = 0; i < places.length; i++) {
            if (places[i].name == name) {
                return places[i].worldPosition;
            }
        }
        return Vector3(0, 0, 0);
    }
}