#include "Logic/Vehicles/PowerupPicker.h"

PowerupPicker::PowerupPicker():
	_speedBoost(0.0f),
	_powerupLifetime(0.0f),
	_active(false)
{

}

PowerupPicker::~PowerupPicker()
{

}

void PowerupPicker::pickUpPowerup(PowerUp *powerup)
{
	if (_active) {
		return;
	}

	_speedBoost = 1.0;
	_powerupLifetime = 2;
	_active = true;
	_powerUp = powerup;
	_powerUp->GetNode()->SetEnabled(false);

    ResourceCache* cache = _powerUp->GetNode()->GetSubsystem<ResourceCache>();
    Sound* sound;
    sound = cache->GetResource<Sound>("Sounds/powerup.wav");

    Node* soundNode = _powerUp->GetNode()->CreateChild("PowerUpSound");
    SoundSource3D* soundSource = soundNode->CreateComponent<SoundSource3D>();
    soundSource->Play(sound);
    soundSource->SetAutoRemoveMode(REMOVE_NODE);
    soundSource->SetDistanceAttenuation(1.0f, 100.0f, 4.0f);
}

void PowerupPicker::updatePowerupPicker(float timeStep)
{
	if (!_active) {
		return;
	}

	_powerupLifetime -= timeStep;
	if (_powerupLifetime < 0) {
		_active = false;
		_speedBoost = 0;
		_powerUp->GetNode()->SetEnabled(true);
		_powerUp = nullptr;
	}
}