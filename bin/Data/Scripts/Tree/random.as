namespace RandomTree {
    class Tree {
        Node@ node;
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
        int rand = RandomInt(3);
        if (rand == 0) {
            object.model = cache.GetResource("Model", "Models/Models/Big_tree.mdl");
        } else if (rand == 1) {
            object.model = cache.GetResource("Model", "Models/Models/Big_tree2.mdl");
        } else {
            object.model = cache.GetResource("Model", "Models/Models/Big_tree3.mdl");
        }
        treeNode.SetScale(1.0f + Random(0.5f));
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
        trees.Push(tree);
        return treeNode;
    }
}