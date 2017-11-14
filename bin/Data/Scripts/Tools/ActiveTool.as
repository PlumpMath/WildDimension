namespace ActiveTool {

    const uint TOOL_AXE = 0;
    const uint TOOL_TRAP = 1;
    const uint TOOL_BRANCH = 2;
    Node@ node;
    Node@ toolNode;
    uint activeToolIndex = 0;
    bool use = false;
    bool back = false;
    float sleepTime = 0.0f;

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

        /*RigidBody@ body = toolNode.CreateComponent("RigidBody");
        // The trigger mode makes the rigid body only detect collisions, but impart no forces on the
        // colliding objects
        body.trigger = true;
        body.collisionMask = 0;
        CollisionShape@ shape = toolNode.CreateComponent("CollisionShape");
        // Create the capsule shape with an offset so that it is correctly aligned with the model, which
        // has its origin at the feet
        shape.SetCapsule(0.7f, 2.0f, Vector3(0.0f, 1.0f, 0.0f));*/
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
        Ray cameraRay = camera.GetScreenRay(0.5, 0.5);
        cameraRay.origin += cameraNode.direction / 10.0f;
        direction = cameraNode.direction;
        // Pick only geometry objects, not eg. zones or lights, only get the first (closest) hit
        // Note the convenience accessor to scene's Octree component
        RayQueryResult result = scene_.octree.RaycastSingle(cameraRay, RAY_TRIANGLE, maxDistance, DRAWABLE_GEOMETRY);
        if (result.drawable !is null)
        {
            hitPos = result.position;
            hitDrawable = result.drawable;
            return true;
        }

        return false;
    }

    void AxeHit(Vector3 position)
    {
        Node@ branchNode = scene_.CreateChild("Branch");
        branchNode.temporary = true;
        branchNode.AddTag("Branch");
        //Vector3 position = parentTree.node.position;
        //position.x += -1.0f + Random(2.0f);
        //position.z += -1.0f + Random(2.0f);
        //position.y = NetworkHandler::terrain.GetHeight(position) + 0.2f;
        branchNode.worldPosition = position;

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
        body.collisionMask = COLLISION_TERRAIN_LEVEL | COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_TREE_LEVEL | COLLISION_FOOD_LEVEL;
        body.mass = 0.1f;

        // Set zero angular factor so that physics doesn't turn the character on its own.
        // Instead we will control the character yaw manually
        //body.angularFactor = Vector3::ZERO;

        // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
        body.collisionEventMode = COLLISION_ALWAYS;

        CollisionShape@ shape = branchNode.CreateComponent("CollisionShape");
        shape.SetConvexHull(object.model);
        //shape.SetBox(Vector3(0.1, 3.0, 0.1));
    

        branchNode.CreateScriptObject(scriptFile, "PickableObject");
    }

    void HitObject()
    {
        Vector3 hitPos;
        Drawable@ hitDrawable;
        Vector3 direction;

        if (Raycast(1.0f, hitPos, hitDrawable, direction)) {
            // Check if target scene node already has a DecalSet component. If not, create now
            Node@ targetNode = hitDrawable.node;
            log.Info("Hit " + targetNode.name);
            
            /*VariantMap data;
            data["Message"] = "You hit " + targetNode.name + "!";
            SendEvent("UpdateEventLogGUI", data);*/

            Node@ baseNode = targetNode;

            float hitPower = 20;
            if (targetNode.HasTag("Adj")) {
                baseNode = targetNode.parent;
                if (targetNode.GetParentComponent("RigidBody") !is null) {
                    if (activeTool.type == TOOL_AXE) {
                        RigidBody@ body = targetNode.GetParentComponent("RigidBody");
                        body.ApplyImpulse(direction * hitPower * body.mass);
                    }
                }
            } else {
                if (targetNode.HasComponent("RigidBody")) {
                    if (activeTool.type == TOOL_AXE) {
                        RigidBody@ body = targetNode.GetComponent("RigidBody");
                        body.ApplyImpulse(direction * hitPower * body.mass);
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
                if (use == false && sleepTime <= 0) {
                    use = true;
                    toolNode.Roll(-60.0f);
                    back = true;
                    sleepTime = 0.2f;
                    HitObject();
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
        if (tools.length == 0) {
            return;
        }
        if (tools.length == 1) {
            tools[0].node.SetDeepEnabled(true);
        } else {
            activeToolIndex++;
            if (activeToolIndex >= tools.length) {
                activeToolIndex = 0;
            }
            for (uint i = 0; i < tools.length; i++) {
                Node@ node = tools[i].node;
                node.SetDeepEnabled(false);
            }
            activeTool = tools[activeToolIndex];
            tools[activeToolIndex].node.SetDeepEnabled(true);
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
}
