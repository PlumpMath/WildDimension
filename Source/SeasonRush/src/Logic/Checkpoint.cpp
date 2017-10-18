#include <Urho3D/Urho3DAll.h>
#include "Logic/Checkpoint.h"

using namespace Urho3D;

Checkpoint::Checkpoint(Context* context) :
Urho3D::LogicComponent(context),
_scale(1.0f),
_last(false),
_fireworkTimer(0.0f)
{
	SetUpdateEventMask(USE_FIXEDUPDATE | USE_POSTUPDATE);
}


Checkpoint::~Checkpoint()
{
}


void Checkpoint::RegisterObject(Context* context)
{
	context->RegisterFactory<Checkpoint>();
}

void Checkpoint::create(Vector3 pos)
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();

	Node* node = GetNode();

    NetworkPriority* np = node->CreateComponent<NetworkPriority>();
    np->SetDistanceFactor(1.0f);
    np->SetBasePriority(50);

	StaticModel* hullObject = node->CreateComponent<StaticModel>();
	Model* model = cache->GetResource<Model>("Models/christmas/checkpoint.mdl");
	hullObject->SetModel(model);
    hullObject->SetCastShadows(true);
	hullObject->SetMaterial(0, cache->GetResource<Material>("Materials/Checkpoint.xml"));
    hullObject->SetMaterial(1, cache->GetResource<Material>("Materials/ChristmasLights1.xml"));
    hullObject->SetMaterial(2, cache->GetResource<Material>("Materials/ChristmasLights2.xml"));

	{
		Material* lightMaterial = cache->GetResource<Material>("Materials/ChristmasLights1.xml");
		// Apply shader parameter animation to material
		SharedPtr<ValueAnimation> specColorAnimation(new ValueAnimation(context_));
		specColorAnimation->SetKeyFrame(0.0f, Color(1.0f, 0.0f, 0.0f, 1.0f));
		specColorAnimation->SetKeyFrame(0.5f, Color(0.0f, 0.0f, 1.0f, 1.0f));
		specColorAnimation->SetKeyFrame(1.0f, Color(1.0f, 1.0f, 0.0f, 1.0f));
		specColorAnimation->SetKeyFrame(1.5f, Color(1.0f, 0.0f, 0.0f, 1.0f));
		// Optionally associate material with scene to make sure shader parameter animation respects scene time scale
		lightMaterial->SetShaderParameterAnimation("MatDiffColor", specColorAnimation);
		lightMaterial->SetShaderParameterAnimation("MatSpecColor", specColorAnimation);
		hullObject->SetMaterial(1, lightMaterial);
	}
	{
		Material* lightMaterial = cache->GetResource<Material>("Materials/ChristmasLights2.xml");
		// Apply shader parameter animation to material
		SharedPtr<ValueAnimation> specColorAnimation(new ValueAnimation(context_));
		specColorAnimation->SetKeyFrame(0.0f, Color(0.0f, 1.0f, 0.0f, 1.0f));
		specColorAnimation->SetKeyFrame(0.5f, Color(1.0f, 0.67f, 0.0f, 1.0f));
		specColorAnimation->SetKeyFrame(1.0f, Color(0.0f, 0.80f, 1.0f, 1.0f));
		specColorAnimation->SetKeyFrame(1.5f, Color(0.0f, 1.0f, 0.0f, 1.0f));
		// Optionally associate material with scene to make sure shader parameter animation respects scene time scale
		lightMaterial->SetShaderParameterAnimation("MatDiffColor", specColorAnimation);
		lightMaterial->SetShaderParameterAnimation("MatSpecColor", specColorAnimation);
		hullObject->SetMaterial(2, lightMaterial);
	}

    node->SetScale(Vector3(1, 1, 1) * _scale);
	//hullObject->SetDrawDistance(1500.0f);
    node->SetPosition(pos);
}

void Checkpoint::setId(unsigned int id)
{
    _id = id;
}

unsigned int Checkpoint::getId()
{
	return _id;
}

/**
* Handle physics world update. Called by LogicComponent base class.
*/
void Checkpoint::FixedUpdate(float timeStep)
{

}

void Checkpoint::PostUpdate(float timeStep)
{
    if (_fireworkTimer > 0) {
        _fireworkTimer -= timeStep;
        if (_fireworkTimer < 0) {
            if (_fireworkEmitter) {
                _fireworkEmitter->SetEmitting(false);
            }
        }
    }
}

bool Checkpoint::isLast()
{
    return _last;
}

void Checkpoint::initFireworks()
{
    ResourceCache* cache = GetSubsystem<ResourceCache>();
    Node* fireworks = GetNode()->CreateChild("FireworksNode");
    _fireworkEmitter = fireworks->CreateComponent<ParticleEmitter>(LOCAL);
    _fireworkEmitter->SetEffect(cache->GetResource<ParticleEffect>("Particle/Fireworks.xml"));
    _fireworkEmitter->SetEmitting(false);
    //Particle emitter should always be in the same scale
    fireworks->SetScale(Vector3(1, 1, 1) / GetNode()->GetScale());
}

void Checkpoint::setLast(bool val)
{
    _last = val;
}

void Checkpoint::startFireworks()
{
    return;
    if (_fireworkEmitter) {
        _fireworkEmitter->SetEmitting(true);
        _fireworkTimer = 0.1f;
    }
}

void Checkpoint::setPosition(Vector3 pos)
{
    _position = pos;
}

Vector3 Checkpoint::getPosition()
{
    return _position;
}