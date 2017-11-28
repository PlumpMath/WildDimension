namespace Spawn {
    const uint SPAWN_UNIT_SNAKE = 1;
    const uint SPAWN_UNIT_PACMAN = 2;
    const uint SPAWN_UNIT_ROCK = 3;
    const uint SPAWN_UNIT_CLOUD = 4;
    const uint SPAWN_UNIT_GRASS = 5;
    const uint SPAWN_UNIT_APPLE = 6;
    const uint SPAWN_UNIT_RASPBERRY = 7;
    const uint SPAWN_UNIT_TETRIS = 8;

    //Instead of checking units each frame, spawner will
    //check distances for spawner units and decide their fate
    const float SPAWNED_OBJECT_CHECK_TIME = 10.0f;

    //Whats the safe distance from the player
    //All units further than this distance from the camera can be safely removed
    //if spawner configuration supports it
    const float SPAWNED_OBJECT_SAFE_DISTANCE = 700.0f;

    //If camera is closer than this distance
    //disable spawner
    const float SPAWN_NEAR_DISTANCE = 20.0f;

    bool debug = false;

    class Spawner {
        Node@ node;
        float maxSpawnRadius;
        float minSpawnRadius;
        uint maxUnits;
        float spawnTime;
        float maxUnitRadius;
        float lastSpawnTime;
        uint type;
        Array<Node@> units;
        float lastCheckTime;
        StaticModel@ model;
    };

    float nextDebugUpdate;
    Array<Spawner> spawners;
    Node@ Create(Vector3 position, float minSpawnRadius, float maxSpawnRadius, float maxUnitRadius, uint maxUnits, float spawnTime, uint type)
    {
        Spawner spawner;
        spawner.node = scene_.CreateChild("Spawner");
        spawner.model = spawner.node.CreateComponent("StaticModel");
        spawner.model.model = cache.GetResource("Model", "Models/Box.mdl");
        spawner.model.materials[0] = cache.GetResource("Material", "Materials/TreeGreen.xml");

        spawner.node.SetScale(20.0f);
        if (debug) {
            spawner.model.enabled = true;
        } else {
            spawner.model.enabled = false;
        }
        spawner.node.temporary = true;
        spawner.node.AddTag("Spawner");

        //Disable enemy spawning by default
        if (type == SPAWN_UNIT_SNAKE || type == SPAWN_UNIT_PACMAN || type == SPAWN_UNIT_TETRIS) {
            spawner.node.enabled = false;
        }

        //position.y = NetworkHandler::terrain.GetHeight(position);
        spawner.node.position = position;
        spawner.maxUnits = maxUnits;
        spawner.minSpawnRadius = minSpawnRadius;
        spawner.maxSpawnRadius = maxSpawnRadius;
        spawner.maxUnitRadius = maxUnitRadius;
        spawner.spawnTime = spawnTime;
        spawner.lastSpawnTime = 0.0f;
        spawner.type = type;
        spawner.lastCheckTime = Random(10.0f);
        spawners.Push(spawner);

        return spawner.node;
    }

    int GetSpawnersCount()
    {
        return spawners.length; 
    }

    int GetSpawnedUnitsCount()
    {
        int count = 0;
        for (uint i = 0; i < spawners.length; i++) {
            count += spawners[i].units.length;
        }
        return count;
    }

    int GetSpawnedUnitsCountByType(uint type)
    {
        int count = 0;
        for (uint i = 0; i < spawners.length; i++) {
            if (spawners[i].type == type) {
                count += spawners[i].units.length;
            }
        }
        return count;
    }

    void Init()
    {
        Array<Node@> spawnPoints = scene_.GetNodesWithTag("Spawner");
        for (uint i = 0; i < spawnPoints.length; i++) {
//            Create(spawnPoints.worldPosition, 10.0f, 500.0f, 5, 10.0f, Spawn::T
        }
        Subscribe();
        RegisterConsoleCommands();

        Create(Places::getPlacePosition("Stonehenge"), 0, 10, 100.0, 1, 1.0f, SPAWN_UNIT_SNAKE);
        Create(Places::getPlacePosition("Stonehenge"), 0, 10, 100.0, 1, 1.0f, SPAWN_UNIT_PACMAN);
        Create(Places::getPlacePosition("Stonehenge"), 0, 200, 200.0, 100, 0.1f, SPAWN_UNIT_ROCK);
    }

    void Subscribe()
    {
        SubscribeToEvent("ActivateSpawners", "Spawn::HandlActivateSpawners");
        SubscribeToEvent("DeactivateSpawners", "Spawn::HandlDeactivateSpawners");

        SubscribeToEvent("ActivateSnakeSpawners", "Spawn::HandlActivateSnakeSpawners");
        SubscribeToEvent("DeactivateSnakeSpawners", "Spawn::HandlDeactivateSnakeSpawners");

        SubscribeToEvent("ActivatePacmanSpawners", "Spawn::HandlActivatePacmanSpawners");
        SubscribeToEvent("DeactivatePacmanSpawners", "Spawn::HandlDeactivatePacmanSpawners");

        SubscribeToEvent("ActivateTetrisSpawners", "Spawn::HandlActivateTetrisSpawners");
        SubscribeToEvent("DeactivateTetrisSpawners", "Spawn::HandlDeactivateTetrisSpawners");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;

        data["CONSOLE_COMMAND_NAME"] = "spawners_activate";
        data["CONSOLE_COMMAND_EVENT"] = "ActivateSpawners";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "spawners_deactivate";
        data["CONSOLE_COMMAND_EVENT"] = "DectivateSpawners";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "spawners_snake_activate";
        data["CONSOLE_COMMAND_EVENT"] = "ActivateSnakeSpawners";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "spawners_snake_deactivate";
        data["CONSOLE_COMMAND_EVENT"] = "DeactivateSnakeSpawners";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "spawners_pacman_activate";
        data["CONSOLE_COMMAND_EVENT"] = "ActivatePacmanSpawners";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "spawners_pacman_deactivate";
        data["CONSOLE_COMMAND_EVENT"] = "DeactivatePacmanSpawners";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "spawners_tetris_activate";
        data["CONSOLE_COMMAND_EVENT"] = "ActivateTetrisSpawners";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "spawners_tetris_deactivate";
        data["CONSOLE_COMMAND_EVENT"] = "DeactivateTetrisSpawners";
        SendEvent("ConsoleCommandAdd", data);
    }

    void ChangeSpawnersStateByType(uint type, bool enabled)
    {
        for (uint i = 0; i < spawners.length; i++) {
            if (spawners[i].type == type) {
                log.Warning("Spawner[" + i + "] " + enabled);
                spawners[i].node.enabled = enabled;
            }
        }
    }

    void HandlActivateSpawners(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Activating all spawners...");
        ChangeSpawnersStateByType(SPAWN_UNIT_SNAKE, true);
        ChangeSpawnersStateByType(SPAWN_UNIT_PACMAN, true);
        ChangeSpawnersStateByType(SPAWN_UNIT_ROCK, true);
        ChangeSpawnersStateByType(SPAWN_UNIT_CLOUD, true);
    }

    void HandlDeactivateSpawners(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Deactivating all spawners...");
        ChangeSpawnersStateByType(SPAWN_UNIT_SNAKE, false);
        ChangeSpawnersStateByType(SPAWN_UNIT_PACMAN, false);
        ChangeSpawnersStateByType(SPAWN_UNIT_ROCK, false);
        ChangeSpawnersStateByType(SPAWN_UNIT_CLOUD, false);
    }

    void HandlActivateSnakeSpawners(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Activating snake spawners...");
        ChangeSpawnersStateByType(SPAWN_UNIT_SNAKE, true);
    }

    void HandlDeactivateSnakeSpawners(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Dectivating snake spawners...");
        ChangeSpawnersStateByType(SPAWN_UNIT_SNAKE, false);
    }

    void HandlActivateTetrisSpawners(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Activating tetris spawners...");
        ChangeSpawnersStateByType(SPAWN_UNIT_TETRIS, true);
    }

    void HandlDeactivateTetrisSpawners(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Dectivating tetris spawners...");
        ChangeSpawnersStateByType(SPAWN_UNIT_TETRIS, false);
    }

    void HandlActivatePacmanSpawners(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Activating pacman spawners...");
        ChangeSpawnersStateByType(SPAWN_UNIT_PACMAN, true);
    }

    void HandlDeactivatePacmanSpawners(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Deactivating pacman spawners...");
        ChangeSpawnersStateByType(SPAWN_UNIT_PACMAN, false);
    }

    Vector3 GetRandomPositionInRange(Spawner& spawner)
    {
        Vector3 position = spawner.node.worldPosition;
        float randX = Random(spawner.maxSpawnRadius - spawner.minSpawnRadius) + spawner.minSpawnRadius;
        if (RandomInt(2) == 0) {
            position.x -= randX;
        } else {
            position.x += randX;
        }

        float randY = Random(spawner.maxSpawnRadius - spawner.minSpawnRadius);
        if (RandomInt(2) == 0) {
            position.y -= randY;
        } else {
            position.y += randY;
        }

        float randZ = Random(spawner.maxSpawnRadius - spawner.minSpawnRadius);
        if (RandomInt(2) == 0) {
            position.z -= randZ;
        } else {
            position.z += randZ;
        }
        return position;
    }

    void CreateSnake(Spawner& spawner)
    {
        Node@ node = Snake::Create(GetRandomPositionInRange(spawner));
        //log.Warning("Spawner creating snake[" + node.id + "]");
        spawner.units.Push(node);
        spawner.lastSpawnTime = 0.0f;
    }

    void CreatePacman(Spawner& spawner)
    {
        Node@ node = Pacman::Create(GetRandomPositionInRange(spawner));
        //log.Warning("Spawner creating pacman[" + node.id + "]");
        spawner.units.Push(node);
        spawner.lastSpawnTime = 0.0f;
    }

    void CreateRock(Spawner& spawner)
    {
        int rockModelNum = 1 + RandomInt(4);   
        Node@ node = Pickable::Create(GetRandomPositionInRange(spawner), "Rock", "Models/Models/Small_rock" + rockModelNum + ".mdl", 2.0);
        //log.Warning("Spawner creating rock[" + node.id + "]");
        spawner.units.Push(node);
        spawner.lastSpawnTime = 0.0f;
    }

    void CreateCloud(Spawner& spawner)
    {
        Node@ node = Clouds::Create(GetRandomPositionInRange(spawner));
        //log.Warning("Spawner creating cloud[" + node.id + "]");
        spawner.units.Push(node);
        spawner.lastSpawnTime = 0.0f;
    }

    void CreateGrass(Spawner& spawner)
    {
        Node@ node = EnvObjects::CreateBillboard(GetRandomPositionInRange(spawner), "Materials/Grass.xml");
        spawner.units.Push(node);
        spawner.lastSpawnTime = 0.0f;
    }

    void CreateApple(Spawner& spawner)
    {
        Node@ node = Pickable::Create(GetRandomPositionInRange(spawner), "Apple", "Models/Models/Apple.mdl", Random(0.8) + 0.5);
        spawner.units.Push(node);
        spawner.lastSpawnTime = 0.0f;
    }

    void CreateRaspberry(Spawner& spawner)
    {
        Node@ node = Pickable::Create(GetRandomPositionInRange(spawner), "Raspberry", "Models/Models/Raspberry.mdl", Random(0.8) + 0.5);
        spawner.units.Push(node);
        spawner.lastSpawnTime = 0.0f;
    }

    void CreateTetris(Spawner& spawner)
    {
        int number = RandomInt(10) + 1;
        Node@ node = EnvObjects::CreateTimed(GetRandomPositionInRange(spawner), "Models/Models/" + number + ".mdl", true, 20.0f, "Tetris");
        spawner.lastSpawnTime = 0.0f;
    }

    bool isNearToPlayer(Node@ node)
    {
        Vector3 diff = node.worldPosition - cameraNode.worldPosition;
        if (diff.length < SPAWN_NEAR_DISTANCE) {
            return true;
        }
        return false;   
    }

    bool IsFarFromPlayer(Node@ node)
    {
        Vector3 diff = node.worldPosition - cameraNode.worldPosition;
        if (diff.length > SPAWNED_OBJECT_SAFE_DISTANCE) {
            return true;
        }
        return false;
    }

    void CheckSpawner(Spawner& spawner)
    {
        //log.Warning("Checking spawner[" + spawner.node.id + "]");
        for (uint i = 0; i < spawner.units.length; i++) {
            Vector3 diff = spawner.units[i].worldPosition - spawner.node.worldPosition;
            if (diff.length > spawner.maxUnitRadius || IsFarFromPlayer(spawner.units[i])) {
                if (!IsFarFromPlayer(spawner.units[i])) {
                    //log.Warning("Unit " + spawner.units[i].name + "[" + spawner.units[i].id + "] reached max radius[" + spawner.maxUnitRadius + "] of spawner, but too close to player, disabling delete!");
                    continue;
                }
                //log.Warning("Unit " + spawner.units[i].name + "[" + spawner.units[i].id + "] reached max radius[" + spawner.maxUnitRadius + "] of spawner, deleting it!");
                if (spawner.type == SPAWN_UNIT_SNAKE) {
                    Snake::DestroyById(spawner.units[i].id);
                } else if (spawner.type == SPAWN_UNIT_PACMAN) {
                    Pacman::DestroyById(spawner.units[i].id);
                } else if (spawner.type == SPAWN_UNIT_ROCK) {
                    Pickable::DestroyById(spawner.units[i].id);
                } else if (spawner.type == SPAWN_UNIT_CLOUD) {
                    Clouds::DestroyById(spawner.units[i].id);
                } else if (spawner.type == SPAWN_UNIT_GRASS) {
                    EnvObjects::DestroyById(spawner.units[i].id);
                } else if (spawner.type == SPAWN_UNIT_APPLE) {
                    Pickable::DestroyById(spawner.units[i].id);
                } else if (spawner.type == SPAWN_UNIT_RASPBERRY) {
                    Pickable::DestroyById(spawner.units[i].id);
                }
                spawner.units.Erase(i);
            } else {
                if (scene_.GetNode(spawner.units[i].id) is null) {
                    //log.Warning("Spawner unit[" + spawner.units[i].id + "] was removed from scene");
                    spawner.units.Erase(i);
                }
            }
        }
        spawner.lastCheckTime = 0.0f;
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        nextDebugUpdate -= timeStep;
        if (nextDebugUpdate < 0.0f) {
            nextDebugUpdate = 0.5f;
            SendEvent("UpdateSpawnerDebug");
        }
        for (uint i = 0; i < spawners.length; i++) {
            spawners[i].lastSpawnTime += timeStep;
            spawners[i].lastCheckTime += timeStep;
            if (spawners[i].lastCheckTime > SPAWNED_OBJECT_CHECK_TIME) {
                CheckSpawner(spawners[i]);
            }
            if (!spawners[i].node.enabled) {
                continue;
            }
            if (spawners[i].lastSpawnTime >= spawners[i].spawnTime) {
                if (IsFarFromPlayer(spawners[i].node)) {
                    //Spawner is too far from player, don't spawn any units
                    //log.Warning("Spawner is too far from player, not spawning any units");
                    spawners[i].lastSpawnTime = 0.0f;
                    spawners[i].model.materials[0] = cache.GetResource("Material", "Materials/TreeYellow.xml");
                    continue;
                } else if (isNearToPlayer(spawners[i].node)) {
                    //Spawner is too far from player, don't spawn any units
                    //log.Warning("Spawner is close to player, not spawning any units " + "[" + spawners[i].node.position.x + "," + spawners[i].node.position.y + "," + spawners[i].node.position.z + "] VS [" + cameraNode.position.x + "," + cameraNode.position.y + "," + cameraNode.position.z + "]");
                    spawners[i].lastSpawnTime = 0.0f;
                    spawners[i].model.materials[0] = cache.GetResource("Material", "Materials/TreeYellow.xml");
                    continue;
                } else if (spawners[i].units.length < spawners[i].maxUnits) {
                    spawners[i].model.materials[0] = cache.GetResource("Material", "Materials/TreeGreen.xml");
                    if (spawners[i].type == SPAWN_UNIT_SNAKE) {
                        CreateSnake(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_PACMAN) {
                        CreatePacman(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_ROCK) {
                        CreateRock(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_CLOUD) {
                        CreateCloud(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_GRASS) {
                        CreateGrass(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_APPLE) {
                        CreateApple(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_RASPBERRY) {
                        CreateRaspberry(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_TETRIS) {
                        CreateTetris(spawners[i]);
                    } 
                }
            }
        }
    }
}