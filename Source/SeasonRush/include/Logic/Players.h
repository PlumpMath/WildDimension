#pragma once
#include <Urho3D/Urho3DAll.h>
#include <list>
#include <deque>
#include <map>

#include "Logic/OnePlayer.h"

using namespace Urho3D;

/**
 * This component should hold all the information about players,
 * this will also send player info out when neccessarry etc.
 */
class Players : public Urho3D::LogicComponent
{
private:
    /**
     * List of all player objects
     */
	std::list<OnePlayer*> _playerList;

    /**
     * Gui update cooldown
     */
    float _guiUpdateCooldown;

	/**
	 * Active scene object
	 */
	SharedPtr<Scene> _scene;

	/**
	 * Main terrain
	 */
	Terrain** _terrain;

	/**
	* Create player scene elements
	*/
	Node* createPlayerControlledNode(Scene* scene, Terrain* terrain);

public:
	Players(Context* context);
	~Players();

	/**
	 * Set the active scene
	 */
	void setScene(SharedPtr<Scene> scene);

	/**
	 * Set the main terrain
	 */
	void setTerrain(Terrain** terrain);

	/**
	 * Add new player
	 * Returns newly added player pointer
	 */
	OnePlayer* createPlayer(bool localPlayer = false, int playerId = -1);

	/**
	 * Remove the player
	 */
	void removePlayer(unsigned short id);

	/**
	 * Get the player information from node
	 */
	OnePlayer* getPlayerByNode(Node* node);

	/**
	 * Get player by his ID
	 */
	OnePlayer* getPlayerById(unsigned short id);

	/**
	 * Get random player
	 */
	OnePlayer* getRandomPlayer();

	/**
	 * Register object factory and attributes.
	 */
	static void RegisterObject(Context* context);

    /**
     * Fixed physics timestep update
     */
	virtual void FixedUpdate(float timeStep);

    /**
     * Post update
     */
    virtual void PostUpdate(float timeStep);

    void HandleDriveableClear(StringHash eventType, VariantMap& eventData);

	void cleanup();

	URHO3D_OBJECT(Players, Urho3D::LogicComponent);
};
