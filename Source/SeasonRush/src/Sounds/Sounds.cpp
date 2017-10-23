#include "Urho3D/Urho3DAll.h"
#include "Sounds/Sounds.h"

using namespace Urho3D;

Sounds::Sounds(Context* context) :
Urho3D::Component(context)
{
}


Sounds::~Sounds()
{
}


void Sounds::RegisterObject(Context* context)
{
	context->RegisterFactory<Sounds>();
}

void Sounds::HandleSoundEvent(StringHash eventType, VariantMap& eventData)
{
}