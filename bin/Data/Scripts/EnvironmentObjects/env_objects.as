//apple -> abols, lapa, katins
//apple tree ->  stumbrs, lapas
//axe -> metals, kats
//big fireplace -> kocins, kocins, akmeni
//big tree -> stumbrs, lapas
//flag -> koks, audums
//House -> durvju aile, arejas sienas, ieksejas sienas, jumts
//House3 -> durvju aile, arejas sienas, ieksejas sienas, jumts, trepes
//stem -> celma malas, celma virsotne, cirvja kats, cirvja metals
//torch -> kats, augsha


namespace EnvObjects {
    Array<Node@> objects;

    Node@ Create(Vector3 position, String model, bool temporary = true, String name = "Custom")
    {
        Node@ node = scene_.CreateChild(name);
        node.temporary = temporary;
        position.y = NetworkHandler::terrain.GetHeight(position);
        node.position = position;

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", model);
        node.SetScale(1.0f);
        object.castShadows = true;
        for (uint i = 0; i < 10; i++) {
            Array<String> mat;
            mat.Push("Materials/Wood.xml");
            mat.Push("Materials/Stone.xml");
            mat.Push("Materials/Metal.xml");
            object.materials[i] = cache.GetResource("Material", mat[RandomInt(mat.length)]);
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

    void Subscribe()
    {
        SubscribeToEvent("SpawnObject", "EnvObjects::HandleSpawnObject");
        SubscribeToEvent("DestroySpawnedObject", "EnvObjects::HandleDestroySpawnedObject");
        DelayedExecute(5.0, false, "void EnvObjects::DisableFurthestObjects()");
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
        Node@ node = Create(position, commands[1], false, "Custom");
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

    void DisableFurthestObjects()
    {
        log.Warning("EnvObjects::DisableFurthestObjects");
        for (uint i = 0; i < objects.length; i++) {
            Node@ obj = objects[i];
            int distanceSquared = Vector3(cameraNode.position - obj.position).lengthSquared;
            if (distanceSquared > DISTANCE_FACTOR * DISTANCE_FACTOR * DISTANCE_FACTOR) {
                obj.enabled = false;
            } else {
                obj.enabled = true;
            }
        }
        DelayedExecute(5.0, false, "void EnvObjects::DisableFurthestObjects()");
    }
}