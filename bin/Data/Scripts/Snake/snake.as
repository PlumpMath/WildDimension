namespace Snake {
	class SnakeBody {
		Array<Node@> body;
		Vector3 targetPosition;
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
	    snakeBody.targetPosition = getRandomPos();
	    snakeBody.lastTurn = 0.0f;
	    for (uint i = 0; i < 30; i++) {
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

	Vector3 getRandomPos()
	{
		return Vector3(-500.0f + Random(500), -500.0f + Random(500), -500.0f + Random(500));
	}

	void HandleUpdate(StringHash eventType, VariantMap& eventData)
	{
		float timeStep = eventData["TimeStep"].GetFloat();
		for (uint i = 0; i < snakes.length; i++) {
			SnakeBody@ snakeBody = snakes[i];
			if (time.elapsedTime % 5 < 1.0f && snakeBody.lastTurn > 0.5f + Random(1.0f)) {
				snakeBody.targetPosition = getRandomPos();
				snakeBody.lastTurn = 0.0f;
			} else {
				snakeBody.lastTurn += timeStep;
			}
			MoveBodyPart(0, snakeBody.body[0], snakeBody.targetPosition, timeStep);
			for (uint j = 1; j < snakeBody.body.length; j++) {
				MoveBodyPart(j, snakeBody.body[j], snakeBody.body[j-1].position, timeStep);
			}
		}
	}

	void MoveBodyPart(int ind, Node@ node, Vector3 targetPosition, float timeStep)
	{
		RigidBody@ rigidBody = node.GetComponent("RigidBody");

		targetPosition.y = node.position.y;
		node.LookAt(targetPosition);

		Vector3 moveDir = node.rotation * Vector3::FORWARD * SNAKE_MOVE_SPEED;
		if (moveDir.lengthSquared > 0.0f) {
            moveDir.Normalize();
		}

		Vector3 diff = node.position - targetPosition;
		if (diff.lengthSquared < 2.0f) {
			moveDir = Vector3::ZERO;
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