//apple -> abols, lapa, katins
//apple tree ->  stumbrs, lapas
//axe -> metals, kats
//big fireplace -> kocins, kocins, akmeni
//big tree -> stumbrs, lapas
//flag -> koks, audums
//+ House -> durvju aile, arejas sienas, ieksejas sienas, jumts
//+ House3 -> durvju aile, arejas sienas, ieksejas sienas, jumts, trepes
//stem -> celma malas, celma virsotne, cirvja kats, cirvja metals
//torch -> kats, augsha


namespace EnvObjects {
    Array<Node@> objects;
    class TimedObject {
        Node@ node;
        float lifetime;
    };
    Array<TimedObject> timedObjects;

    Node@ Create(Vector3 position, String model, bool temporary = true, String name = "Custom")
    {
        if (Places::IsInDistance(position, 50)) {
            //Too close to place, not creating env model
            log.Warning("Unable to create env object, because place is too near!");
            return null;
        }

        Node@ node = scene_.CreateChild(name);
        node.temporary = temporary;
        position.y = NetworkHandler::terrain.GetHeight(position);
        node.position = position;

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", model);
        node.SetScale(1.0f);
        object.castShadows = true;
        if (name == "House1" || name == "House2") {
            object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
            object.materials[1] = cache.GetResource("Material", "Materials/Wood.xml");
            object.materials[2] = cache.GetResource("Material", "Materials/Wood.xml");
            object.materials[3] = cache.GetResource("Material", "Materials/Roof.xml");
        } else if (name == "House3") {
            object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
            object.materials[1] = cache.GetResource("Material", "Materials/Wood.xml");
            object.materials[2] = cache.GetResource("Material", "Materials/Wood.xml");
            object.materials[3] = cache.GetResource("Material", "Materials/Roof.xml");
            object.materials[4] = cache.GetResource("Material", "Materials/Stone.xml");
        } else if (name == "Rock") {
            object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");
        } else if (name == "Tree") {
            object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
            if (RandomInt(2) == 1) {
                object.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
            } else {
                object.materials[1] = cache.GetResource("Material", "Materials/TreeYellow.xml");
            }
            node.SetScale(10.0f);
        }
        
        object.viewMask = VIEW_MASK_INTERACTABLE;

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        RigidBody@ body = node.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_STATIC_OBJECTS;
        body.collisionMask = COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_FOOD_LEVEL;
        body.mass = 0.0f;

        // Set zero angular factor so that physics doesn't turn the character on its own.
        // Instead we will control the character yaw manually
        body.angularFactor = Vector3::ZERO;

        // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
        //body.collisionEventMode = COLLISION_ALWAYS;


        // Set a capsule shape for collision
        CollisionShape@ shape = node.CreateComponent("CollisionShape");
        shape.SetTriangleMesh(object.model);

        objects.Push(node);

        return node;
    }

