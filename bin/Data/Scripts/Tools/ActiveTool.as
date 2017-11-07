namespace ActiveTool {
    Node@ node;
    Node@ toolNode;
    Array<Node@> tools;
    uint activeToolIndex = 0;
    bool use = false;
    bool back = false;
    float sleepTime = 0.0f;

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

        if (Raycast(2.0f, hitPos, hitDrawable, direction))
        {
            // Check if target scene node already has a DecalSet component. If not, create now
            Node@ targetNode = hitDrawable.node;
            log.Info("Hit " + targetNode.name);
            float hitPower = 20;
            if (targetNode.HasTag("Adj")) {
                if (targetNode.GetParentComponent("RigidBody") !is null) {
                    RigidBody@ body = targetNode.GetParentComponent("RigidBody");
                    body.ApplyImpulse(direction * hitPower * body.mass);
                }
            } else {
                if (targetNode.HasComponent("RigidBody")) {
                    RigidBody@ body = targetNode.GetComponent("RigidBody");
                    body.ApplyImpulse(direction * hitPower * body.mass);
                }
            }
            if (targetNode.name == "Tree") {
                AxeHit(hitPos);
            }
            /*DecalSet@ decal = targetNode.GetComponent("DecalSet");
            if (decal is null)
            {
                decal = targetNode.CreateComponent("DecalSet");
                decal.material = cache.GetResource("Material", "Materials/UrhoDecal.xml");
            }
            // Add a square decal to the decal set using the geometry of the drawable that was hit, orient it to face the camera,
            // use full texture UV's (0,0) to (1,1). Note that if we create several decals to a large object (such as the ground
            // plane) over a large area using just one DecalSet component, the decals will all be culled as one unit. If that is
            // undesirable, it may be necessary to create more than one DecalSet based on the distance
            decal.AddDecal(hitDrawable, hitPos, cameraNode.rotation, 0.5f, 1.0f, 1.0f, Vector2::ZERO, Vector2::ONE);
            */
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        sleepTime -= timeStep;
        if (tools.length > 0) {
            if (input.mouseButtonDown[MOUSEB_LEFT] && use == false && sleepTime <= 0) {
                use = true;
                toolNode.Roll(-60.0f);
                back = true;
                sleepTime = 0.2f;
                HitObject();
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
            tools[0].SetDeepEnabled(true);
        } else {
            activeToolIndex++;
            if (activeToolIndex >= tools.length) {
                activeToolIndex = 0;
            }
            for (uint i = 0; i < tools.length; i++) {
                Node@ node = tools[i];
                node.SetDeepEnabled(false);
            }
            tools[activeToolIndex].SetDeepEnabled(true);
        }
    }

    void SetActiveTool(Node@ newTool)
    {
        for (uint i = 0; i < tools.length; i++) {
            Node@ node = tools[i];
            if (newTool.id == node.id) {
                node.SetDeepEnabled(true);
                activeToolIndex = i;
            } else {
                node.SetDeepEnabled(false);
            }
        }
    }
}
