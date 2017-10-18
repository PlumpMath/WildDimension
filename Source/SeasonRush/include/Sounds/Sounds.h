#pragma once
#include <Urho3D/Urho3DAll.h>

using namespace Urho3D;

static const StringHash SOUND_CHECKPOINT_REACHED("SoundCheckpointReached");
static const StringHash SOUND_POWERUP_COLLECTED("SoundPowerupCollected");
static const StringHash SOUND_CAR_COLLISION("SoundCarCollision");
static const StringHash SOUND_SLED_COLLISION("SoundSledCollision");

class Sounds : public Urho3D::Component
{
public:
	Sounds(Context* context);
	~Sounds();

	/**
	 * Register object factory and attributes.
	 */
	static void RegisterObject(Context* context);

    void HandleSoundEvent(StringHash eventType, VariantMap& eventData);

	URHO3D_OBJECT(Sounds, Urho3D::Component);
};
