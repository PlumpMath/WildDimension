namespace Pacman {
    const uint STAGE_MOVE = 0;
    const uint STAGE_SLEEP = 1;
    const uint STAGE_DULL = 2;

    class SinglePacman {
        Node@ node;
        ParticleEmitter@ sleepParticleEmitter;
        ParticleEmitter@ dullParticleEmitter;
        uint stage;
        float sleepTime;
        Node@ targetNode;
        float lifetime;
        float nextFoodCheck;
    };
    Array<SinglePacman> pacmans;
    const float PACMAN_MOVE_SPEED = 0.05f;

    Node@ Create(Vector3 position)
    {
        Node@ pacmanNode = scene_.CreateChild("Pacman");
        pacmanNode.AddTag("Enemy");
        pacmanNode.AddTag("Pacman");
        pacmanNode.temporary = true;
        position.y = NetworkHandler::terrain.GetHeight(position) + 2;
        pacmanNode.position = position;
        pacmanNode.Scale(0.5f);

        Node@ adjNode = pacmanNode.CreateChild("Pacman");
        adjNode.AddTag("Adj");
        adjNode.rotation = Quaternion(-90.0f, Vector3::UP);

        StaticModel@ pacmanObject = adjNode.CreateComponent("StaticModel");
        pacmanObject.model = cache.GetResource("Model", "Models/Models/Pacman.mdl");
        pacmanObject.material = cache.GetResource("Material", "Materials/Stone.xml");
        pacmanObject.castShadows = true;
        pacmanObject.materials[0] = cache.GetResource("Material", "Materials/Pacman.xml");
        pacmanObject.materials[1] = cache.GetResource("Material", "Materials/Black.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        RigidBody@ pacmanBody = pacmanNode.CreateComponent("RigidBody");
        pacmanBody.collisionLayer = COLLISION_PACMAN_LEVEL;
        pacmanBody.collisionMask = COLLISION_TERRAIN_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_FOOD_LEVEL | COLLISION_TREE_LEVEL | COLLISION_STATIC_OBJECTS;
        pacmanBody.mass = 1.0f;

        // Set zero angular factor so that physics doesn't turn the character on its own.
        // Instead we will control the character yaw manually
        pacmanBody.angularFactor = Vector3::ZERO;

        // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
        //pacmanBody.collisionEventMode = COLLISION_ALWAYS;

        // Set a capsule shape for collision
        CollisionShape@ shape = pacmanNode.CreateComponent("CollisionShape");
        shape.SetBox(Vector3(2, 2, 2));

        Node@ sleepParticleNode = pacmanNode.CreateChild("SleepParticleNode");
        ParticleEmitter@ sleepParticleEmitter = sleepParticleNode.CreateComponent("ParticleEmitter");
        sleepParticleEmitter.effect = cache.GetResource("ParticleEffect", "Particle/Dreaming.xml");
        sleepParticleEmitter.emitting = false;
        sleepParticleEmitter.viewMask = VIEW_MASK_STATIC_OBJECT;

        Node@ dullParticleNode = pacmanNode.CreateChild("DullParticleNode");
        dullParticleNode.position = Vector3(0, 2, 0);
        ParticleEmitter@ dullParticleEmitter = dullParticleNode.CreateComponent("ParticleEmitter");
        dullParticleEmitter.effect = cache.GetResource("ParticleEffect", "Particle/Dull.xml");
        dullParticleEmitter.emitting = false;
        dullParticleEmitter.viewMask = VIEW_MASK_STATIC_OBJECT;

        GameSounds::AddLoopedSoundToNode(pacmanNode, GameSounds::PACMAN);

        SinglePacman pacman;
        pacman.nextFoodCheck = 0.0f;
        pacman.node = pacmanNode;
        pacman.sleepParticleEmitter = sleepParticleEmitter;
        pacman.dullParticleEmitter = dullParticleEmitter;
        pacman.stage = STAGE_MOVE;
        pacman.sleepTime = 0.0f;
        pacmans.Push(pacman);
        return pacmanNode;
    }

    void Destroy()
    {
        for (uint i = 0; i < pacmans.length; i++) {
            pacmans[i].node.Remove();
        }
        pacmans.Clear();
    }

    void DestroyById(uint id)
    {
        for (uint i = 0; i < pacmans.length; i++) {
            if (pacmans[i].node.id == id) {
                pacmans[i].node.Remove();
                pacmans.Erase(i);
                return;
            }
        }
    }

    void Subscribe()
    {
        SubscribeToEvent("PacmanRemove", "Pacman::HandlePacmanRemove");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "pacman_remove";
        data["CONSOLE_COMMAND_EVENT"] = "PacmanRemove";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandlePacmanRemove(StringHash eventType, VariantMap& eventData)
    {
        Destroy();
    }

    void ChangePacmanState(SinglePacman& pacman, uint stage)
    {
        pacman.stage = stage;
        if (pacman.stage == STAGE_MOVE) {
            pacman.sleepParticleEmitter.emitting = false;
            pacman.dullParticleEmitter.emitting = false;
        } else if (pacman.stage == STAGE_SLEEP) {
            pacman.sleepParticleEmitter.emitting = true;
            pacman.dullParticleEmitter.emitting = false;
        } else if (pacman.stage == STAGE_DULL) {
            pacman.sleepParticleEmitter.emitting = false;
            pacman.dullParticleEmitter.emitting = true;
        }
    }

    void HitPacman(Node@ pacmanNode)
    {
        for (uint i = 0; i < pacmans.length; i++) {
            if (pacmans[i].node.id == pacmanNode.id) {
                ChangePacmanState(pacmans[i], STAGE_DULL);
                pacmans[i].sleepTime = 20.0f;
            }
        }
    }

    Node@ getNearestRaspberry(Vector3 position)
    {
        //return Vector3(-500.0f + Random(500), -500.0f + Random(500), -500.0f + Random(500));
        Array<Node@> apples = scene_.GetNodesWithTag("Raspberry");
        Node@ nearestApple;
        float nearestLength = 0;
        int nearestIndex = -1;
        apples.Push(Player::playerNode);
        
        for (uint i = 0; i < apples.length; i++) {
            Node@ apple = apples[i];
            Vector3 diff = Vector3(apple.worldPosition - position);
            float lengthSquared = diff.lengthSquared;
            if (apple.enabled == false) {
                continue;
            }
            if (nearestLength == 0 || nearestLength > lengthSquared) {
                nearestLength = lengthSquared;
                nearestIndex = i;
            }
        }

        if (nearestIndex >= 0) {
            nearestApple = apples[nearestIndex];
        }

        return nearestApple;
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        for (uint i = 0; i < pacmans.length; i++) {
            pacmans[i].lifetime += timeStep;
            if (pacmans[i].stage == STAGE_SLEEP || pacmans[i].stage == STAGE_DULL) {
                pacmans[i].sleepTime -= timeStep;
                if (pacmans[i].sleepTime <= 0.0f) {
                    ChangePacmanState(pacmans[i], STAGE_MOVE);
                }
                continue;
            }
            Node@ pacmanNode = pacmans[i].node;
            RigidBody@ pacmanBody = pacmans[i].node.GetComponent("RigidBody");
            pacmans[i].nextFoodCheck -= timeStep;
            if (pacmans[i].targetNode is null || pacmans[i].targetNode.enabled == false || pacmans[i].nextFoodCheck < 0.0) {
                pacmans[i].targetNode = getNearestRaspberry(pacmanNode.worldPosition);
                pacmans[i].nextFoodCheck = Random(10.0f);
            }
            Vector3 targetPosition = pacmans[i].targetNode.worldPosition;
            targetPosition.y = pacmanNode.position.y;
            pacmanNode.LookAt(targetPosition);

            Vector3 moveDir = pacmanNode.rotation * Vector3::FORWARD * PACMAN_MOVE_SPEED * timeStep;
            if (moveDir.lengthSquared > 0.0f) {
                moveDir.Normalize();
            }

            targetPosition = pacmans[i].targetNode.worldPosition;
            Vector3 diff = pacmanNode.worldPosition - targetPosition;
            if (diff.lengthSquared < 2.0f) {
                moveDir = Vector3::ZERO;
                if (pacmans[i].targetNode.HasTag("Raspberry")) {
                    pacmans[i].targetNode.SetDeepEnabled(false);
                }
                if (pacmans[i].targetNode.HasTag("Player")) {
                    SendEvent("PlayerHit");
                }
            }

            pacmanBody.ApplyImpulse(moveDir);

            Vector3 velocity = pacmanBody.linearVelocity;
            Vector3 planeVelocity(velocity.x, 0.0f, velocity.z);
            Vector3 brakeForce = -planeVelocity * 0.2f;
            pacmanBody.ApplyImpulse(brakeForce);
        }
    }
}