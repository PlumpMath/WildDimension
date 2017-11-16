namespace EnvObjects {
    Array<Node@> objects;

    Node@ Create(Vector3 position, String model)
    {
        Node@ node = scene_.CreateChild("Rock");
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
        //shape.SetConvexHull(object.model);
        shape.SetTriangleMesh(object.model);

        objects.Push(node);
        return node;
    }
}