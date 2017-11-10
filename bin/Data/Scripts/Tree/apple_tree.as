namespace AppleTree {
    class Tree {
        Node@ node;
        float lifetime;
        StaticModel@ model;
        uint stage;
        Array<Node@> apples;
    }
    Array<Tree@> trees;

    Node@ Create(Vector3 position)
    {
        Node@ treeNode = scene_.CreateChild("Tree");
        treeNode.AddTag("Tree");
        treeNode.temporary = true;
        position.y = NetworkHandler::terrain.GetHeight(position);
        treeNode.position = position;

        Node@ adjNode = treeNode.CreateChild("Tree");
        adjNode.rotation = Quaternion(-90.0f, Vector3::UP);

        StaticModel@ object = adjNode.CreateComponent("StaticModel");
        if (RandomInt(2) == 1) {
            object.model = cache.GetResource("Model", "Models/Models/Apple_tree.mdl");
        } else {
            object.model = cache.GetResource("Model", "Models/Models/Apple_tree2.mdl");
        }
        treeNode.SetScale(0.8f + Random(0.5f));
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
        //shape.SetConvexHull(object.model);
        shape.SetBox(Vector3(1.3, 10.0, 1.3));

        Tree tree;
        tree.node = treeNode;
        tree.lifetime = 20.0f + Random(20.0f);
        tree.stage = 0;
        tree.model = object;
        CreateApples(1 + RandomInt(5), tree);
        trees.Push(tree);
        return treeNode;
    }

    void CreateApples(int count, Tree@ parentTree)
    {
        for (int i = 0; i < count; i++) {
            Node@ apple = scene_.CreateChild("Apple");
            apple.temporary = true;
            apple.AddTag("Apple");
            Vector3 position = parentTree.node.position;
            position.x += -30.0f + Random(60.0f);
            position.z += -30.0f + Random(60.0f);
            position.y = NetworkHandler::terrain.GetHeight(position) + 0.2f;
            apple.worldPosition = position;

            StaticModel@ object = apple.CreateComponent("StaticModel");
            object.model = cache.GetResource("Model", "Models/Models/Apple.mdl");

            apple.SetScale(0.8f + Random(0.5f));
            object.castShadows = true;
            object.materials[0] = cache.GetResource("Material", "Materials/Apple.xml");
            object.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
            object.materials[2] = cache.GetResource("Material", "Materials/Wood.xml");

            // Create rigidbody, and set non-zero mass so that the body becomes dynamic
            /*RigidBody@ body = apple.CreateComponent("RigidBody");
            body.collisionLayer = COLLISION_FOOD_LEVEL;
            body.collisionMask = COLLISION_TERRAIN_LEVEL | COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PLAYER_LEVEL | COLLISION_TREE_LEVEL | COLLISION_FOOD_LEVEL;
            body.mass = 0.1f;

            // Set zero angular factor so that physics doesn't turn the character on its own.
            // Instead we will control the character yaw manually
            //body.angularFactor = Vector3::ZERO;

            // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
            body.collisionEventMode = COLLISION_ALWAYS;

            CollisionShape@ shape = apple.CreateComponent("CollisionShape");
            //shape.SetConvexHull(object.model);
            shape.SetBox(Vector3(0.4, 0.4, 0.4));*/

            parentTree.apples.Push(apple);
        }
    }

    void ReenableApples(Tree tree)
    {
        for (uint i = 0; i < tree.apples.length; i++) {
            Node@ apple = tree.apples[i];
            if (apple.enabled == true) {
                continue;
            }
            Vector3 position = tree.node.position;
            position.x += -30.0f + Random(60.0f);
            position.z += -30.0f + Random(60.0f);
            position.y = NetworkHandler::terrain.GetHeight(position) + 0.2f;
            apple.worldPosition = position;
            apple.SetDeepEnabled(true);
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        for (uint i = 0; i < trees.length; i++) {
            Tree@ tree = trees[i];
            tree.lifetime -= timeStep;
            if (tree.lifetime < 0) {
                tree.stage++;
                tree.lifetime = 20.0f + Random(20.0f);
                if (tree.stage > 1) {
                    tree.stage = 0;
                }
                if (tree.stage == 0) {
                    tree.model.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
                    ReenableApples(tree);
                } else if (tree.stage == 1) {
                    tree.model.materials[1] = cache.GetResource("Material", "Materials/TreeYellow.xml");
                }
            }
        }
    }
}