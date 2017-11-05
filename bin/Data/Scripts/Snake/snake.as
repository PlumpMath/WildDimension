namespace Snake {
	class SnakeBody {
		Array<Node@> body;
		Node@ targetNode;
		float lastTurn;
	};
	const float SNAKE_MOVE_SPEED = 0.05f;
	Array<SnakeBody> snakes;
	uint collisionMask = 2;
	uint collisionLayer = 1;

	Node@ Create(Vector3 position)
	{
		Node@ snakeNode = scene_.CreateChild("SnakeNode");
		position.y = NetworkHandler::terrain.GetHeight(position) + 2;
		snakeNode.position = position;
		//snakeNode.Scale(0.5f);

		Node@ adjNode = snakeNode.CreateChild("AdjNode");
    	adjNode.rotation = Quaternion(-90.0f, Vector3::UP);

	    StaticModel@ pacmanObject = adjNode.CreateComponent("StaticModel");
        pacmanObject.model = cache.GetResource("Model", "Models/Models/Snake_head.mdl");
        pacmanObject.material = cache.GetResource("Material", "Materials/Stone.xml");
        pacmanObject.castShadows = true;
        pacmanObject.materials[0] = cache.GetResource("Material", "Materials/Snake.xml");
        //pacmanObject.materials[1] = cache.GetResource("Material", "Materials/Black.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
	    RigidBody@ pacmanBody = snakeNode.CreateComponent("RigidBody");
	    pacmanBody.collisionLayer = collisionLayer;
	    //pacmanBody.collisionMask = collisionMask;
	    pacmanBody.mass = 2.0f;

	    // Set zero angular factor so that physics doesn't turn the character on its own.
	    // Instead we will control the character yaw manually
	    pacmanBody.angularFactor = Vector3::ZERO;

	    // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
	    pacmanBody.collisionEventMode = COLLISION_ALWAYS;

	    // Set a capsule shape for collision
	    CollisionShape@ shape = snakeNode.CreateComponent("CollisionShape");
	    shape.SetConvexHull(pacmanObject.model);

	    SnakeBody snakeBody;
	    snakeBody.body.Push(snakeNode);
	    snakeBody.targetNode = getNearestApple(snakeBody.body[0].worldPosition);
	    snakeBody.lastTurn = 0.0f;
	    for (uint i = 0; i < 3; i++) {
	    	snakeBody.body.Push(createSnakeBodyPart(snakeBody));
	    }
	    snakes.Push(snakeBody);

		return snakeNode;
	}

	Node@ createSnakeBodyPart(SnakeBody@ parent)
	{
		Node@ lastNode = parent.body[parent.body.length - 1];
		Vector3 position = lastNode.position;
		position -= lastNode.direction.Normalized() * 0.9f;
		Node@ snakeNode = scene_.CreateChild("SnakeBody");
		snakeNode.LookAt(parent.body[0].position);
		position.y = NetworkHandler::terrain.GetHeight(position) + 2;
		snakeNode.worldPosition = position;
		//snakeNode.Scale(1.0f);

		Node@ adjNode = snakeNode.CreateChild("AdjNode");
    	adjNode.rotation = Quaternion(-90.0f, Vector3::UP);

	    StaticModel@ pacmanObject = adjNode.CreateComponent("StaticModel");
        pacmanObject.model = cache.GetResource("Model", "Models/Models/Snake_body.mdl");
        pacmanObject.material = cache.GetResource("Material", "Materials/Stone.xml");
        pacmanObject.castShadows = true;
        pacmanObject.materials[0] = cache.GetResource("Material", "Materials/Snake.xml");
        //pacmanObject.materials[1] = cache.GetResource("Material", "Materials/Black.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
	    RigidBody@ pacmanBody = snakeNode.CreateComponent("RigidBody");
	    pacmanBody.collisionLayer = collisionLayer;
	    //pacmanBody.collisionMask = collisionMask;
	    pacmanBody.mass = 1.0f;

	    // Set zero angular factor so that physics doesn't turn the character on its own.
	    // Instead we will control the character yaw manually
	    pacmanBody.angularFactor = Vector3::ZERO;

	    // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
	    pacmanBody.collisionEventMode = COLLISION_ALWAYS;

	    // Set a capsule shape for collision
	    CollisionShape@ shape = snakeNode.CreateComponent("CollisionShape");
	    shape.SetConvexHull(pacmanObject.model);
	    
		return snakeNode;
	}

	Node@ getNearestApple(Vector3 position)
	{
		//return Vector3(-500.0f + Random(500), -500.0f + Random(500), -500.0f + Random(500));
		Array<Node@> apples = scene_.GetNodesWithTag("Apple");
		Node@ nearestApple;
		int nearestLength = 0;
		int nearestIndex = -1;
		
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

		//If no apples are near, chase the player
		if (nearestApple is null) {
			nearestApple = cameraNode;
		}

		return nearestApple;
	}

	void HandleUpdate(StringHash eventType, VariantMap& eventData)
	{
		float timeStep = eventData["TimeStep"].GetFloat();
		for (uint i = 0; i < snakes.length; i++) {
			SnakeBody@ snakeBody = snakes[i];
			//if (snakeBody.targetNode.enabled == false) {
				snakeBody.targetNode = getNearestApple(snakeBody.body[0].worldPosition);
			//}
			/*if (time.elapsedTime % 5 < 1.0f && snakeBody.lastTurn > 0.5f + Random(1.0f)) {
				snakeBody.targetNode = getNearestApple(snakeBody.body[0].position);
				snakeBody.lastTurn = 0.0f;
			} else {
				snakeBody.lastTurn += timeStep;
			}*/
			MoveBodyPart(i, 0, snakeBody.body[0], snakeBody.targetNode, timeStep);
			for (uint j = 1; j < snakeBody.body.length; j++) {
				MoveBodyPart(i, j, snakeBody.body[j], snakeBody.body[j-1], timeStep);
			}
		}
	}

	void MoveBodyPart(int snakeIndex, int ind, Node@ node, Node@ targetNode, float timeStep)
	{
		Vector3 targetPosition = targetNode.worldPosition;
		RigidBody@ rigidBody = node.GetComponent("RigidBody");

		targetPosition.y = node.position.y;
		node.direction = targetPosition - node.position;

		Vector3 moveDir = node.rotation * Vector3::FORWARD * SNAKE_MOVE_SPEED;
		if (moveDir.lengthSquared > 0.0f) {
            moveDir.Normalize();
		}

		Vector3 diff = node.position - targetPosition;
		if (diff.lengthSquared < 2.0f) {
			moveDir = Vector3::ZERO;
			if (ind == 0) {
				if (targetNode.HasTag("Apple")) {
					targetNode.SetDeepEnabled(false);
					snakes[snakeIndex].body.Push(createSnakeBodyPart(snakes[snakeIndex]));
				}
			}
		} else if (ind > 0 && diff.lengthSquared > 3) {
			moveDir *= 2;
		}
		if (ind == 0) {
			node.Pitch(timeStep * 10);
		}

		rigidBody.ApplyImpulse(moveDir);

		Vector3 velocity = rigidBody.linearVelocity;
		Vector3 planeVelocity(velocity.x, 0.0f, velocity.z);
		Vector3 brakeForce = -planeVelocity * 0.2f;
        rigidBody.ApplyImpulse(brakeForce);
	}
}