    Node@ CreateTimed(Vector3 position, String model, bool temporary = true, float lifetime = 10.0f, String name = "Custom")
    {

        Node@ node = scene_.CreateChild(name);
        node.temporary = temporary;
        node.position = position;

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", model);
        node.SetScale(2.0f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");
        
        object.viewMask = VIEW_MASK_INTERACTABLE;

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        RigidBody@ body = node.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_FOOD_LEVEL;
        body.collisionMask = COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_FOOD_LEVEL | COLLISION_TERRAIN_LEVEL;
        body.mass = 10.0f;
        body.linearVelocity = Vector3(0, -100, 0);

        // Set a capsule shape for collision
        CollisionShape@ shape = node.CreateComponent("CollisionShape");
        shape.SetConvexHull(object.model);

        TimedObject timedObject;
        timedObject.lifetime = lifetime;
        timedObject.node = node;
        timedObjects.Push(timedObject);

        return node;
    }

    Node@ CreateBillboard(Vector3 position, String material, bool temporary = true, String name = "Custom")
    {
        Node@ node = scene_.CreateChild(name);
        node.temporary = temporary;
        position.y = NetworkHandler::terrain.GetHeight(position) + 0.5f;
        node.rotation = Quaternion(Vector3(0.0f, 1.0f, 0.0f), NetworkHandler::terrain.GetNormal(position));
        node.position = position;
        node.SetScale(1.0f);

        const int NUM_BILLBOARDS = 5;
        BillboardSet@ billboardObject = node.CreateComponent("BillboardSet");
        billboardObject.numBillboards = NUM_BILLBOARDS;
        billboardObject.material = cache.GetResource("Material", material);
        billboardObject.sorted = true;
        billboardObject.faceCameraMode = FC_ROTATE_Y;


        for (uint j = 0; j < NUM_BILLBOARDS; ++j)
        {
            Vector3 subPosition = Vector3(Random(5.0f), 0, Random(5.0f));
            Billboard@ bb = billboardObject.billboards[j];
            subPosition.y = NetworkHandler::terrain.GetHeight(position);
            //bb.position = subPosition;
            bb.size = Vector2(1.0f + Random(1.0f), 1.0f + Random(1.0f));
            //bb.rotation = 120 * j;
            //bb.direction = Vector3(j, 0, j);
            bb.enabled = true;
        }

        objects.Push(node);
        return node;
    }

    void DestroyById(uint id)
    {
        for (uint i = 0; i < objects.length; i++) {
            if (objects[i].id == id) {
                objects[i].Remove();
                objects.Erase(i);
                return;
            }
        }
    }

    void Subscribe()
    {
        SubscribeToEvent("SpawnObject", "EnvObjects::HandleSpawnObject");
        SubscribeToEvent("DestroySpawnedObject", "EnvObjects::HandleDestroySpawnedObject");
        //DelayedExecute(5.0, false, "void EnvObjects::DisableFurthestObjects()");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "spawn";
        data["CONSOLE_COMMAND_EVENT"] = "SpawnObject";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "spawn_destroy";
        data["CONSOLE_COMMAND_EVENT"] = "DestroySpawnedObject";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandleSpawnObject(StringHash eventType, VariantMap& eventData)
    {
        Array<String> commands = eventData["PARAMETERS"].GetStringVector();
        if (commands.length < 2) {
            log.Error("'spawn' command expects second argument!");
            return;
        }
    
        Vector3 position = cameraNode.position;
        position += cameraNode.direction * 10;
        Create(position, commands[1], false, "Custom");
    }

    void HandleDestroySpawnedObject(StringHash eventType, VariantMap& eventData)
    {
        if (objects.length > 0) {
            objects[objects.length - 1].Remove();
            objects.Erase(objects.length - 1);
        }
    }

    void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        for (uint i = 0; i < timedObjects.length; i++) {
            timedObjects[i].lifetime -= timeStep;
            if (timedObjects[i].lifetime < 0) {
                timedObjects[i].node.Remove();
                timedObjects.Erase(i);
                i--;
            }
        }

        if (objects.length > 0) {
            //Move front
            if (input.keyDown[KEY_KP_8]) {
                Vector3 position = objects[objects.length - 1].position;
                position.z -= timeStep;
                objects[objects.length - 1].position = position;
            }
            //Move back
            if (input.keyDown[KEY_KP_2]) {
                Vector3 position = objects[objects.length - 1].position;
                position.z += timeStep;
                objects[objects.length - 1].position = position;
            }
            //Move left
            if (input.keyDown[KEY_KP_4]) {
                Vector3 position = objects[objects.length - 1].position;
                position.x += timeStep;
                objects[objects.length - 1].position = position;
            }
            //Move right
            if (input.keyDown[KEY_6]) {
                Vector3 position = objects[objects.length - 1].position;
                position.x -= timeStep;
                objects[objects.length - 1].position = position;
            }
            //Move up
            if (input.keyDown[KEY_KP_9]) {
                Vector3 position = objects[objects.length - 1].position;
                position.y += timeStep;
                objects[objects.length - 1].position = position;
            }
            //Move down
            if (input.keyDown[KEY_KP_3]) {
                Vector3 position = objects[objects.length - 1].position;
                position.y -= timeStep;
                objects[objects.length - 1].position = position;
            }

            //Rotate Y
            if (input.keyDown[KEY_I]) {
                objects[objects.length - 1].Yaw(timeStep * 10);
            }
            if (input.keyDown[KEY_J]) {
                objects[objects.length - 1].Yaw(-timeStep * 10);
            }
            //Rotate X
            if (input.keyDown[KEY_O]) {
                objects[objects.length - 1].Pitch(timeStep * 10);
            }
            if (input.keyDown[KEY_K]) {
                objects[objects.length - 1].Pitch(-timeStep * 10);
            }
            //Rotate Z
            if (input.keyDown[KEY_P]) {
                objects[objects.length - 1].Roll(timeStep * 10);
            }
            if (input.keyDown[KEY_L]) {
                objects[objects.length - 1].Roll(-timeStep * 10);
            }

            if (input.keyDown[KEY_KP_PLUS]) {
                Vector3 oldScale = objects[objects.length - 1].scale;
                oldScale.x += timeStep;
                oldScale.y += timeStep;
                oldScale.z += timeStep;
                objects[objects.length - 1].Scale(oldScale);
            }
            if (input.keyDown[KEY_KP_MINUS]) {
                Vector3 oldScale = objects[objects.length - 1].scale;
                oldScale.x -= timeStep;
                oldScale.y -= timeStep;
                oldScale.z -= timeStep;
                objects[objects.length - 1].Scale(oldScale);
            }
        }
    }


}