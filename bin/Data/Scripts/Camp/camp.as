namespace Camp {
    class Campfire {
        Node@ node;
        ParticleEmitter@ particleEmitter;
    };
    Array<Campfire> campfires;

    void Create(Vector3 position) {
        Campfire campfire;
        campfire.node = scene_.CreateChild("Snake");
        position.y = NetworkHandler::terrain.GetHeight(position);
        campfire.node.position = position;
        campfire.node.temporary = true;

        StaticModel@ object = campfire.node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Small_campfire.mdl");
        campfire.node.rotation = Quaternion(Vector3(0.0f, 1.0f, 0.0f), NetworkHandler::terrain.GetNormal(position));
        object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");
        for (int i = 1; i <= 9; i++) {
            object.materials[i] = cache.GetResource("Material", "Materials/Wood.xml");
        }
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Snake.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        RigidBody@ body = campfire.node.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_STATIC_OBJECTS;
        body.collisionMask = COLLISION_PACMAN_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_FOOD_LEVEL | COLLISION_TREE_LEVEL;
        body.mass = 0.0f;

        // Set a capsule shape for collision
        CollisionShape@ shape = campfire.node.CreateComponent("CollisionShape");
        //shape.SetConvexHull(pacmanObject.model);
        shape.SetBox(Vector3(1.0, 1.0, 1.0));

        campfire.particleEmitter = campfire.node.CreateComponent("ParticleEmitter");
        campfire.particleEmitter.effect = cache.GetResource("ParticleEffect", "Particle/Campfire.xml");
        campfire.particleEmitter.emitting = true;

        position.x += 5 + Random(10.0f);
        position.z += 5 + Random(10.0f);
        Pickable::Create(position, "Stem", "Models/Models/Stem.mdl");

        campfires.Push(campfire);
    }
}