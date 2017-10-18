#pragma once
#include "Urho3D/Urho3DAll.h"

#ifdef _WIN32
#include <thread>
#endif

#include <list>
#include <deque>
#include "Logic/Players.h"
#include "Logic/OnePlayer.h"
#include "Logic/CameraController.h"
#include "Network/NetworkRequests.h"
#include "Logic/Checkpoint.h"
#include "Logic/Trees.h"
#include "Logic/Snowman.h"

using namespace Urho3D;
const float TOUCH_SENSITIVITY = 2.0f;

/**
 * When player enters new game or joins an existing one, this class creates everything for us
 */
class GameSession: public Object
{
private:
	/**
	 * Game session scene object
	 */
	SharedPtr<Scene> _scene;

	/**
	 * Game session viewport object
	 */
	SharedPtr<Viewport> _viewport;

	/**
	 * Start new game server when we hit "new game" button
	 */
	void startServer(bool lanServer, bool headless, VariantMap& eventData);

	/**
	 * Join already existing game when "join" button is pressed
	 */
	bool JoinServer(String address, String port);

    /**
     * List of vehicle nodes
     */
	std::deque<Node*> _vehicles;

    void InitTouchInput();

#ifdef _WIN32
	/**
	 * Broadcasting thread
	 */
	std::thread* _broadcastThread;
#endif

	/**
	 * Camera yaw
	 */
	float _yaw;

	/**
	 * Camera pitch
	 */
	float _pitch;

	/**
	 * Main terrain
	 */
	Terrain* _terrain;

	//std::list<String> _players;

	HashMap<Connection*, OnePlayer*> _clientPlayers;

	/**
	 * Draw aiming ray for the players
	 */
	void drawAimRay(float yaw, float pitch, Node* node);

	/**
	 * Server port
	 */
	unsigned short _serverPort;

	/**
	 * Current player info
	 */
	OnePlayer* _player;

	/**
	 * Current player ID
	 */
	unsigned short _playerId;

	/**
	 * Water reflection node
	 */
	Node* reflectionCameraNode_;

	Node* _waterNode;

	/**
	 * This creates water node and creates reflection texture to it
	 */
	void createWater();

	/**
	 * Updates water reflection based on camera position
	 */
	void updateWater();

	/**
	 * Network requests handler
	 */
	Synchronization::NetworkRequests** _network;

	/**
	 * Camera controller
	 */
	CameraController* _cameraController;

	/**
	 * Holds the information about pressed keys and mouse position
	 */
	Controls _controls;

	void drawTrees();

	bool _drawPhysics;

	SharedPtr<Trees> _trees;
	SharedPtr<Snowman> _snowmans;

	Vector<Vector3> _trackPath;

    unsigned int _vehicleCount;
    unsigned int _sledCount;
public:
	GameSession(Context* context);
	~GameSession();

	/// Register object factory and attributes.
	static void RegisterObject(Context* context);

	void setScene(SharedPtr<Scene> scene);

	/**
	 * Load scene and create players in there
	 */
	void createNewGame();


	void addVehicles(int sleds, int cars);

    void addHumans();

	/**
	 * Destroy created stuff
	 */
	void exitGame();

    /**
     * Set network requests handler
     */
    void setNetworkRequestHandler(Synchronization::NetworkRequests** network);

	/**
	 * Handle our custom game events
	 */
	void HandleGameEvents(StringHash eventType, VariantMap& eventData);

    void HandleNodePrediction(StringHash eventType, VariantMap& eventData);

    void HandleSubmitScore(StringHash eventType, VariantMap& eventData);

	/**
	 * When client connects
	 */
	void HandleClientConnected(StringHash eventType, VariantMap& eventData);

	/**
	 * When client disconnects
	 */
	void HandleClientDisconnected(StringHash eventType, VariantMap& eventData);

	/**
	 * Handle update each frame
	 */
	void HandleUpdate(StringHash eventType, VariantMap& eventData);

	void drawDebug(StringHash eventType, VariantMap& eventData);

	/**
	* Handle update each frame
	*/
	void HandlePostUpdate(StringHash eventType, VariantMap& eventData);

	/**
	 * Handle when client connects to server
	 */
	void HandleServerConnected(StringHash eventType, VariantMap& eventData);

	/**
	 * Handle client controls
	 */
	void HandlePhysicsPreStep(StringHash eventType, VariantMap& eventData);

	/**
	 * When server sends us information, which node we control
	 */
	void HandleRetrieveClientId(StringHash eventType, VariantMap& eventData);

	/**
	 * When we receive network message
	 */
	void HandleNetworkMessage(StringHash eventType, VariantMap& eventData);

	/**
	* When client sends his information
	*/
	void HandleClientIdentity(StringHash eventType, VariantMap& eventData);

	/**
	* Handle key pressed event
	*/
	void HandleKeyDown(StringHash eventType, VariantMap& eventData);


	/**
	 * Handle key release event
	 */
	void HandleKeyUp(StringHash eventType, VariantMap& eventData);

	void HandlePhysicsChanged(StringHash eventType, VariantMap& eventData);

	/**
	 * Subscribe to all events
	 */
	void subscribe();

	/**
	 * Remove all the objects
	 */
	void cleanup();

	URHO3D_OBJECT(GameSession, Urho3D::Object);
};

