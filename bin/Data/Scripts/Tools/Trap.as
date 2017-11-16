namespace Trap {
    Node@ node;
    bool enabled = false;

    void Create()
    {
        if (node !is null) {
            return;
        }
        node = ActiveTool::toolNode.CreateChild("Trap");
        node.AddTag("Trap");

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Box.mdl");

        node.SetScale(0.2f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/StoneFps.xml");

        node.SetDeepEnabled(false);
        //ActiveTool::tools.Push(node);
        ActiveTool::AddTool(node, ActiveTool::TOOL_TRAP);
    }
}