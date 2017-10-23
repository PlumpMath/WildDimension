#pragma once
#include "Logic/Vehicles/Offroad/Sled.h"
#include "Logic/Checkpoint.h"
#include <Urho3D/Urho3DAll.h>
#include <deque>

#include <Logic/Vehicles/Offroad/NewVehicle.h>
#include <Logic/Vehicles/Offroad/Sled.h>
#include <Logic/Vehicles/CheckpointPicker.h>
#include <Logic/PowerUp.h>

using namespace Urho3D;
using namespace Offroad;

/**
 * This component should hold all the information about players,
 * this will also send player info out when neccessarry etc.
 */
class Usables : public Urho3D::Component
{
private:
    /**
     * List of usable vehicles
     */
	Vector<SharedPtr<NewVehicle>> _vehicles;

	Vector<SharedPtr<Sled>> _sleds;

	Vector<SharedPtr<PowerUp>> _powerups;

    Vector<DriveableObject*> _driveables;
    Vector<CheckpointPicker*> _checkpointPickers;
    Vector<PowerupPicker*> _powerupPickers;


	Vector<SharedPtr<Checkpoint>> _checkpoints;

    /**
     * For which scene the object should be created
     */
    Scene* _scene;

	/**
	* Terrain
	*/
	Terrain* _terrain;

	Vector<Vector3> _trackPath;

    void regroupDriveables();

    unsigned int _lastFinishedPosition;

public:
	Usables(Context* context);
	~Usables();

	/**
     * Set the scene
     */
	void setScene(Scene* scene);

	/**
	 * Set the terrain
	 */
	void setTerrain(Terrain* terrain);

    /**
     * Get active scene
     */
	Scene* getActiveScene();

	/**
	 * Register object factory and attributes.
	 */
	static void RegisterObject(Context* context);

    /**
     * Create new vehicle
     */
    NewVehicle* createVehicle(Vector3 position, Vector3 direction, bool ready = false);

	/**
	* Create new vehicle
	*/
	Sled* createSled(Vector3 position, Vector3 direction, bool ready = false);

	Checkpoint* createCheckpoint(Node* node, Vector3 position, bool last = false);

	PowerUp* createPowerUp(Vector3 position);

	void setTrackPath(Vector<Vector3> trackPath);

	/**
	 * Remove all the vehicles from the map
	 */
	void destroyAllVehicles();

	void destroyAllSleds();

    /**
     * Get the nearest usable vehicle based on player position and vehicle usability radius
     */
	NewVehicle* getNearestVehicle(Vector3 position);

	/**
	* Get the nearest usable vehicle based on player position and vehicle usability radius
	*/
	Sled* getNearestSled(Vector3 position);

    DriveableObject* getNearestDriveableObject(Vector3 position);

    /**
     * Fixed physics timestep update
     */
	virtual void FixedUpdate(float timeStep);

	void HandlePostUpdate(StringHash eventType, VariantMap& eventData);

	void HandleCountDownFinished(StringHash eventType, VariantMap& eventData);

    void HandleDriveableEvents(StringHash eventType, VariantMap& eventData);

    void HandleDriveableClear(StringHash eventType, VariantMap& eventData);

    /**
     * Post update
     */
    virtual void PostUpdate(float timeStep);

    void sendOutPredictedNodes();

	URHO3D_OBJECT(Usables, Urho3D::Component);
};
