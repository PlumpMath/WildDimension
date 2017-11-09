namespace Camp {
    class Campfire {
        Node@ node;
        ParticleEmitter@ particleEmitter;
    };
    Array<Campfire> campfires;

    void Create(Vector3 position) {
        Campfire campfire;
        campfire.node = scene_.CreateChild("Snake");
        position.y = NetworkHandler::terrain.GetHeight(position) + 0.0f;
        campfire.node.position = position;
        campfire.node.temporary = true;

        StaticModel@ object = campfire.node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Sphere.mdl");
        object.material = cache.GetResource("Material", "Materials/Stone.xml");
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

        campfires.Push(campfire);
    }
}