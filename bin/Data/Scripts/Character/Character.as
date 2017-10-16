class Character : ScriptObject
{
    Vector3 position;
    AnimatedSprite2D@ spriterAnimatedSprite;
    AnimationSet2D@ spriterAnimationSet;
    ParticleEmitter2D@ particleEmitter;

    Character()
    {
        log.Info("Character created");
        CreateSprite();
    }

    void CreateSprite()
    {
        spriterAnimationSet = cache.GetResource("AnimationSet2D", "Urho2D/imp/imp.scml");
        if (spriterAnimationSet is null)
            return;

        spriterNode = scene_.CreateChild("SpriterAnimation", REPLICATED);
        spriterAnimatedSprite = spriterNode.CreateComponent("AnimatedSprite2D", REPLICATED);
        spriterAnimatedSprite.animationSet = spriterAnimationSet;
        spriterAnimatedSprite.SetAnimation(spriterAnimationSet.GetAnimation(spriterAnimationIndex), LM_FORCE_LOOPED);

        ParticleEffect2D@ particleEffect = cache.GetResource("ParticleEffect2D", "Urho2D/sun.pex");
        if (particleEffect is null)
            return;

        Node@ particleNode = spriterNode.CreateChild("ParticleEmitter2D");
        particleEmitter = particleNode.CreateComponent("ParticleEmitter2D");
        particleEmitter.effect = particleEffect;

        ParticleEffect2D@ greenSpiralEffect = cache.GetResource("ParticleEffect2D", "Urho2D/greenspiral.pex");
        if (greenSpiralEffect is null)
            return;

        Node@ node  = spriterNode.CreateChild("RigidBody");
        //node.position = Vector3(Random(-0.1f, 0.1f), 5.0f + i * 0.4f, 0.0f);

        // Create rigid body
        RigidBody2D@ body = node.CreateComponent("RigidBody2D");
        body.bodyType = BT_STATIC;

        CollisionBox2D@ box = node.CreateComponent("CollisionBox2D");
            // Set size
        box.size = Vector2(2.3f, 2.5f);
    }

    void Update(float timeStep)
    {
        const float MOVE_SPEED = 4.0f;
        if (input.keyDown[KEY_A]) {
            spriterAnimatedSprite.SetFlip(false, false);
            Vector3 position = spriterNode.position;
            position.x -= MOVE_SPEED * timeStep;
            spriterNode.position = position;
            if (spriterAnimatedSprite !is null) {
                spriterAnimatedSprite.SetAnimation(spriterAnimationSet.GetAnimation(2), LM_FORCE_LOOPED);
            }
            particleEmitter.emitting = true;
        } else if (input.keyDown[KEY_D]) {
            spriterAnimatedSprite.SetFlip(true, false);
            Vector3 position = spriterNode.position;
            position.x += MOVE_SPEED * timeStep;
            spriterNode.position = position;
            if (spriterAnimatedSprite !is null) {
                spriterAnimatedSprite.SetAnimation(spriterAnimationSet.GetAnimation(2), LM_FORCE_LOOPED);
            }
            particleEmitter.emitting = true;
        } else {
            particleEmitter.emitting = false;
            if (spriterAnimatedSprite !is null) {
                spriterAnimatedSprite.SetAnimation(spriterAnimationSet.GetAnimation(0), LM_FORCE_LOOPED);
            }
        }
    }
}