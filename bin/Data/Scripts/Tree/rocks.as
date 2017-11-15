namespace RandomRock {
    class Tree {
        Node@ node;
    }
    Array<Tree@> trees;

    Node@ Create(Vector3 position)
    {
        Node@ treeNode = scene_.CreateChild("Rock");
        treeNode.AddTag("Rock");
        treeNode.temporary = true;
        position.y = NetworkHandler::terrain.GetHeight(position);
        treeNode.position = position;

        StaticModel@ object = treeNode.CreateComponent("StaticModel");
        int rand = RandomInt(4);
        if (rand == 0) {
            object.model = cache.GetResource("Model", "Models/Models/Small_rock.mdl");
        } else if (rand == 1) {
            object.model = cache.GetResource("Model", "Models/Models/Small_rock2.mdl");
        } else if (rand == 2) {
            object.model = cache.GetResource("Model", "Models/Models/Small_rock3.mdl");
        } else {
            object.model = cache.GetResource("Model", "Models/Models/Small_rock4.mdl");
        }
        treeNode.SetScale(1.0f + Random(0.5f));
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");
    

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        RigidBody@ body = treeNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_TREE_LEVEL;
        body.collisionMask = COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_FOOD_LEVEL;
        body.mass = 0.0f;

        // Set zero angular factor so that physics doesn't turn the character on its own.
        // Instead we will control the character yaw manually
        body.angularFactor = Vector3::ZERO;

        // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
        body.collisionEventMode = COLLISION_ALWAYS;

        // Set a capsule shape for collision
        CollisionShape@ shape = treeNode.CreateComponent("CollisionShape");
        //shape.SetConvexHull(object.model);
        shape.SetTriangleMesh(object.model);

        treeNode.CreateScriptObject(scriptFile, "PickableObject");
        Tree tree;
        tree.node = treeNode;
        trees.Push(tree);
        return treeNode;
    }

    void Subscribe()
    {
        SubscribeToEvent("GetRock", "RandomRock::HandlePickup");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "get_rock";
        data["CONSOLE_COMMAND_EVENT"] = "GetRock";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandlePickup(StringHash eventType, VariantMap& eventData)
    {
        //Create();
        SendEvent("InventoryAddRock");
        //ActiveTool::SetActiveTool(node);

        VariantMap data;
        data["Name"] = "GetRock";
        SendEvent("UnlockAchievement", data);
    }
}