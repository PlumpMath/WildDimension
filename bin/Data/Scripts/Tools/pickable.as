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
            if (node.name == "Stem") {
                VariantMap data;
                data["Name"] = "Axe";
                SendEvent("InventoryAdd", data);
                data["Name"] = "Wood";
                SendEvent("InventoryAdd", data);

                data["Name"] = "GetAxe";
                SendEvent("UnlockAchievement", data);
                data["Name"] = "GetWood";
                SendEvent("UnlockAchievement", data);
            } else if (node.name == "Backpack") {
                VariantMap data;
                data["Name"] = "Passport";
                SendEvent("InventoryAdd", data);
                data["Name"] = "Tent";
                SendEvent("InventoryAdd", data);

                data["Name"] = "GetPassport";
                SendEvent("UnlockAchievement", data);
                data["Name"] = "GetTent";
                SendEvent("UnlockAchievement", data);
            } else {
                VariantMap data;
                data["Name"] = node.name;
                SendEvent("InventoryAdd", data);

                data["Name"] = "Get" + node.name;
                SendEvent("UnlockAchievement", data);
            }

            GameSounds::Play(GameSounds::PICKUP_TOOL, 0.1);
            node.Remove();
        } else if (otherNode.HasTag("Snake")) {
            Snake::SnakeAdd(otherNode);
        }
    }
}

namespace Pickable {
    Array<Node@> pickables;

    Node@ Create(Vector3 position, String name, String model, float scale = 1.0f, bool playerOnly = true)
    {
        Node@ node = scene_.CreateChild(name);
        node.temporary = true;
        node.AddTag(name);
        position.y = NetworkHandler::terrain.GetHeight(position);
        node.position = position;

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", model);

        node.SetScale(scale);
        object.castShadows = true;
        if (name == "Stem") {
            object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
            object.materials[1] = cache.GetResource("Material", "Materials/Wood.xml");
            object.materials[2] = cache.GetResource("Material", "Materials/Wood.xml");
            object.materials[3] = cache.GetResource("Material", "Materials/Stone.xml");
        } else if (name == "Axe") {
            object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");
            object.materials[1] = cache.GetResource("Material", "Materials/Wood.xml");
        } else if (name == "Apple") {
            object.materials[0] = cache.GetResource("Material", "Materials/Apple.xml");
            object.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
            object.materials[2] = cache.GetResource("Material", "Materials/Wood.xml");
        } else if (name == "Raspberry") {
            object.materials[0] = cache.GetResource("Material", "Materials/Raspberry.xml");
            object.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
            object.materials[2] = cache.GetResource("Material", "Materials/TreeGreen.xml");
        } else {
            object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");
        }

        RigidBody@ body = node.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_PICKABLE_LEVEL;
        if (playerOnly) {
            body.collisionMask = COLLISION_PLAYER_LEVEL;
        } else {
            body.collisionMask = COLLISION_PLAYER_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PACMAN_LEVEL;
        }
        // The trigger mode makes the rigid body only detect collisions, but impart no forces on the
        // colliding objects
        body.trigger = true;
        CollisionShape@ shape = node.CreateComponent("CollisionShape");
        // Create the capsule shape with an offset so that it is correctly aligned with the model, which
        // has its origin at the feet
        shape.SetSphere(2.0f);

        node.CreateScriptObject(scriptFile, "PickableObject");
        pickables.Push(node);

        return node;
    }

    void DestroyById(uint id)
    {
        for (uint i = 0; i < pickables.length; i++) {
            if (pickables[i].id == id) {
                pickables[i].Remove();
                pickables.Erase(i);
                return;
            }
        }
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
        if (name == "Stem") {
            VariantMap data;
            data["Name"] = "Axe";
            SendEvent("InventoryAdd", data);
            data["Name"] = "Wood";
            SendEvent("InventoryAdd", data);

            data["Name"] = "GetAxe";
            SendEvent("UnlockAchievement", data);
            data["Name"] = "GetWood";
            SendEvent("UnlockAchievement", data);
            return;
        } else if (name == "Backpack") {
            VariantMap data;
            data["Name"] = "Passport";
            SendEvent("InventoryAdd", data);
            data["Name"] = "Tent";
            SendEvent("InventoryAdd", data);

            data["Name"] = "GetPassport";
            SendEvent("UnlockAchievement", data);
            data["Name"] = "GetTent";
            SendEvent("UnlockAchievement", data);
            return;
        }
        VariantMap data;
        data["Name"] = name;
        SendEvent("InventoryAdd", data);

        data["Name"] = "Get" + name;
        SendEvent("UnlockAchievement", data);
    }
}
