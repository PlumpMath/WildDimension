#pragma once
#include <Urho3D/Urho3DAll.h>
#include <list>
#include "Logic/Usables.h"
#include "Logic/Vehicles/DriveableObject.h"

using namespace Urho3D;

static const float PLAYER_SPEED = 20.0f;
static const float PLAYER_SPEED_CATCHER = 25.0f;

/**
 * This object will hold information about specific player
 */
class OnePlayer : public Urho3D::LogicComponent
{
private:

	/**
	 * Player name
	 */
	String _name;

	/**
	 * Player health
	 */
	unsigned short _health;

	/**
	 * Player points
	 */
	float _points;

	/**
	 * Player controlled node
	 */
	Node* _node;

	/**
	 * When the ping request was sent
	 */
	unsigned int _pingRequestTime;

	/**
	 *  Player ping
	 */
	unsigned short _ping;

	/**
	 * Which vehicle this player is controlling
	 */
	DriveableObject* _driveableObject;

	/**
	 * Time since last action
	 */
	float _lastActionCooldown;

	/**
	 * Which node camera should follow
	 */
	Node* _cameraNode;

	/**
	 * Control values for this player
	 */
	Controls _controls;

	/**
	 * Is this the player on the local system
	 */
	bool _isServerPlayer;

    /**
     * Pointer to usables class
     */
    Usables* _usables;

	/**
	 * Do we have to send out this players information to all the clients?
	 */
	bool _updateNeeded;

    SharedPtr<Connection> _connection;

    float _time;
public:
	OnePlayer(Context* context);
	~OnePlayer();

    /**
	 * Register object factory and attributes.
	 */
	static void RegisterObject(Context* context);

    /**
     * Set usables class pointer
     */
    void setUsables(Usables* usables);

    void setPlayerConnection(Connection* connection);

    /**
     * Set player controlled node
     */
    void setControlledNode(Node* node = nullptr);

	/**
	 * Get player controlled node
	 */
	Node* getControlledNode();

	/**
	 * Set the player name
	 */
	void setName(String name);

    /**
     * Get the player name
     */
    String getName();

    /**
     * Set the player health
     */
    void setHealth(unsigned short val);

    /**
     * Get the player health
     */
    unsigned short getHealth();

    /**
     * Set the time when ping request was sent
     */
    void setPingRequestTime(unsigned int time);

    /**
     * Get ping request time for this player
     */
    unsigned int getPingRequestTime();

    /**
     * Set the ping for this player
     */
    void setPing(unsigned int time);

    /**
     * Get the ping for this player
     */
    unsigned short getPing();

 
    /**
     * Set the camera node
     */
    void setCameraNodeById(unsigned int id);

    /**
     * Set player camera node
     */
    void setCameraNode(Node* node);

	/**
	 * Get camera node
	 */
	Node* getCameraNode();

	/**
	 * Add points to the player,
	 * provide negative value to take away points
	 */
	void addPoints(float val);

    /**
     * Set player points
     */
    void setPoints(float val);

	/**
	 * Get player points
	 */
	float getPoints();

    /**
     * Set the player controls
     */
    void setControls(Controls controls);

    /**
	 * Get this player controls
	 */
	Controls getControls();

	/**
	 * Set if this player is local player or not
	 */
	void setServerPlayer(bool val);

	/**
	 * Is this player from the local system
	 */
	bool isServerPlayer();

	/**
	 * Toggle physics for player controlled node
	 */
	void togglePhysics(bool val);
	
	/**
	 * Avoid from falling trough terrain
	 */
	void fixYPos(float y);

//################## ACTIONS
    /**
     * Enter the car
     */
	void enterDriveableObject(DriveableObject* driveableObject);

	/**
     * Enter from car
     */
	void exitDriveableObject();


	/**
	 * Do any action, this aplies cooldown value for the future player actions
	 */
	void doAction(float cooldown = 1.0f);

	/**
	 * Do the player updates based on his controls
	 */
	void FixedUpdate(float timeStep);

	/**
	* Do the player updates based on his controls
	*/
	void PostUpdate(float timeStep);

//################## ACTIONS END

//########### CLEANUP METHODS
    /**
	 *  Destroys all the elements for this player
	 */
	void destroy();
//########### CLEANUP METHODS END

	/**
	 * Do we have to send out the information about this player?
	 * This method is supposed to be called only once, after the call
	 * this parameter is set to it's default value - False
	 */
	bool isUpdateNeeded();

    void playerPointsChanged(StringHash eventType, VariantMap& eventData);

    void lastCheckpointReached(StringHash eventType, VariantMap& eventData);

	URHO3D_OBJECT(OnePlayer, Urho3D::LogicComponent);
};
