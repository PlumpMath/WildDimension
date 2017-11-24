namespace ActiveTool {

    const uint TOOL_NONE = 0;
    const uint TOOL_AXE = 1;
    const uint TOOL_TRAP = 2;
    const uint TOOL_BRANCH = 3;
    const uint TOOL_FLAG = 4;
    const uint TOOL_TENT = 5;
    const uint TOOL_CAMPFIRE = 6;
    const uint TOOL_LIGHTER = 7;
    const uint TOOL_TORCH = 8;

    Node@ node;
    Node@ toolNode;
    bool use = false;
    bool back = false;
    float sleepTime = 0.0f;

    const float BRANCH_DISSAPEAR_TIME = 10.0f;

    class Tool {
        Node@ node;
        uint type;
    };
    Tool activeTool;
    Array<Tool> tools;

    void Create()
    {
        node = cameraNode.CreateChild("ActiveTool");
        //position.y = NetworkHandler::terrain.GetHeight(position) + 1.0f;
        //node.position = position;

        toolNode = node.CreateChild("AdjNode");
        toolNode.rotation = Quaternion(-100.0f, Vector3::UP);

        Vector3 position = cameraNode.position;
        position += cameraNode.direction * 0.6f;
        position += node.rotation * Vector3::RIGHT * 0.3f;
        position += node.rotation * Vector3::UP * -0.1f;
        node.position = position;

        Axe::Create();
        Trap::Create();
        Flag::Create();
        Tent::Create();
        Campfire::Create();
        Lighter::Create();
        Torch::Create();
    }

    void AddTool(Node@ node, uint type)
    {
        Tool tool;
        tool.node = node;
        tool.type = type;
        tools.Push(tool);
    }

    void Subscribe()
    {
        SubscribeToEvent("NextTool", "ActiveTool::HandleNextTool");
    }

    bool Raycast(float maxDistance, Vector3& hitPos, Drawable@& hitDrawable, Vector3& direction)
    {
        hitDrawable = null;

        Camera@ camera = cameraNode.GetComponent("Camera");
        Ray cameraRay = camera.GetScreenRay(0.5f, 0.5f);
        direction = cameraNode.direction;
        //cameraRay.origin += cameraNode.direction;
        // Pick only geometry objects, not eg. zones or lights, only get the first (closest) hit
        // Note the convenience accessor to scene's Octree component
        RayQueryResult result = scene_.octree.RaycastSingle(cameraRay, RAY_TRIANGLE, maxDistance, DRAWABLE_GEOMETRY, VIEW_MASK_INTERACTABLE);
        if (result.drawable !is null)
        {
            hitPos = result.position;
            hitDrawable = result.drawable;
            return true;
        }

        return false;
    }

    void CreateFlag(Vector3 position)
    {
        node = scene_.CreateChild("Flag");
        node.AddTag("Flag");
        position.y = NetworkHandler::terrain.GetHeight(position);
        node.position = position;

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Flag.mdl");

        node.SetScale(1.0f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/SnakeSkin.xml");

        Inventory::RemoveItem("Flag");
        RemoveActiveTool();
        SendEvent("NextTool");
        SendEvent("GameFinished");
    }

    bool CreateTent(Vector3 position)
    {
        if (!Missions::IsMissionCompletedByEventName("GetTrap")) {
            VariantMap data;
            data["Message"] = "Can't use this item yet!";
            data["Type"] = Notifications::NOTIFICATION_TYPE_BAD;
            SendEvent("AddNotification", data);
            return false;
        }
        node = scene_.CreateChild("Tent");
        node.AddTag("Tent");
        position.y = NetworkHandler::terrain.GetHeight(position);
        node.position = position;
        node.rotation = Quaternion(Vector3(0.0f, 1.0f, 0.0f), NetworkHandler::terrain.GetNormal(position));

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Pyramid.mdl");

        node.SetScale(1.0f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");

        Inventory::RemoveItem("Tent");
        RemoveActiveTool();
        SendEvent("NextTool");
        return true;
    }

    void CreateCampfire(Vector3 position)
    {
        Camp::Create(position);

        Inventory::RemoveItem("Campfire");
        RemoveActiveTool();
        SendEvent("NextTool");
    }

    void AxeHit(Vector3 position)
    {
        position -= cameraNode.direction;
        Node@ branchNode = scene_.CreateChild("Wood");
        branchNode.temporary = true;
        branchNode.AddTag("Wood");
        //Vector3 position = parentTree.node.position;
        //position.x += -1.0f + Random(2.0f);
        //position.z += -1.0f + Random(2.0f);
        //position.y = NetworkHandler::terrain.GetHeight(position) + 0.2f;
        branchNode.worldPosition = position;
        branchNode.SetScale(2.0);
        StaticModel@ object = branchNode.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Branch.mdl");

        //branchNode.SetScale(0.8f + Random(0.5f));
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
        //object.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
        //object.materials[2] = cache.GetResource("Material", "Materials/Wood.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        RigidBody@ body = branchNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_FOOD_LEVEL;
        body.collisionMask = COLLISION_TERRAIN_LEVEL | COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_TREE_LEVEL | COLLISION_FOOD_LEVEL | COLLISION_STATIC_OBJECTS;
        body.mass = 0.1f;

        CollisionShape@ shape = branchNode.CreateComponent("CollisionShape");
        shape.SetConvexHull(object.model);

        branchNode.CreateScriptObject(scriptFile, "PickableObject");

        Array<Variant> parameters;
        parameters.Push(Variant(branchNode.id));

        //Automatically remove branches 
        DelayedExecute(BRANCH_DISSAPEAR_TIME, false, "void ActiveTool::DestroyBranch(uint)", parameters);
    }

    void DestroyBranch(uint nodeId)
    {
        Node@ node = scene_.GetNode(nodeId);
        if (node !is null) {
            node.Remove();
        }
    }

    void HitObject()
    {
        Vector3 hitPos;
        Drawable@ hitDrawable;
        Vector3 direction;

        if (activeTool.type == TOOL_LIGHTER) {
            Lighter::StartAnimation();
        }
        if (Raycast(5.0f, hitPos, hitDrawable, direction)) {

            // Check if target scene node already has a DecalSet component. If not, create now
            Node@ targetNode = hitDrawable.node;
            VariantMap data;
            data["Message"] = "You hit " + targetNode.name + "[" + targetNode.id + "]!";
            SendEvent("UpdateEventLogGUI", data);

            /*DecalSet@ decal = targetNode.GetComponent("DecalSet");
            if (decal is null)
            {
                decal = targetNode.CreateComponent("DecalSet");
                decal.material = cache.GetResource("Material", "Materials/UrhoDecal.xml");
            }*/
            // Add a square decal to the decal set using the geometry of the drawable that was hit, orient it to face the camera,
            // use full texture UV's (0,0) to (1,1). Note that if we create several decals to a large object (such as the ground
            // plane) over a large area using just one DecalSet component, the decals will all be culled as one unit. If that is
            // undesirable, it may be necessary to create more than one DecalSet based on the distance
            //decal.AddDecal(hitDrawable, hitPos, cameraNode.rotation, 0.5f, 1.0f, 1.0f, Vector2::ZERO, Vector2::ONE);

            Node@ baseNode = targetNode;

            if (activeTool.type == TOOL_FLAG) {
                VariantMap data;
                data["Name"] = "Use" + activeTool.node.name;
                CreateFlag(hitPos);
                SendEvent("UnlockAchievement", data);
                return;
            }
            if (activeTool.type == TOOL_TENT) {
                VariantMap data;
                data["Name"] = "Use" + activeTool.node.name;
                if (CreateTent(hitPos)) {
                    SendEvent("UnlockAchievement", data);
                    return;
                }
            }
            if (activeTool.type == TOOL_CAMPFIRE) {
                VariantMap data;
                data["Name"] = "Use" + activeTool.node.name;
                CreateCampfire(hitPos);
                SendEvent("UnlockAchievement", data);
                return;
            }
            if (activeTool.type == TOOL_LIGHTER) {
                if (targetNode.HasTag("Campfire")) {
                    Camp::ChangeState(targetNode.id);
                    VariantMap data;
                    data["Name"] = "Use" + activeTool.node.name;
                    SendEvent("UnlockAchievement", data);
                    return;
                }
            }
            float hitPower = 20;
            if (targetNode.HasTag("Adj")) {
                baseNode = targetNode.parent;
                if (targetNode.GetParentComponent("RigidBody") !is null) {
                    if (activeTool.type == TOOL_AXE) {
                        RigidBody@ body = targetNode.GetParentComponent("RigidBody");
                        body.ApplyImpulse(direction * hitPower * body.mass);
                        VariantMap data;
                        data["Name"] = "Use" + activeTool.node.name;
                        SendEvent("UnlockAchievement", data);
                    }
                }
            } else {
                if (targetNode.HasComponent("RigidBody")) {
                    if (activeTool.type == TOOL_AXE) {
                        RigidBody@ body = targetNode.GetComponent("RigidBody");
                        body.ApplyImpulse(direction * hitPower * body.mass);
                        VariantMap data;
                        data["Name"] = "Use" + activeTool.node.name;
                        SendEvent("UnlockAchievement", data);
                    }
                }
            }
            if (baseNode.HasTag("Enemy")) {
                if (activeTool.type == TOOL_AXE) {
                    if (baseNode.HasTag("Snake")) {
                        GameSounds::Play(GameSounds::HIT_SNAKE);
                        VariantMap data;
                        data["Name"] = "HitSnake";
                        SendEvent("UnlockAchievement", data);
                        Snake::HitSnake(baseNode);
                    } else if (baseNode.HasTag("Pacman")) {
                        GameSounds::Play(GameSounds::HIT_PACMAN);
                        VariantMap data;
                        data["Name"] = "HitPacman";
                        SendEvent("UnlockAchievement", data);
                        Pacman::HitPacman(baseNode);
                    }
                }
            }
            if (targetNode.name == "Tree") {
                if (activeTool.type == TOOL_AXE) {
                    GameSounds::Play(GameSounds::HIT_TREE);
                    AxeHit(hitPos);
                    VariantMap data;
                    data["Name"] = "HitTree";
                    SendEvent("UnlockAchievement", data);
                }
            } else {
                if (activeTool.type == TOOL_TRAP) {
                    GameSounds::Play(GameSounds::HIT_FOOD);
                    VariantMap data;
                    data["Name"] = "HitFood";
                    SendEvent("UnlockAchievement", data);
                }
            }
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        sleepTime -= timeStep;
        if (tools.length > 0) {
            if ((isMobilePlatform == false && input.mouseButtonDown[MOUSEB_LEFT]) || input.keyDown[KEY_E]) {
                if (activeTool.node !is null) {
                    if (use == false && sleepTime <= 0) {
                        use = true;
                        toolNode.Roll(-60.0f);
                        back = true;
                        sleepTime = 0.2f;
                        HitObject();
                    }
                }
            }
            if (back == true && sleepTime <= 0) {
                toolNode.Roll(60.0f);
                back = false;
                use = false;
                sleepTime = 0.2f;   
            }
            if (input.keyPress[KEY_Q]) {
                SendEvent("NextTool");
            }
        }
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "next_tool";
        data["CONSOLE_COMMAND_EVENT"] = "NextTool";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandleNextTool(StringHash eventType, VariantMap& eventData)
    {
        if (activeTool.node is null) {
            for (uint i = 0; i < tools.length; i++) {
                if (Inventory::GetItemCount(tools[i].node.name) > 0) {
                    SetActiveToolByName(tools[i].node.name);
                }
            }
        } else {
            uint currentIndex = 0;
            for (uint i = 0; i < tools.length; i++) {
                if (activeTool.node.id == tools[i].node.id) {
                    currentIndex = i;
                }
            }
            bool foundNext = false;
            for (uint i = currentIndex + 1; i < tools.length; i++) {
                if (foundNext) {
                    continue;
                }
                if (Inventory::GetItemCount(tools[i].node.name) > 0) {
                    currentIndex = i;
                    foundNext = true;
                    SetActiveToolByName(tools[i].node.name);
                }
            }
            if (foundNext == false) {
                for (uint i = 0; i < tools.length; i++) {
                    if (foundNext) {
                        continue;
                    }
                    if (Inventory::GetItemCount(tools[i].node.name) > 0) {
                        currentIndex = i;
                        foundNext = true;
                        SetActiveToolByName(tools[i].node.name);
                    }
                }   
            }
        }
    }

    void RemoveActiveTool()
    {
        activeTool.type = TOOL_NONE;
        activeTool.node = null;
        for (uint i = 0; i < tools.length; i++) {
            Node@ node = tools[i].node;
            node.SetDeepEnabled(false);
        }
    }

    void SetActiveTool(Node@ newTool)
    {
        for (uint i = 0; i < tools.length; i++) {
            Node@ node = tools[i].node;
            if (newTool.id == node.id) {
                node.SetDeepEnabled(true);
                activeTool = tools[i];

            } else {
                node.SetDeepEnabled(false);
            }
        }
    }

    void SetActiveToolByName(String name)
    {
        if (Inventory::GetItemCount(name) <= 0) {
            return;
        }
        bool found = false;
        for (uint i = 0; i < tools.length; i++) {
            Node@ node = tools[i].node;
            if (name == node.name) {
                found = true;
            }
        }
        if (found) {
            for (uint i = 0; i < tools.length; i++) {
                Node@ node = tools[i].node;
                if (name == node.name) {
                    node.SetDeepEnabled(true);
                    activeTool = tools[i];

                } else {
                    node.SetDeepEnabled(false);
                }
            }
        }
    }
}
