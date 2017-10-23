#pragma once
#include "Urho3D/Urho3DAll.h"
#include <vector>

using namespace Urho3D;

const unsigned int POWERUP_TYPE_SPEED = 0;

class PowerUp : public Urho3D::Component
{
private:

	SharedPtr<Scene> _scene;
	SharedPtr<Terrain> _terrain;

	/**
	 * Powerup type
	 */
	unsigned int _type;

	float _scale;

	SharedPtr<Node> _node;
public:
	PowerUp(Context* context);
	~PowerUp();

	static void RegisterObject(Context* context);

	void setPowerupType(unsigned int type);

	/**
	 * Add new powerup to the map
	 */
	void Init(unsigned int powerupType);

	/**
	 * Add random powerup
	 */
	void createRandom(Vector3 pos);

	URHO3D_OBJECT(Component, Urho3D::Object);
};
