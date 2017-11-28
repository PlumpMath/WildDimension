namespace AppleTree {
    class Tree {
        Node@ node;
        float lifetime;
        StaticModel@ model;
        uint stage;
    }

    uint STAGE_SUMMER = 0;
    uint STAGE_AUTUMN = 1;
    Array<Tree@> trees;

    const float TREE_MIN_SEASON_TIME = 20.0f;

    Node@ Create(Vector3 position)
    {
        position.y = NetworkHandler::terrain.GetHeight(position);
        if (position.y < 100) {
            return null;
        }
        Node@ treeNode = scene_.CreateChild("Tree");
        treeNode.AddTag("Tree");
        treeNode.temporary = true;
        treeNode.position = position;

        StaticModel@ object = treeNode.CreateComponent("StaticModel");
        if (RandomInt(2) == 1) {
            object.model = cache.GetResource("Model", "Models/Models/Apple_tree.mdl");
        } else {
            object.model = cache.GetResource("Model", "Models/Models/Apple_tree2.mdl");
        }
        treeNode.SetScale(2.0f + Random(0.8f));
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");

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
        //shape.SetBox(Vector3(1.3, 10.0, 1.3));

        Tree tree;
        tree.node = treeNode;
        tree.lifetime = TREE_MIN_SEASON_TIME + Random(TREE_MIN_SEASON_TIME);
        tree.stage = STAGE_SUMMER;
        tree.model = object;
        Spawn::Create(treeNode.worldPosition, 5, 100, 100, 1 + RandomInt(1), 10, Spawn::SPAWN_UNIT_APPLE);
        trees.Push(tree);
        return treeNode;
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        for (uint i = 0; i < trees.length; i++) {
            Tree@ tree = trees[i];
            tree.lifetime -= timeStep;
            if (tree.lifetime < 0) {
                tree.stage++;
                if (tree.stage > STAGE_AUTUMN) {
                    tree.stage = STAGE_SUMMER;
                }
                tree.lifetime = TREE_MIN_SEASON_TIME + Random(TREE_MIN_SEASON_TIME);
                if (tree.stage == STAGE_SUMMER) {
                    tree.model.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
                } else if (tree.stage == STAGE_AUTUMN) {
                    tree.model.materials[1] = cache.GetResource("Material", "Materials/TreeYellow.xml");
                }
            }
        }
    }
}