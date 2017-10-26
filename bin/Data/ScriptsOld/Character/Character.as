// Control bits we define
const uint CTRL_FORWARD = 1;
const uint CTRL_BACK = 2;
const uint CTRL_LEFT = 4;
const uint CTRL_RIGHT = 8;
const uint CTRL_JUMP = 16;

class Character : ScriptObject
{
    Vector3 position;
    AnimatedSprite2D@ spriterAnimatedSprite;
    AnimationSet2D@ spriterAnimationSet;
    ParticleEmitter2D@ particleEmitter;
    bool local = false;
    Node@ node;
    Node@ spriterNode;
    int spriterAnimationIndex = 0;
    Controls controls;
    Controls oldControls;
    RigidBody2D@ rigidBody;


    Character()
    {
        log.Info("Character created ");
    }

    void SetLocal(bool l)
    {
        local = l;
    }

    void SetNode(Node@ n)
    {
        node = n;
    }

    void Init()
    {
        CreateSprite();
    }

    void SetControls(Controls c)
    {
        controls = c;
    }

    void CreateSprite()
    {
        spriterAnimationSet = cache.GetResource("AnimationSet2D", "Urho2D/imp/imp.scml");
        if (spriterAnimationSet is null)
            return;

        spriterNode = node.CreateChild("SpriterAnimation", REPLICATED);
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

        //Node@ node  = spriterNode.CreateChild("RigidBody");
        //node.position = Vector3(Random(-0.1f, 0.1f), 5.0f + i * 0.4f, 0.0f);

        // Create rigid body
        rigidBody = node.CreateComponent("RigidBody2D");
        rigidBody.bodyType = BT_DYNAMIC;

        CollisionCircle2D@ box = node.CreateComponent("CollisionCircle2D");
            // Set size
        //box.size = Vector2(2.3f, 2.5f);
        box.radius = 1.2;
        box.friction = 0.7;
    }

    void Update(float timeStep)
    {
        const float MOVE_SPEED = 4.0f;
        if (controls.IsDown(CTRL_LEFT)) {
            spriterAnimatedSprite.SetFlip(false, false);
            //Vector3 position = node.position;
            //position.x -= MOVE_SPEED * timeStep;
            //node.position = position;
            //rigidBody.ApplyLinearImpulseToCenter(Vector2(10 * -timeStep, 0), true);
            rigidBody.linearVelocity = Vector2(-3, rigidBody.linearVelocity.y);
            if (spriterAnimatedSprite !is null) {
                spriterAnimatedSprite.SetAnimation(spriterAnimationSet.GetAnimation(2), LM_FORCE_LOOPED);
            }
            particleEmitter.emitting = true;
        } else if (controls.IsDown(CTRL_RIGHT)) {
            spriterAnimatedSprite.SetFlip(true, false);
            //rigidBody.ApplyLinearImpulseToCenter(Vector2(10 * timeStep, 0), true);
            rigidBody.linearVelocity = Vector2(3, rigidBody.linearVelocity.y);
            //Vector3 position = node.position;
            //position.x += MOVE_SPEED * timeStep;
            //node.position = position;
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

        if (controls.IsPressed(CTRL_JUMP, oldControls)) {
            if (rigidBody.linearVelocity.y < 1) {
                rigidBody.ApplyLinearImpulseToCenter(Vector2(0, 5), true);
            }
        }

        oldControls = controls;
    }
}