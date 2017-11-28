namespace RaspberryBush {
    class Bush {
        Node@ node;
        float lifetime;
        StaticModel@ model;
        uint stage;
        Array<Node@> berries;
    }
    Array<Bush@> trees;

    uint STAGE_SUMMER = 0;
    uint STAGE_AUTUMN = 1;

    Node@ Create(Vector3 position)
    {
        position.y = NetworkHandler::terrain.GetHeight(position);
        if (position.y < 100) {
            return null;
        }
        Node@ treeNode = scene_.CreateChild("Bush");
        treeNode.temporary = true;
        treeNode.AddTag("Bush");
        treeNode.position = position;

        StaticModel@ object = treeNode.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Raspberry_bush.mdl");
        treeNode.SetScale(1.8f + Random(0.5f));
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/TreeGreen.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        RigidBody@ body = treeNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_TREE_LEVEL;
        body.collisionMask = COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_FOOD_LEVEL;
        body.mass = 0.0f;

        // Set zero angular factor so that physics doesn't turn the character on its own.
        // Instead we will control the character yaw manually
        body.angularFactor = Vector3::ZERO;

        // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
        body.collisionEventMode = COLLISION_ALWAYS;

        // Set a capsule shape for collision
        CollisionShape@ shape = treeNode.CreateComponent("CollisionShape");
        shape.SetTriangleMesh(object.model);
        Bush tree;
        tree.node = treeNode;
        tree.lifetime = 20.0f + Random(20.0f);
        tree.stage = STAGE_SUMMER;
        tree.model = object;
        Spawn::Create(treeNode.worldPosition, 5, 100, 100, 1 + RandomInt(1), 10, Spawn::SPAWN_UNIT_RASPBERRY);
        trees.Push(tree);
        return treeNode;
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        for (uint i = 0; i < trees.length; i++) {
            Bush@ tree = trees[i];
            tree.lifetime -= timeStep;
            if (tree.lifetime < 0) {
                tree.stage++;
                tree.lifetime = 20.0f + Random(20.0f);
                if (tree.stage > STAGE_AUTUMN) {
                    tree.stage = STAGE_SUMMER;
                }
                if (tree.stage == STAGE_SUMMER) {
                    tree.model.materials[0] = cache.GetResource("Material", "Materials/TreeGreen.xml");
                } else if (tree.stage == STAGE_AUTUMN) {
                    tree.model.materials[0] = cache.GetResource("Material", "Materials/TreeYellow.xml");
                }
            }
        }
    }
}