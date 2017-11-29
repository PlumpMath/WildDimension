namespace Tent {
    Node@ node;
    bool enabled = false;

    void Create()
    {
        if (node !is null) {
            return;
        }
        node = ActiveTool::toolNode.CreateChild("Tent");
        node.AddTag("Tent");

        Node@ adjTentNode = node.CreateChild("AdjNode");
        adjTentNode.rotation = Quaternion(-120.0f, Vector3::UP);

        StaticModel@ object = adjTentNode.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Tent.mdl");

        node.SetScale(0.05f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/WoodFps.xml");

        node.SetDeepEnabled(false);
        //ActiveTool::tools.Push(node);
        ActiveTool::AddTool(node, ActiveTool::TOOL_TENT);
    }
}