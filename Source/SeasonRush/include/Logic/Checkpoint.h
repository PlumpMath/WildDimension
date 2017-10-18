#pragma once
#include "Urho3D/Urho3DAll.h"
#include <vector>

using namespace Urho3D;

class Checkpoint : public Urho3D::LogicComponent
{
public:
	Checkpoint(Context* context);
	~Checkpoint();

	static void RegisterObject(Context* context);

	/**
	* Handle physics world update. Called by LogicComponent base class.
	*/
	virtual void FixedUpdate(float timeStep);
	virtual void PostUpdate(float timeStep);

	/**
	 * Add new checkpoint to the map
	 */
	void create(Vector3 pos);

    void initFireworks();

    void setId(unsigned int id);
	unsigned int getId();

    void setLast(bool val);
    bool isLast();

    void setPosition(Vector3 pos);

    Vector3 getPosition();

    void startFireworks();
private:
	unsigned int _id;

	float _scale;

    bool _last;

    float _fireworkTimer;

    Vector3 _position;

    SharedPtr<ParticleEmitter> _fireworkEmitter;

	URHO3D_OBJECT(Checkpoint, Urho3D::LogicComponent);
};
