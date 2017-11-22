namespace Spawn {
    const uint SPAWN_UNIT_SNAKE = 1;
    const uint SPAWN_UNIT_PACMAN = 2;
    const uint SPAWN_UNIT_ROCK = 3;
    const uint SPAWN_UNIT_CLOUD = 4;

    //Instead of checking units each frame, spawner will
    //check distances for spawner units and decide their fate
    const float SPAWNED_OBJECT_CHECK_TIME = 20.0f;

    //Whats the safe distance from the player
    //All units further than this distance from the camera can be safely removed
    //if spawner configuration supports it
    const float SPAWNED_OBJECT_SAFE_DISTANCE = 200.0f;
    const float SPAWNED_OBJECT_SAFE_DISTANCE_SQUARED = SPAWNED_OBJECT_SAFE_DISTANCE * SPAWNED_OBJECT_SAFE_DISTANCE * SPAWNED_OBJECT_SAFE_DISTANCE;

    //If camera is closer than this distance
    //disable spawner
    const float SPAWN_NEAR_DISTANCE = 10.0f;
    const float SPAWN_NEAR_DISTANCE_SQUARED = SPAWN_NEAR_DISTANCE * SPAWN_NEAR_DISTANCE * SPAWN_NEAR_DISTANCE;

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
    };

    Array<Spawner> spawners;

    void Create(Vector3 position, float minSpawnRadius, float maxSpawnRadius, float maxUnitRadius, uint maxUnits, float spawnTime, uint type)
    {
        Spawner spawner;
        spawner.node = scene_.CreateChild("Spawner");
        spawner.node.temporary = true;
        spawner.node.AddTag("Spawner");
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
    }

    void Init()
    {
        Array<Node@> spawnPoints = scene_.GetNodesWithTag("Spawner");
        for (uint i = 0; i < spawnPoints.length; i++) {
//            Create(spawnPoints.worldPosition, 10.0f, 500.0f, 5, 10.0f, Spawn::T
        }
    }

    Vector3 GetRandomPositionInRange(Spawner& spawner)
    {
        Vector3 position = spawner.node.position;
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
        Node@ node = Pickable::Create(GetRandomPositionInRange(spawner), "Rock", "Models/Models/Small_rock" + rockModelNum + ".mdl");
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

    bool isNearToPlayer(Node@ node)
    {
        Vector3 diff = node.worldPosition - cameraNode.worldPosition;
        if (diff.lengthSquared < SPAWN_NEAR_DISTANCE_SQUARED) {
            return true;
        }
        return false;   
    }

    bool IsFarFromPlayer(Node@ node)
    {
        Vector3 diff = node.worldPosition - cameraNode.worldPosition;
        if (diff.lengthSquared > SPAWNED_OBJECT_SAFE_DISTANCE_SQUARED) {
            return true;
        }
        return false;
    }

    void CheckSpawner(Spawner& spawner)
    {
        //log.Warning("Checking spawner[" + spawner.node.id + "]");
        for (uint i = 0; i < spawner.units.length; i++) {
            Vector3 diff = spawner.units[i].worldPosition - spawner.node.worldPosition;
            if (diff.lengthSquared > spawner.maxUnitRadius * spawner.maxUnitRadius * spawner.maxUnitRadius) {
                if (!IsFarFromPlayer(spawner.units[i])) {
                    //log.Warning("Unit[" + spawner.units[i].id + "] reached max radius[" + spawner.maxUnitRadius + "] of spawner, but too close to player, disabling delete!");
                    continue;
                }
                //log.Warning("Unit[" + spawner.units[i].id + "] reached max radius[" + spawner.maxUnitRadius + "] of spawner, deleting it!");
                if (spawner.type == SPAWN_UNIT_SNAKE) {
                    Snake::DestroyById(spawner.units[i].id);
                } else if (spawner.type == SPAWN_UNIT_PACMAN) {
                    Pacman::DestroyById(spawner.units[i].id);
                } else if (spawner.type == SPAWN_UNIT_ROCK) {
                    Pickable::DestroyById(spawner.units[i].id);
                } else if (spawner.type == SPAWN_UNIT_CLOUD) {
                    Clouds::DestroyById(spawner.units[i].id);
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
        for (uint i = 0; i < spawners.length; i++) {
            spawners[i].lastSpawnTime += timeStep;
            spawners[i].lastCheckTime += timeStep;
            if (spawners[i].lastCheckTime > SPAWNED_OBJECT_CHECK_TIME) {
                CheckSpawner(spawners[i]);
            }
            if (spawners[i].lastSpawnTime >= spawners[i].spawnTime) {
                if (IsFarFromPlayer(spawners[i].node)) {
                    //Spawner is too far from player, don't spawn any units
                    //log.Warning("Spawner is too far from player, not spawning any units");
                    spawners[i].lastSpawnTime = 0.0f;
                    continue;
                }
                if (isNearToPlayer(spawners[i].node)) {
                    //Spawner is too far from player, don't spawn any units
                    //log.Warning("Spawner is close to player, not spawning any units " + "[" + spawners[i].node.position.x + "," + spawners[i].node.position.y + "," + spawners[i].node.position.z + "] VS [" + cameraNode.position.x + "," + cameraNode.position.y + "," + cameraNode.position.z + "]");
                    spawners[i].lastSpawnTime = 0.0f;
                    continue;
                }
                if (spawners[i].units.length < spawners[i].maxUnits) {
                    if (spawners[i].type == SPAWN_UNIT_SNAKE) {
                        CreateSnake(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_PACMAN) {
                        CreatePacman(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_ROCK) {
                        CreateRock(spawners[i]);
                    } else if (spawners[i].type == SPAWN_UNIT_CLOUD) {
                        CreateCloud(spawners[i]);
                    }
                }
            }
        }
    }
}