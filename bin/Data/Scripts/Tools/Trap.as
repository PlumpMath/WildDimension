class TrapTrigger : ScriptObject
{
    void Start()
    {
        // Subscribe physics collisions that concern this scene node
        SubscribeToEvent(node, "NodeCollision", "HandleNodeCollision");
    }

    void HandleNodeCollision(StringHash eventType, VariantMap& eventData)
    {
        Node@ otherNode = eventData["OtherNode"].GetPtr();
        if (otherNode.HasTag("Snake") || otherNode.HasTag("Pacman")) {
            GameSounds::Play(GameSounds::TRAP_ENEMY);
            VariantMap data;

            if (otherNode.HasTag("Pacman")) {
                data["Name"] = "TrapPacman";
                SendEvent("UnlockAchievement", data);
                Pacman::DestroyById(otherNode.id);
            }
            if (otherNode.HasTag("Snake")) {
                data["Name"] = "TrapSnake";
                SendEvent("UnlockAchievement", data);
                Snake::DestroyById(otherNode.id);
            }
        }
    }
}

namespace Trap {
    Node@ node;
    bool enabled = false;

    Array<Node@> placedTraps;

    void Create()
    {
        if (node !is null) {
            return;
        }
        node = ActiveTool::toolNode.CreateChild("Trap");
        node.AddTag("Trap");

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Cage.mdl");

        node.SetScale(0.1f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[2] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[3] = cache.GetResource("Material", "Materials/WoodFps.xml");

        node.SetDeepEnabled(false);
        //ActiveTool::tools.Push(node);
        ActiveTool::AddTool(node, ActiveTool::TOOL_TRAP);
    }

    void Use(Vector3 position)
    {
        /*if (!Missions::IsMissionCompletedByEventName("UseLighter")) {
            VariantMap data;
            data["Message"] = "Can't use this item yet!";
            data["Type"] = Notifications::NOTIFICATION_TYPE_BAD;
            SendEvent("AddNotification", data);
            return;
        }*/
        if (PlaceTrap(position)) {
            VariantMap data;
            data["Name"] = "UseTrap";
            SendEvent("UnlockAchievement", data);
        }
    }

    bool PlaceTrap(Vector3 position)
    {
        Node@ newTrap = scene_.CreateChild("Trap");
        newTrap.AddTag("Trap");
        position.y = NetworkHandler::terrain.GetHeight(position);
        newTrap.position = position;
        newTrap.rotation = Quaternion(Vector3(0.0f, 1.0f, 0.0f), NetworkHandler::terrain.GetNormal(position));

        StaticModel@ object = newTrap.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Cage.mdl");

        newTrap.SetScale(1.0f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[2] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[3] = cache.GetResource("Material", "Materials/Wood.xml");

        RigidBody@ body = newTrap.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_STATIC_OBJECTS;
        body.collisionMask = COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PLAYER_LEVEL;
        body.mass = 0.0f;

        // Set zero angular factor so that physics doesn't turn the character on its own.
        // Instead we will control the character yaw manually
        body.angularFactor = Vector3::ZERO;

        // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
        //body.collisionEventMode = COLLISION_ALWAYS;


        // Set a capsule shape for collision
        CollisionShape@ shape = newTrap.CreateComponent("CollisionShape");
        shape.SetTriangleMesh(object.model);

        newTrap.CreateScriptObject(scriptFile, "TrapTrigger");

        Inventory::RemoveItem("Trap");
        ActiveTool::RemoveActiveTool();
        SendEvent("NextTool");

        placedTraps.Push(newTrap);
        return true;
    }
}