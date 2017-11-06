namespace Clouds {
	const int RAINDROP_LIMIT = 10;
	class Cloud {
		Node@ node;
		float nextFall;
		Array<Node@> raindrops;
		bool active;
	};
	Array<Cloud> clouds;

	Node@ Create(Vector3 position)
	{
		Node@ cloudNode = scene_.CreateChild("SnakeNode");
		position.y = NetworkHandler::terrain.GetHeight(position) + 300.0f;
		cloudNode.position = position;

		Node@ adjNode = cloudNode.CreateChild("AdjNode");
    	//adjNode.rotation = Quaternion(-90.0f, Vector3::UP);

	    StaticModel@ object = adjNode.CreateComponent("StaticModel");
	    if (RandomInt(2) == 1) {
        	object.model = cache.GetResource("Model", "Models/Models/Cloud1.mdl");
    	} else {
    		object.model = cache.GetResource("Model", "Models/Models/Cloud2.mdl");
    	}
    	cloudNode.SetScale(4.0f + Random(2.0f));
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Cloud.xml");

	    Cloud cloud;
	    cloud.node = cloudNode;
	    cloud.nextFall = 1.0f + Random(1.0f);
	    cloud.active = false;
	    clouds.Push(cloud);
		return cloudNode;
	}

	void Destroy()
	{
		for (uint i = 0; i < clouds.length; i++) {
			Cloud@ cloud = clouds[i];
			for (uint j = 0; j < cloud.raindrops.length; j++) {
				cloud.raindrops[j].Remove();
			}
			cloud.node.Remove();
			cloud.raindrops.Clear();
		}
		clouds.Clear();
	}

	void Subscribe()
	{
		SubscribeToEvent("RainStart", "Clouds::HandleRainStart");
		SubscribeToEvent("RainStop", "Clouds::HandleRainStop");
		SubscribeToEvent("CloudsRemove", "Clouds::HandleCloudsRemove");
	}

	void RegisterConsoleCommands()
	{
		VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "rain_start";
        data["CONSOLE_COMMAND_EVENT"] = "RainStart";
		SendEvent("ConsoleCommandAdd", data);

		data["CONSOLE_COMMAND_NAME"] = "rain_stop";
        data["CONSOLE_COMMAND_EVENT"] = "RainStop";
		SendEvent("ConsoleCommandAdd", data);

		data["CONSOLE_COMMAND_NAME"] = "clouds_remove";
        data["CONSOLE_COMMAND_EVENT"] = "CloudsRemove";
		SendEvent("ConsoleCommandAdd", data);
	}

	void HandleCloudsRemove(StringHash eventType, VariantMap& eventData)
	{
		Destroy();
	}

	void HandleRainStart(StringHash eventType, VariantMap& eventData)
	{
		for (uint i = 0; i < clouds.length; i++) {
			Cloud@ cloud = clouds[i];
			cloud.active = true;
		}
	}

	void HandleRainStop(StringHash eventType, VariantMap& eventData)
	{
		for (uint i = 0; i < clouds.length; i++) {
			Cloud@ cloud = clouds[i];
			cloud.active = false;
			for (uint j = 0; j < cloud.raindrops.length; j++) {
				cloud.raindrops[j].Remove();
			}
			cloud.raindrops.Clear();

		}
	}

	void CreateRaindrop(Cloud@ parent)
	{
		if (parent.raindrops.length > RAINDROP_LIMIT) {
			parent.raindrops[0].Remove();
			parent.raindrops.Erase(0);
		}

		Node@ raindrop = scene_.CreateChild("Raindrop");
		raindrop.AddTag("Raindrop");
		Vector3 position = parent.node.position;
		position.x += -30.0f + Random(60.0f);
		position.z += -30.0f + Random(60.0f);
		raindrop.worldPosition = position;

	    StaticModel@ object = raindrop.CreateComponent("StaticModel");
    	object.model = cache.GetResource("Model", "Models/Box.mdl");

        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Stone.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
	    RigidBody@ body = raindrop.CreateComponent("RigidBody");
	    body.collisionLayer = 1;
	    body.mass = 10.0f;
	    body.linearDamping = 0.3f;

	    // Set zero angular factor so that physics doesn't turn the character on its own.
	    // Instead we will control the character yaw manually
	    //body.angularFactor = Vector3::ZERO;

	    // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
	    body.collisionEventMode = COLLISION_ALWAYS;

	    CollisionShape@ shape = raindrop.CreateComponent("CollisionShape");
	    shape.SetBox(Vector3::ONE);

	    parent.raindrops.Push(raindrop);
	}

	void HandleUpdate(StringHash eventType, VariantMap& eventData)
	{
		float timeStep = eventData["TimeStep"].GetFloat();
		for (uint i = 0; i < clouds.length; i++) {
			Cloud@ cloud = clouds[i];
			if (cloud.active == false) {
				continue;
			}
			cloud.nextFall -= timeStep;
			if (cloud.nextFall < 0) {
				CreateRaindrop(cloud);
				cloud.nextFall = 1.0f + Random(1.0f);
			}
		}
	}
}