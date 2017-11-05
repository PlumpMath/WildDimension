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
		Node@ treeNode = scene_.CreateChild("AppleTree");
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
        object.materials[0] = cache.GetResource("Material", "Materials/Wood.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");

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
	    Tree tree;
	    tree.node = treeNode;
	    tree.lifetime = 10.0f + Random(5.0f);
	    tree.stage = 0;
	    tree.model = object;
	    CreateTreeApples(5 + RandomInt(10), tree);
	    trees.Push(tree);
		return treeNode;
	}

	void CreateTreeApples(int count, Tree@ parentTree)
	{
		for (uint i = 0; i < count; i++) {
			log.Info("Creating apple");
			Node@ apple = parentTree.node.CreateChild("Apple");
			Vector3 position = parentTree.node.position;
			position.x = -20.0f + Random(40.0f);
			position.z = -20.0f + Random(40.0f);
			position.y = NetworkHandler::terrain.GetHeight(position);
			apple.position = position;

		    StaticModel@ object = apple.CreateComponent("StaticModel");
	    	object.model = cache.GetResource("Model", "Models/Models/Apple.mdl");

	    	apple.SetScale(0.8f + Random(0.5f));
	        object.castShadows = true;
	        object.materials[0] = cache.GetResource("Material", "Materials/Apple.xml");
	        object.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
	        object.materials[2] = cache.GetResource("Material", "Materials/Wood.xml");

	        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
		    RigidBody@ body = apple.CreateComponent("RigidBody");
		    body.collisionLayer = 1;
		    body.mass = 0.1f;

		    // Set zero angular factor so that physics doesn't turn the character on its own.
		    // Instead we will control the character yaw manually
		    //body.angularFactor = Vector3::ZERO;

		    // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
		    body.collisionEventMode = COLLISION_ALWAYS;

		    CollisionShape@ shape = apple.CreateComponent("CollisionShape");
		    shape.SetConvexHull(object.model);

		    parentTree.apples.Push(apple);
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
				tree.lifetime = 10.0f + Random(5.0f);
				if (tree.stage > 1) {
					tree.stage = 0;
				}
				if (tree.stage == 0) {
					tree.model.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
				} else if (tree.stage == 1) {
					tree.model.materials[1] = cache.GetResource("Material", "Materials/TreeYellow.xml");
				}
			}
		}
	}
}