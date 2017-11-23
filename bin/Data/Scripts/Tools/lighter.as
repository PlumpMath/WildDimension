namespace Lighter {
    Node@ node;
    bool enabled = false;
    ParticleEmitter@ particleEmitter;

    void Create()
    {
        if (node !is null) {
            return;
        }
        node = ActiveTool::toolNode.CreateChild("Lighter");
        node.AddTag("Lighter");
        node.SetScale(0.5f);

        Node@ firstRock = node.CreateChild("Rock1");
        firstRock.position = Vector3(-0.1, 0, 0);
        StaticModel@ object1 = firstRock.CreateComponent("StaticModel");
        object1.model = cache.GetResource("Model", "Models/Models/Small_rock1.mdl");
        object1.castShadows = true;
        object1.materials[0] = cache.GetResource("Material", "Materials/StoneFps.xml");

        Node@ secondRock = node.CreateChild("Rock2");
        secondRock.position = Vector3(0.1, 0, 0);
        StaticModel@ object2 = secondRock.CreateComponent("StaticModel");
        object2.model = cache.GetResource("Model", "Models/Models/Small_rock2.mdl");
        object2.castShadows = true;
        object2.materials[0] = cache.GetResource("Material", "Materials/StoneFps.xml");

        node.SetDeepEnabled(false);
        //ActiveTool::tools.Push(node);

        particleEmitter = node.CreateComponent("ParticleEmitter");
        particleEmitter.effect = cache.GetResource("ParticleEffect", "Particle/Burst.xml");
        particleEmitter.emitting = false;
        particleEmitter.viewMask = VIEW_MASK_STATIC_OBJECT;

        ActiveTool::AddTool(node, ActiveTool::TOOL_LIGHTER);
    }

    void StartAnimation()
    {
        particleEmitter.ResetEmissionTimer();
        particleEmitter.emitting = true;
        GameSounds::Play(GameSounds::STONE_HIT, 1.0);
    }
}