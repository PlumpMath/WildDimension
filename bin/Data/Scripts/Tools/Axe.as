namespace Axe {
    Node@ node;
    bool enabled = false;

    void Create()
    {
        if (node !is null) {
            return;
        }
        node = ActiveTool::toolNode.CreateChild("Axe");
        node.AddTag("Axe");

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Axe.001.mdl");

        node.SetScale(0.5f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/StoneFps.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/WoodFps.xml");

        node.SetDeepEnabled(false);
        //ActiveTool::tools.Push(node);
        ActiveTool::AddTool(node, ActiveTool::TOOL_AXE);
    }

    void Subscribe()
    {
        SubscribeToEvent("GetAxe", "Axe::HandlePickup");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "get_axe";
        data["CONSOLE_COMMAND_EVENT"] = "GetAxe";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandlePickup(StringHash eventType, VariantMap& eventData)
    {
        Create();
        SendEvent("InventoryAddAxe");
        ActiveTool::SetActiveTool(node);

        VariantMap data;
        data["Name"] = "GetAxe";
        SendEvent("UnlockAchievement", data);
    }

    void CreatePickable(Vector3 position)
    {
        Node@ node = scene_.CreateChild("Axe");
        node.temporary = true;
        node.AddTag("Axe");
        position.y = NetworkHandler::terrain.GetHeight(position) + 1.0f;
        node.position = position;

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Axe.mdl");

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
    }
}