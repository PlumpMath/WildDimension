#pragma once

#include <Urho3D/Physics/CollisionShape.h>
#include <Urho3D/Physics/Constraint.h>
#include <Urho3D/Urho3DAll.h>

using namespace Urho3D;

/// Custom component that creates a ragdoll upon collision.
class RagdollClean : public Component
{

public:
	/// Construct.
    RagdollClean(Context* context);

	/**
	* Register object factory and attributes.
	*/
	static void RegisterObject(Context* context);

private:
    float _lifetime;
	/// Handle scene node's physics collision.
	//void Handle(StringHash eventType, VariantMap& eventData);
    void HandlePostUpdate(StringHash eventType, VariantMap& eventData);

	URHO3D_OBJECT(RagdollClean, Component);
};