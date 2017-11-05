namespace Pacman {
	Array<Node@> pacmans;
	const float PACMAN_MOVE_SPEED = 0.05f;

	Node@ Create(Vector3 position)
	{
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

	Node@ getNearestRaspberry(Vector3 position)
	{
		//return Vector3(-500.0f + Random(500), -500.0f + Random(500), -500.0f + Random(500));
		Array<Node@> apples = scene_.GetNodesWithTag("Raspberry");
		Node@ nearestApple;
		int nearestLength = 0;
		int nearestIndex = -1;
		apples.Push(cameraNode);
		
		for (uint i = 0; i < apples.length; i++) {
			Node@ apple = apples[i];
			Vector3 diff = Vector3(apple.worldPosition - position);
			float lengthSquared = diff.lengthSquared;
			if (apple.enabled == false) {
				continue;
			}
			if (nearestLength == 0 || nearestLength > lengthSquared) {
				nearestLength = lengthSquared;
				nearestIndex = i;
			}
		}

		if (nearestIndex >= 0) {
			nearestApple = apples[nearestIndex];
		}

		return nearestApple;
	}

	void HandleUpdate(StringHash eventType, VariantMap& eventData)
	{
		float timeStep = eventData["TimeStep"].GetFloat();
		for (uint i = 0; i < pacmans.length; i++) {
			Node@ pacmanNode = pacmans[i];
			RigidBody@ pacmanBody = pacmans[i].GetComponent("RigidBody");

			Node@ raspberryNode = getNearestRaspberry(pacmanNode.worldPosition);
			Vector3 targetPosition = raspberryNode.worldPosition;
			targetPosition.y = pacmanNode.position.y;
			pacmanNode.LookAt(targetPosition);

			Vector3 moveDir = pacmanNode.rotation * Vector3::FORWARD * PACMAN_MOVE_SPEED;
			if (moveDir.lengthSquared > 0.0f) {
	            moveDir.Normalize();
			}

			Vector3 diff = pacmanNode.worldPosition - targetPosition;
			if (diff.lengthSquared < 2.0f) {
				moveDir = Vector3::ZERO;
				if (raspberryNode.HasTag("Raspberry")) {
					raspberryNode.SetDeepEnabled(false);
				}
			}

			pacmanBody.ApplyImpulse(moveDir);

			Vector3 velocity = pacmanBody.linearVelocity;
			Vector3 planeVelocity(velocity.x, 0.0f, velocity.z);
			Vector3 brakeForce = -planeVelocity * 0.2f;
	        pacmanBody.ApplyImpulse(brakeForce);
		}
	}
}