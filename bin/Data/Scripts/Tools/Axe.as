namespace Axe {
	Node@ node;
	bool enabled = false;

	Node@ Create()
	{
		node = cameraNode.CreateChild("Axe");
		//position.y = NetworkHandler::terrain.GetHeight(position) + 1.0f;
		//node.position = position;

		Node@ adjNode = node.CreateChild("AdjNode");
    	adjNode.rotation = Quaternion(-100.0f, Vector3::UP);

    	Vector3 position = cameraNode.position;
		position += cameraNode.direction * 0.6f;
		position += node.rotation * Vector3::RIGHT * 0.3f;
		position += node.rotation * Vector3::UP * -0.1f;
		node.position = position;

	    StaticModel@ object = adjNode.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Axe.mdl");

    	node.SetScale(0.5f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Axe.xml");

        node.SetDeepEnabled(enabled);

		return node;
	}

	void Subscribe()
    {
        SubscribeToEvent("GetAxe", "Axe::HandlePickup");
    }

    void RegisterConsoleCommands()
	{
		VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "get_axe";
        data["CONSOLE_COMMAND_EVENT"] = "GetAxe";
		SendEvent("ConsoleCommandAdd", data);
	}

    void HandlePickup(StringHash eventType, VariantMap& eventData)
    {
    	Axe::enabled = true;
    	Axe::node.SetDeepEnabled(Axe::enabled);
    }
}