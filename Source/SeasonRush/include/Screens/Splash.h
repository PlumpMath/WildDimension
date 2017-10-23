#pragma once
#include <Urho3D/Urho3DAll.h>
#include <list>
#include <deque>
#include <map>
#include "Effects/Fader.h"

using namespace Urho3D;

/**
 * This component should hold all the information about players,
 * this will also send player info out when neccessarry etc.
 */
class Splash : public Urho3D::LogicComponent
{
private:
	float _time;

	BorderImage* _logo;
	BorderImage* _gameLogo;
	Fader* _fader;

	int _logoIndex;

public:
	Splash(Context* context);
	~Splash();

	/**
	 * Register object factory and attributes.
	 */
	static void RegisterObject(Context* context);

	/**
	 * Show the splashscreen
	 */
	void show();

	/**
	 * Update each frame
	 */
	virtual void PostUpdate(float timeStep);

	/**
	 * Destroy the splashscreen
	 */
	void destroy();

	URHO3D_OBJECT(Splash, Urho3D::LogicComponent);
};
