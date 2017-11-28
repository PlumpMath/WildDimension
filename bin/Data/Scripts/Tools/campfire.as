namespace Campfire {
    Node@ node;
    bool enabled = false;

    void Create()
    {
        if (node !is null) {
            return;
        }
        node = ActiveTool::toolNode.CreateChild("Campfire");
        node.AddTag("Campfire");

        StaticModel@ object = node.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Small_campfire.mdl");

        node.SetScale(0.2f);
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[1] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[2] = cache.GetResource("Material", "Materials/StoneFps.xml");
        object.materials[3] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[4] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[5] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[6] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[7] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[8] = cache.GetResource("Material", "Materials/WoodFps.xml");
        object.materials[9] = cache.GetResource("Material", "Materials/WoodFps.xml");

        node.SetDeepEnabled(false);
        //ActiveTool::tools.Push(node);
        ActiveTool::AddTool(node, ActiveTool::TOOL_CAMPFIRE);
    }
}