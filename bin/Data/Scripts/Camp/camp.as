namespace Camp {
    const uint STATE_INACTIVE = 0;
    const uint STATE_SMOKING = 1;
    const uint STATE_BURNING = 2;

    class Campfire {
        Node@ node;
        ParticleEmitter@ smokeEmitter;
        ParticleEmitter@ fireEmitter;
        uint state;
        Light@ light;
    };
    Array<Campfire> campfires;

    void Create(Vector3 position) {
        Campfire campfire;

        campfire.state = STATE_INACTIVE;

        campfire.node = scene_.CreateChild("Campfire");
        campfire.node.AddTag("Campfire");
        position.y = NetworkHandler::terrain.GetHeight(position);
        campfire.node.position = position;
        campfire.node.temporary = true;
        campfire.node.rotation = Quaternion(Vector3(0.0f, 1.0f, 0.0f), NetworkHandler::terrain.GetNormal(position));

        StaticModel@ object = campfire.node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Small_campfire.mdl");
        campfire.node.rotation = Quaternion(Vector3(0.0f, 1.0f, 0.0f), NetworkHandler::terrain.GetNormal(position));
        object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[2] = cache.GetResource("Material", "Materials/Stone.xml");
        object.materials[3] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[4] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[5] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[6] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[7] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[8] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[9] = cache.GetResource("Material", "Materials/Wood.xml");

        object.castShadows = true;
        object.viewMask = VIEW_MASK_INTERACTABLE;

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        RigidBody@ body = campfire.node.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_STATIC_OBJECTS;
        body.collisionMask = COLLISION_PACMAN_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_FOOD_LEVEL | COLLISION_TREE_LEVEL;
        body.mass = 0.0f;

        // Set a capsule shape for collision
        CollisionShape@ shape = campfire.node.CreateComponent("CollisionShape");
        //shape.SetConvexHull(pacmanObject.model);
        shape.SetBox(Vector3(1.0, 1.0, 1.0));

        Node@ smokeNode = campfire.node.CreateChild("SmokeEmitterNode");
        smokeNode.position = Vector3(0, 0.8, 0);
        campfire.smokeEmitter = smokeNode.CreateComponent("ParticleEmitter");
        campfire.smokeEmitter.effect = cache.GetResource("ParticleEffect", "Particle/Campfire.xml");
        campfire.smokeEmitter.emitting = false;
        campfire.smokeEmitter.viewMask = VIEW_MASK_STATIC_OBJECT;

        Node@ childNode = campfire.node.CreateChild("FireEmitterNode");
        campfire.fireEmitter = childNode.CreateComponent("ParticleEmitter");
        campfire.fireEmitter.effect = cache.GetResource("ParticleEffect", "Particle/Fire.xml");
        campfire.fireEmitter.emitting = false;
        campfire.fireEmitter.viewMask = VIEW_MASK_STATIC_OBJECT;

        Node@ lightNode = campfire.node.CreateChild("LightNode");
        lightNode.position = Vector3(0, 0.5, 0);
        campfire.light = lightNode.CreateComponent("Light");
        campfire.light.lightType = LIGHT_POINT;
        campfire.light.color = Color(0.88, 0.44, 0.33);
        campfire.light.range = 300.0f;
        campfire.light.enabled = false;
        campfire.light.castShadows = true;

        campfires.Push(campfire);
    }

    void ChangeState(uint id)
    {
        for (uint i = 0; i < campfires.length; i++) {
            if (campfires[i].node.id == id) {
                campfires[i].state++;
                if (campfires[i].state > STATE_BURNING) {
                    campfires[i].state = STATE_INACTIVE;
                }
                if (campfires[i].state == STATE_INACTIVE) {
                    campfires[i].smokeEmitter.emitting = false;
                    campfires[i].fireEmitter.emitting = false;
                    campfires[i].light.enabled = false;
                } else if (campfires[i].state == STATE_SMOKING) {
                    campfires[i].smokeEmitter.emitting = true;
                    campfires[i].fireEmitter.emitting = false;
                    campfires[i].light.enabled = false;
                } else if (campfires[i].state == STATE_BURNING) {
                    campfires[i].smokeEmitter.emitting = true;
                    campfires[i].fireEmitter.emitting = true;
                    campfires[i].light.enabled = true;
                }
            }
        }
    }
}