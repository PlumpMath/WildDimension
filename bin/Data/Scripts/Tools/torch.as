namespace Torch {
    Node@ node;
    bool enabled = false;
    ParticleEmitter@ particleEmitter;

    void Create()
    {
        if (node !is null) {
            return;
        }
        node = ActiveTool::toolNode.CreateChild("Torch");
        node.AddTag("Torch");
        node.SetScale(0.2f);

        StaticModel@ object1 = node.CreateComponent("StaticModel");
        object1.model = cache.GetResource("Model", "Models/Models/Torch.mdl");
        object1.castShadows = true;
        object1.materials[0] = cache.GetResource("Material", "Materials/StoneFps.xml");
        object1.materials[1] = cache.GetResource("Material", "Materials/WoodFps.xml");

        Node@ lightNode = node.CreateChild("LightNode");
        lightNode.position = Vector3(0, 1.9, 0);
        lightNode.SetScale(1.0f);
        particleEmitter = lightNode.CreateComponent("ParticleEmitter");
        particleEmitter.effect = cache.GetResource("ParticleEffect", "Particle/Fire.xml");
        particleEmitter.emitting = true;
        particleEmitter.viewMask = VIEW_MASK_STATIC_OBJECT;

        Light@ light = lightNode.CreateComponent("Light");
        light.lightType = LIGHT_POINT;
        light.color = Color(0.88, 0.44, 0.33);
        light.range = 300.0f;
        light.enabled = true;
        light.castShadows = true;

        node.SetDeepEnabled(false);

        ActiveTool::AddTool(node, ActiveTool::TOOL_TORCH);
    }
}