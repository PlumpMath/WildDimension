namespace Pacman {
	Array<Node@> pacmans;
	const float PACMAN_MOVE_SPEED = 0.6f;

	Node@ Create(Vector3 position)
	{
		log.Info("Creating pacman...");
		Node@ pacmanNode = scene_.CreateChild("PlayerNode");
		position.y = NetworkHandler::terrain.GetHeight(position) + 2;
		pacmanNode.position = position;

	    StaticModel@ pacmanObject = pacmanNode.CreateComponent("StaticModel");
        pacmanObject.model = cache.GetResource("Model", "Models/Sphere.mdl");
        pacmanObject.material = cache.GetResource("Material", "Materials/Stone.xml");
        pacmanObject.castShadows = true;

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

	void HandleUpdate(StringHash eventType, VariantMap& eventData)
	{
		for (uint i = 0; i < pacmans.length; i++) {
			Node@ pacmanNode = pacmans[i];
			RigidBody@ pacmanBody = pacmans[i].GetComponent("RigidBody");
			float timeStep = eventData["TimeStep"].GetFloat();

			Vector3 targetPosition = cameraNode.position;
			targetPosition.y = 0;
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