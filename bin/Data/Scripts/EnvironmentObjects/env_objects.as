namespace EnvObjects {
    Array<Node@> objects;

    Node@ Create(Vector3 position, String model)
    {
        Node@ node = scene_.CreateChild();
        node.AddTag("Rock");
        node.temporary = true;
        position.y = NetworkHandler::terrain.GetHeight(position);
        node.position = position;

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", model);
        node.SetScale(1.0f + Random(0.5f));
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        RigidBody@ body = node.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_STATIC_OBJECTS;
        body.collisionMask = COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_FOOD_LEVEL;
        body.mass = 0.0f;

        // Set zero angular factor so that physics doesn't turn the character on its own.
        // Instead we will control the character yaw manually
        body.angularFactor = Vector3::ZERO;

        // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
        body.collisionEventMode = COLLISION_ALWAYS;

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
        Create(position, commands[1]);
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
            if (input.keyDown[KEY_I]) {
                Vector3 position = objects[objects.length - 1].position;
                position.z -= timeStep;
                objects[objects.length - 1].position = position;
            }
            if (input.keyDown[KEY_K]) {
                Vector3 position = objects[objects.length - 1].position;
                position.z += timeStep;
                objects[objects.length - 1].position = position;
            }
            if (input.keyDown[KEY_J]) {
                Vector3 position = objects[objects.length - 1].position;
                position.x += timeStep;
                objects[objects.length - 1].position = position;
            }
            if (input.keyDown[KEY_L]) {
                Vector3 position = objects[objects.length - 1].position;
                position.x -= timeStep;
                objects[objects.length - 1].position = position;
            }
            if (input.keyDown[KEY_U]) {
                Vector3 position = objects[objects.length - 1].position;
                position.y += timeStep;
                objects[objects.length - 1].position = position;
            }
            if (input.keyDown[KEY_H]) {
                Vector3 position = objects[objects.length - 1].position;
                position.y -= timeStep;
                objects[objects.length - 1].position = position;
            }

            if (input.keyDown[KEY_B]) {
                objects[objects.length - 1].Yaw(timeStep * 10);
            }
            if (input.keyDown[KEY_N]) {
                objects[objects.length - 1].Pitch(timeStep * 10);
            }
            if (input.keyDown[KEY_M]) {
                objects[objects.length - 1].Roll(timeStep * 10);
            }
        }
    }
}