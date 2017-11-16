class PickableObject : ScriptObject
{
    void Start()
    {
        // Subscribe physics collisions that concern this scene node
        SubscribeToEvent(node, "NodeCollision", "HandleNodeCollision");
    }

    void HandleNodeCollision(StringHash eventType, VariantMap& eventData)
    {
        Node@ otherNode = eventData["OtherNode"].GetPtr();
        if (otherNode.HasTag("Player")) {
            log.Info("Player " + otherNode.id + " picked up " + node.name);
            VariantMap data;
            data["Name"] = node.name;
            SendEvent("InventoryAdd", data);

            data["Name"] = "Get" + node.name;
            SendEvent("UnlockAchievement", data);

            GameSounds::Play(GameSounds::PICKUP_TOOL);
            node.Remove();
        }
    }
}

namespace Pickable {
    Array<Node@> pickables;

    void Create(Vector3 position, String name, String model)
    {
        Node@ node = scene_.CreateChild(name);
        node.temporary = true;
        node.AddTag(name);
        position.y = NetworkHandler::terrain.GetHeight(position) + 1.0f;
        node.position = position;

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", model);

        node.SetScale(1.0f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/Wood.xml");

        RigidBody@ body = node.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_PICKABLE_LEVEL;
        body.collisionMask = COLLISION_PLAYER_LEVEL;
        // The trigger mode makes the rigid body only detect collisions, but impart no forces on the
        // colliding objects
        body.trigger = true;
        CollisionShape@ shape = node.CreateComponent("CollisionShape");
        // Create the capsule shape with an offset so that it is correctly aligned with the model, which
        // has its origin at the feet
        shape.SetSphere(1.5f);

        node.CreateScriptObject(scriptFile, "PickableObject");
        pickables.Push(node);
    }

    void Subscribe()
    {
        SubscribeToEvent("GetItem", "Pickable::HandlePickup");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "get";
        data["CONSOLE_COMMAND_EVENT"] = "GetItem";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandlePickup(StringHash eventType, VariantMap& eventData)
    {
        Array<String> commands = eventData["PARAMETERS"].GetStringVector();
        if (commands.length < 2) {
            log.Error("'get' command expects second argument!");
            return;
        }
        String name = commands[1];
        VariantMap data;
        data["Name"] = name;
        SendEvent("InventoryAdd", data);

        data["Name"] = "Get" + name;
        SendEvent("UnlockAchievement", data);
    }
}
