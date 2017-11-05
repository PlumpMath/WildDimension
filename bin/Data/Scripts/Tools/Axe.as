namespace Axe {
	Node@ node;

	Node@ Create()
	{
		Node@ node = cameraNode.CreateChild("SnakeNode");
		//position.y = NetworkHandler::terrain.GetHeight(position) + 1.0f;
		//node.position = position;

		Node@ adjNode = node.CreateChild("AdjNode");
    	adjNode.rotation = Quaternion(-110.0f, Vector3::UP);

    	Vector3 position = cameraNode.position;
		position += cameraNode.direction * 0.8f;
		position += node.rotation * Vector3::RIGHT * 0.5f;
		node.position = position;

	    StaticModel@ object = adjNode.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Axe.mdl");

    	node.SetScale(0.5f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/Axe.xml");

		return node;
	}
}