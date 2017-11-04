namespace Pacman {
	Array<Node@> pacmans;
	const float PACMAN_MOVE_SPEED = 0.05f;

	Node@ Create(Vector3 position)
	{
		log.Info("Creating pacman...");
		Node@ pacmanNode = scene_.CreateChild("PlayerNode");
		position.y = NetworkHandler::terrain.GetHeight(position) + 2;
		pacmanNode.position = position;
		pacmanNode.Scale(0.5f);

		Node@ adjNode = pacmanNode.CreateChild("AdjNode");
    	adjNode.rotation = Quaternion(-90.0f, Vector3::UP);

	    StaticModel@ pacmanObject = adjNode.CreateComponent("StaticModel");
        pacmanObject.model = cache.GetResource("Model", "Models/Models/Pacman.mdl");
        pacmanObject.material = cache.GetResource("Material", "Materials/Stone.xml");
        pacmanObject.castShadows = true;
        pacmanObject.materials[0] = cache.GetResource("Material", "Materials/Pacman.xml");
        pacmanObject.materials[1] = cache.GetResource("Material", "Materials/Black.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
	    RigidBody@ pacmanBody = pacmanNode.CreateComponent("RigidBody");
	    pacmanBody.collisionLayer = 1;
	    pacmanBody.mass = 1.0f;

	    // Set zero angular factor so that physics doesn't turn the character on its own.
	    // Instead we will control the character yaw manually
	    pacmanBody.angularFactor = Vector3::ZERO;

	    // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
	    pacmanBody.collisionEventMode = COLLISION_ALWAYS;

	    // Set a capsule shape for collision
	    CollisionShape@ shape = pacmanNode.CreateComponent("CollisionShape");
	    shape.SetConvexHull(pacmanObject.model);

	    pacmans.Push(pacmanNode);
		return pacmanNode;
	}

	Vector3 getRandomPos(Node@ node, float timeStep)
	{
		Vector3 pos = node.position;
		Vector3 randomPos = pos;
		randomPos = Quaternion(90.0f, Vector3::UP) * randomPos * 10;
		return pos + randomPos;
	}

	void HandleUpdate(StringHash eventType, VariantMap& eventData)
	{
		float timeStep = eventData["TimeStep"].GetFloat();
		for (uint i = 0; i < pacmans.length; i++) {
			Node@ pacmanNode = pacmans[i];
			RigidBody@ pacmanBody = pacmans[i].GetComponent("RigidBody");

			Vector3 targetPosition = getRandomPos(pacmanNode, timeStep);
			targetPosition.y = pacmanNode.position.y;
			pacmanNode.LookAt(targetPosition);

			Vector3 moveDir = pacmanNode.rotation * Vector3::FORWARD * PACMAN_MOVE_SPEED;
			if (moveDir.lengthSquared > 0.0f) {
	            moveDir.Normalize();
			}

			pacmanBody.ApplyImpulse(moveDir);

			Vector3 velocity = pacmanBody.linearVelocity;
			Vector3 planeVelocity(velocity.x, 0.0f, velocity.z);
			Vector3 brakeForce = -planeVelocity * 0.2f;
	        pacmanBody.ApplyImpulse(brakeForce);
		}
	}
}