#include <Urho3D/Urho3DAll.h>
#include "Logic/PowerUp.h"

using namespace Urho3D;

static const int GAME_TIME = 300;//in seconds

PowerUp::PowerUp(Context* context) :
Urho3D::Component(context),
_scale(1.0f)
{
}


PowerUp::~PowerUp()
{
}


void PowerUp::RegisterObject(Context* context)
{
	context->RegisterFactory<PowerUp>();
}

void PowerUp::setPowerupType(unsigned int type)
{
	_type = type;
}

void PowerUp::Init(unsigned int powerupType)
{
	_type = powerupType;

	ResourceCache* cache = GetSubsystem<ResourceCache>();

	_node = GetNode();
	StaticModel* hullObject = _node->CreateComponent<StaticModel>();
	Model* model = cache->GetResource<Model>("Models/christmas/present.mdl");
	hullObject->SetModel(model);
	hullObject->SetMaterial(0, cache->GetResource<Material>("Materials/Colors/Green.xml"));
	hullObject->SetMaterial(1, cache->GetResource<Material>("Materials/Colors/Red.xml"));

	//hullObject->SetDrawDistance(1500.0f);

    ScriptInstance* instance = _node->CreateComponent<ScriptInstance>();
    instance->CreateObject(cache->GetResource<ScriptFile>("Scripts/Rotator.as"), "Rotator");
    // Call the script object's "SetRotationSpeed" function. Function arguments need to be passed in a VariantVector
    VariantVector parameters;
    parameters.Push(Vector3(10.0f, 20.0f, 30.0f));
    instance->Execute("void SetRotationSpeed(const Vector3&in)", parameters);

    VariantVector parameters2;
    parameters2.Push(_node->GetPosition());
    instance->Execute("void SetInitialPosition(const Vector3&in)", parameters2);

	_node->SetScale(Vector3(1, 1, 1) * _scale);
}