namespace Trap {
    Node@ node;
    bool enabled = false;

    void Create()
    {
        if (node !is null) {
            return;
        }
        node = ActiveTool::toolNode.CreateChild("Trap");
        node.AddTag("Trap");

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Box.mdl");

        node.SetScale(0.2f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/StoneFps.xml");

        node.SetDeepEnabled(false);
        //ActiveTool::tools.Push(node);
        ActiveTool::AddTool(node, ActiveTool::TOOL_TRAP);
    }

    void CreatePickable(Vector3 position)
    {
        Node@ node = scene_.CreateChild("Trap");
        node.temporary = true;
        node.AddTag("Trap");

        position.y = NetworkHandler::terrain.GetHeight(position) + 1.0f;
        node.position = position;

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Box.mdl");

        node.SetScale(1.0f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");

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

    void Subscribe()
    {
        SubscribeToEvent("GetTrap", "Trap::HandlePickup");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "get_trap";
        data["CONSOLE_COMMAND_EVENT"] = "GetTrap";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandlePickup(StringHash eventType, VariantMap& eventData)
    {
        Create();
        SendEvent("InventoryAddTrap");
        ActiveTool::SetActiveTool(node);

        VariantMap data;
        data["Name"] = "GetTrap";
        SendEvent("UnlockAchievement", data);
    }
}