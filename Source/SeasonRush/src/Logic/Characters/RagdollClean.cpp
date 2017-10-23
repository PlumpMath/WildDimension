#include "Logic/Characters/RagdollClean.h"
#include <Urho3D/Urho3DAll.h>

#include <Urho3D/DebugNew.h>

RagdollClean::RagdollClean(Context* context) :
	Component(context),
    _lifetime(10)
{
    SubscribeToEvent(E_POSTUPDATE, URHO3D_HANDLER(RagdollClean, HandlePostUpdate));
}

void RagdollClean::RegisterObject(Context* context)
{
	context->RegisterFactory<RagdollClean>();
}

void RagdollClean::HandlePostUpdate(StringHash eventType, VariantMap& eventData)
{
    const float timeStep = eventData[PostUpdate::P_TIMESTEP].GetFloat();
    _lifetime -= timeStep;
    if (_lifetime < 0) {
        GetNode()->Remove();
    }
}
