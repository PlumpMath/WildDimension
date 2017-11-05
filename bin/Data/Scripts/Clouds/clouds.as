namespace Clouds {
	Array<Node@> clouds;

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

	    clouds.Push(cloudNode);
		return cloudNode;
	}
}