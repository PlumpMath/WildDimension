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

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Pyramid.mdl");

        node.SetScale(0.5f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/WoodFps.xml");

        node.SetDeepEnabled(false);
        //ActiveTool::tools.Push(node);
        ActiveTool::AddTool(node, ActiveTool::TOOL_TENT);
    }
}