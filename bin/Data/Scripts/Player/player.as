namespace Player {
	const int CTRL_FORWARD = 1;
	const int CTRL_BACK = 2;
	const int CTRL_LEFT = 4;
	const int CTRL_RIGHT = 8;
	const int CTRL_JUMP = 16;

	Node@ playerNode;
	Controls playerControls;
	RigidBody@ playerBody;
    const float PLAYER_BRAKE_FORCE = 0.2f;

	Node@ CreatePlayer()
	{
		playerNode = scene_.CreateChild("PlayerNode");
		// Create rigidbody, and set non-zero mass so that the body becomes dynamic
	    playerBody = playerNode.CreateComponent("RigidBody");
	    playerBody.collisionLayer = 1;
        //playerBody.collisionMask = 2;
	    playerBody.mass = 1.0f;

	    // Set zero angular factor so that physics doesn't turn the character on its own.
	    // Instead we will control the character yaw manually
	    playerBody.angularFactor = Vector3::ZERO;

	    // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
	    playerBody.collisionEventMode = COLLISION_ALWAYS;

	    // Set a capsule shape for collision
	    CollisionShape@ shape = playerNode.CreateComponent("CollisionShape");
	    shape.SetCapsule(0.7f, 1.8f, Vector3(0.0f, 0.9f, 0.0f));
		return playerNode;
	}

	void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
	{
		if (playerNode is null) {
			return;
		}

		Controls oldControls = playerControls;
		float timeStep = eventData["TimeStep"].GetFloat();
		playerControls.Set(CTRL_FORWARD, input.keyDown[KEY_W]);
		playerControls.Set(CTRL_BACK, input.keyDown[KEY_S]);
		playerControls.Set(CTRL_LEFT, input.keyDown[KEY_A]);
		playerControls.Set(CTRL_RIGHT, input.keyDown[KEY_D]);
		playerControls.Set(CTRL_JUMP, input.keyDown[KEY_SPACE]);

		Vector3 moveDir(0.0f, 0.0f, 0.0f);

		if (playerControls.IsDown(CTRL_FORWARD)) {
            moveDir += Vector3::FORWARD;
            //log.Info("moving forward");
		}
        if (playerControls.IsDown(CTRL_BACK)) {
            moveDir += Vector3::BACK;
            //log.Info("moving backward");
        }
        if (playerControls.IsDown(CTRL_LEFT)) {
            moveDir += Vector3::LEFT;
            //log.Info("moving left");
        }
        if (playerControls.IsDown(CTRL_RIGHT)) {
            moveDir += Vector3::RIGHT;
            //log.Info("moving right");
        }

        bool jump = false;
        if (playerControls.IsPressed(CTRL_JUMP, oldControls)) {
        	jump = true;
        }

        Quaternion lookAt = Quaternion(pitch, yaw, 0.0f);

        //Ignore Y to allow moving only in X,Z directions
        Quaternion lookAt2 = Quaternion(0.0f, yaw, 0.0f);
        playerNode.rotation = lookAt;
        Quaternion rot = playerNode.rotation;

        Vector3 position = playerNode.position;

        Vector3 velocity = playerBody.linearVelocity;
        // Velocity on the XZ plane
        Vector3 planeVelocity(velocity.x, 0.0f, velocity.z);

        //position = lookAt * moveDir * timeStep * 30 + position;
        //playerNode.position = position;
         // Normalize move vector so that diagonal strafing is not faster
        if (moveDir.lengthSquared > 0.0f)
            moveDir.Normalize();

        playerBody.ApplyImpulse(lookAt2 * moveDir);

        Vector3 brakeForce = -planeVelocity * PLAYER_BRAKE_FORCE;
        playerBody.ApplyImpulse(brakeForce);

        if (jump) {
        	playerBody.ApplyImpulse(Vector3::UP * 5);
        }

        if (playerNode.position.y < NetworkHandler::terrain.GetHeight(playerNode.position)) {
            Vector3 playerPosition = playerNode.position;
            playerPosition.y = NetworkHandler::terrain.GetHeight(playerPosition);
            playerNode.position = playerPosition;
        }
	}

	void HandleKeyDown(StringHash eventType, VariantMap& eventData)
    {
    	int key = eventData["Key"].GetInt();
        if (key == KEY_W) {
        }
    }

    void HandleKeyUp(StringHash eventType, VariantMap& eventData)
    {
    	int key = eventData["Key"].GetInt();
        if (key == KEY_F1) {
        }
    }
}