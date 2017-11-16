namespace Axe {
    Node@ node;
    bool enabled = false;

    void Create()
    {
        if (node !is null) {
            return;
        }
        node = ActiveTool::toolNode.CreateChild("Axe");
        node.AddTag("Axe");

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Axe.001.mdl");

        node.SetScale(0.5f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/StoneFps.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/WoodFps.xml");

        node.SetDeepEnabled(false);
        //ActiveTool::tools.Push(node);
        ActiveTool::AddTool(node, ActiveTool::TOOL_AXE);
    }
}