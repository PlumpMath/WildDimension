namespace AppleTree {
	Array<Node@> trees;

	Node@ Create(Vector3 position)
	{
		Node@ treeNode = scene_.CreateChild("SnakeNode");
		position.y = NetworkHandler::terrain.GetHeight(position);
		treeNode.position = position;

		Node@ adjNode = treeNode.CreateChild("AdjNode");
    	adjNode.rotation = Quaternion(-90.0f, Vector3::UP);

	    StaticModel@ object = adjNode.CreateComponent("StaticModel");
	    if (RandomInt(2) == 1) {
        	object.model = cache.GetResource("Model", "Models/Models/Apple_tree.mdl");
    	} else {
    		object.model = cache.GetResource("Model", "Models/Models/Apple_tree2.mdl");
    	}
    	treeNode.SetScale(0.8f + Random(0.5f));
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/Snake.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
	    RigidBody@ body = treeNode.CreateComponent("RigidBody");
	    body.collisionLayer = 1;
	    body.mass = 0.0f;

	    // Set zero angular factor so that physics doesn't turn the character on its own.
	    // Instead we will control the character yaw manually
	    body.angularFactor = Vector3::ZERO;

	    // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
	    body.collisionEventMode = COLLISION_ALWAYS;

	    // Set a capsule shape for collision
	    CollisionShape@ shape = treeNode.CreateComponent("CollisionShape");
	    shape.SetConvexHull(object.model);
	    trees.Push(treeNode);
		return treeNode;
	}
}