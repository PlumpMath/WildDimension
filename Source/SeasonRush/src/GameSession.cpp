#include "Urho3D/Urho3DAll.h"
#include "GameSession.h"
#include "LanBroadcast.h"
#include "Events.h"

#include "Logic/Players.h"
#include "Logic/Gui.h"
#include "Logic/Usables.h"
#include "Logic/PowerUp.h"
#include "Logic/Characters/Ragdoll.h"
#include "Logic/Vehicles/Offroad/NewVehicle.h"
#include "Logic/Vehicles/Offroad/RaycastVehicle.h"
#include "Logic/Vehicles/Offroad/WheelTrackModel.h"

#include "Sounds/Sounds.h"
#include "version.h"

using namespace Offroad;

void broadcastThreadFunction(unsigned short serverPort)
{
	LanBroadcast::instance().broadcast(serverPort);
}

GameSession::GameSession(Context* context) :
Urho3D::Object(context),
_serverPort(25019),
reflectionCameraNode_(nullptr),
_scene(nullptr),
_player(nullptr),
_cameraController(nullptr),
_drawPhysics(false),
_yaw(0.0f),
_pitch(0.0f),
_vehicleCount(0),
_sledCount(0)
{
	subscribe();
	UnsubscribeFromEvent(E_SCENEUPDATE);
}


GameSession::~GameSession()
{
}


void GameSession::RegisterObject(Context* context)
{
	context->RegisterFactory<GameSession>();

	context->RegisterSubsystem(new Script(context));

	Players::RegisterObject(context);
	Gui::RegisterObject(context);
	Usables::RegisterObject(context);
	Sled::RegisterObject(context);
	PowerUp::RegisterObject(context);
	
	NewVehicle::RegisterObject(context);
	Offroad::RaycastVehicle::RegisterObject(context);
	WheelTrackModel::RegisterObject(context);

	Sounds::RegisterObject(context);
	CameraController::RegisterObject(context);

	Checkpoint::RegisterObject(context);

	Ragdoll::RegisterObject(context);

    Trees::RegisterObject(context);
}

void GameSession::createNewGame()
{
    InitTouchInput();

	ResourceCache* cache = GetSubsystem<ResourceCache>();

	//Create new game session scene
	_scene = new Scene(context_);
    _scene->CreateComponent<Sounds>();
    
	XMLFile* sceneFile = cache->GetResource<XMLFile>("Scenes/Map.xml");
	_scene->LoadXML(sceneFile->GetRoot());
	_scene->GetComponent<PhysicsWorld>()->SetGravity(Vector3(0, -5, 0));
	Node* terrain = _scene->GetChild("terrainNode", true);
	_terrain = terrain->GetComponent<Terrain>();
    terrain->SetRotation(Quaternion());
	
	_cameraController = _scene->CreateComponent<CameraController>(LOCAL);
	_cameraController->init(_scene);
	GetSubsystem<Audio>()->SetListener(_cameraController->getRotationNode()->GetComponent<SoundListener>());

	_viewport = new Viewport(context_, _scene, _cameraController->getCamera());
    if (_viewport && _viewport->GetRenderPath()) {
        SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
        //effectRenderPath->Append(cache->GetResource<XMLFile>("PostProcess/Vibrance.xml"));
        effectRenderPath->Append(cache->GetResource<XMLFile>("PostProcess/GammaCorrection.xml"));
        effectRenderPath->Append(cache->GetResource<XMLFile>("PostProcess/Bloom.xml"));
        effectRenderPath->Append(cache->GetResource<XMLFile>("PostProcess/Toon.xml"));
        effectRenderPath->Append(cache->GetResource<XMLFile>("PostProcess/FXAA2.xml"));
        //effectRenderPath->SetEnabled("Vibrance", true);
        effectRenderPath->SetEnabled("GammaCorrection", false);
        effectRenderPath->SetEnabled("Bloom", true);
        effectRenderPath->SetEnabled("Toon", false);
        effectRenderPath->SetEnabled("FXAA2", true);
        _viewport->SetRenderPath(effectRenderPath);

        _scene->CreateComponent<DebugRenderer>(LOCAL);
    }

    _scene->CreateComponent<Usables>(LOCAL);

	//Add player handling component
	Players* players = _scene->CreateComponent<Players>(LOCAL);
	players->setScene(_scene);
	players->setTerrain(&_terrain);
	//Add usables component


	Gui* gui = _scene->CreateComponent<Gui>(LOCAL);
	gui->init();

	//createWater();

    /**
     * Set the active scene
     */
	_scene->GetComponent<Usables>()->setScene(_scene);

	_scene->GetComponent<Usables>()->setTerrain(_terrain);

	//Search up to 100 path points
	for (int i = 0; i < 100; i++) {
		Node* p = _scene->GetChild("path" + String(i), true);
		if (p) {
			Vector3 pos = p->GetWorldPosition();
			pos.y_ = _terrain->GetHeight(pos);
			pos = _terrain->GetNode()->GetWorldRotation() * pos;
			_trackPath.Push(pos);

			if (i > 0) {
				pos = (pos + _trackPath.At(i - 1)) / 2.0f;
				for (int pu = 0; pu < 1; pu+=1) {
					pos.y_ = _terrain->GetHeight(pos);
					pos.x_ += pu;
					pos.z_ += pu;
					pos = _terrain->GetNode()->GetWorldRotation() * pos;
					pos.y_ += 0.8f;
					_scene->GetComponent<Usables>()->createPowerUp(pos);
				}
			}
			p->SetEnabled(false);
		}
	}

	Node* finishNode = _scene->GetChild("FinishNode", true);
	if (finishNode) {
		_trackPath.Push(finishNode->GetWorldPosition());
	}

	_scene->GetComponent<Usables>()->setTrackPath(_trackPath);

	int index = 0;
	while (index < _trackPath.Size() - 1) {
		Checkpoint* ch = _scene->GetComponent<Usables>()->createCheckpoint(nullptr, _trackPath.At(index), (index == _trackPath.Size() - 1));
		if (index == _trackPath.Size() - 1) {
			ch->GetNode()->SetDirection(Vector3::FORWARD);
		}
		else {
			ch->GetNode()->SetDirection(_trackPath.At(index + 1) - _trackPath.At(index));
		}
		index++;
	}
    _scene->GetComponent<Usables>()->createCheckpoint(finishNode, _trackPath.At(index), true);

    _trees = _scene->CreateComponent<Trees>();
	_trees->setScene(_scene);
	_trees->setTerrain(_terrain);

    const float distance = 40;
	for (int i = -900; i < 900; i += distance) {
		for (int j = -900; j < 900; j += distance) {
			_trees->add(Vector3(i + Random(distance) - distance/2, 0, j + Random(distance) - distance/2), true);
		}
	}

	/*_snowmans = new Snowman(context_);
	_snowmans->setScene(_scene);
	_snowmans->setTerrain(_terrain);

	for (int i = -10; i < 0; i++) {
		for (int j = -10; j < 0; j++) {
			//_snowmans->add(Vector3(i * Random(50), 0, j * Random(60)));
		}
	}*/

	//No need to show the mouse, we will use it for 3D navigation
	GetSubsystem<Input>()->SetMouseGrabbed(true);
	GetSubsystem<Input>()->SetMouseVisible(false);

	Renderer* renderer = GetSubsystem<Renderer>();
    if (renderer) {
        renderer->SetViewport(0, _viewport);
    }

	//drawTrees();
}

void GameSession::addVehicles(int sleds, int cars)
{
    _vehicleCount = cars;
    _sledCount = sleds;
    Node* start = _scene->GetChild("startNode", true);

    if (start) {
        Vector3 startPosition = start->GetWorldPosition();
        int createdCars = 0;
        int createdSleds = 0;
        for (int i = 0; i < 5; i++) {
            if (cars - createdCars > 0) {
                int shouldCreate = 20;
                if (shouldCreate > cars - createdCars) {
                    shouldCreate = cars - createdCars;
                }
                startPosition.z_ += 10;
                //startPosition.y_ += 20;
                VariantMap map;
                map[P_POSITION] = startPosition;
                map[P_DIRECTION] = _trackPath.At(0) - startPosition;
                map[P_COUNT] = shouldCreate;
                SendEvent(E_ADD_VEHICLE, map);
                createdCars += shouldCreate;
            }

            if (sleds - createdSleds > 0) {
                int shouldCreate = 20;
                if (shouldCreate > sleds - createdSleds) {
                    shouldCreate = sleds - createdSleds;
                }
                startPosition.z_ += 10;
                
                VariantMap map;
                map[P_POSITION] = startPosition;
                map[P_DIRECTION] = _trackPath.At(0) - startPosition;
                map[P_COUNT] = shouldCreate;
                SendEvent(E_ADD_SLED, map);
                createdSleds += shouldCreate;
            }
        }

    }
}

void GameSession::addHumans()
{
    ResourceCache* cache = GetSubsystem<ResourceCache>();
    for (int i = 0; i < _trackPath.Size() - 1; i++) {
        Node* modelNode = _scene->CreateChild("Jack");
        modelNode->SetScale(2);
        Vector3 pos = _trackPath.At(i);
        //pos.y_ = _terrain->GetHeight(pos);
        //pos = _terrain->GetNode()->GetRotation() * pos;
        modelNode->SetPosition(pos);

        modelNode->SetRotation(Quaternion(0.0f, 180.0f, 0.0f));
        AnimatedModel* modelObject = modelNode->CreateComponent<AnimatedModel>();
        modelObject->SetModel(cache->GetResource<Model>("Models/Jack.mdl"));
        modelObject->SetMaterial(0, cache->GetResource<Material>("Materials/JackBody.xml"));
        modelObject->SetMaterial(1, cache->GetResource<Material>("Materials/JackHead.xml"));
       // modelObject->SetCastShadows(true);
        // Set the model to also update when invisible to avoid staying invisible when the model should come into
        // view, but does not as the bounding box is not updated
        modelObject->SetUpdateInvisible(true);
        modelNode->CreateComponent<AnimationController>()->Play("Models/Jack_Walk.ani", 0, true);

        //AnimationController* control = modelNode->CreateComponent<AnimationController>();
       //control->Play()

        // Create a rigid body and a collision shape. These will act as a trigger for transforming the
        // model into a ragdoll when hit by a moving object
        RigidBody* body = modelNode->CreateComponent<RigidBody>();
        // The Trigger mode makes the rigid body only detect collisions, but impart no forces on the
        // colliding objects
        body->SetTrigger(true);
        CollisionShape* shape = modelNode->CreateComponent<CollisionShape>();
        // Create the capsule shape with an offset so that it is correctly aligned with the model, which
        // has its origin at the feet
        shape->SetCapsule(0.7f, 2.0f, Vector3(0.0f, 1.0f, 0.0f));

        // Create a custom component that reacts to collisions and creates the ragdoll
        modelNode->CreateComponent<Ragdoll>();
    }
}

void GameSession::createWater()
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();
	// Create a water plane object that is as large as the terrain
	Node* waterNode_ = _scene->CreateChild("Water");
	waterNode_->SetScale(Vector3(4096.0f, 1, 4096.0f));
	waterNode_->SetPosition(Vector3(0.0f, _terrain->GetHeight(Vector3(400, 1, 400)) - 0.5, 0.0f));
	StaticModel* water = waterNode_->CreateComponent<StaticModel>();
	_waterNode = waterNode_;
	water->SetModel(cache->GetResource<Model>("Models/Plane.mdl"));
	water->SetMaterial(cache->GetResource<Material>("Materials/Water.xml"));
	// Set a different viewmask on the water plane to be able to hide it from the reflection camera
	water->SetViewMask(0x80000000);
	water->SetOccluder(true);

	// Create a mathematical plane to represent the water in calculations
	Plane waterPlane_ = Plane(waterNode_->GetWorldRotation() * Vector3(0.0f, 1.0f, 0.0f), waterNode_->GetWorldPosition());
	// Create a downward biased plane for reflection view clipping. Biasing is necessary to avoid too aggressive clipping
	Plane waterClipPlane_ = Plane(waterNode_->GetWorldRotation() * Vector3(0.0f, 1.0f, 0.0f), waterNode_->GetWorldPosition() -
		Vector3(0.0f, 0.1f, 0.0f));

	Graphics* graphics = GetSubsystem<Graphics>();
	// Create camera for water reflection
	// It will have the same farclip and position as the main viewport camera, but uses a reflection plane to modify
	// its position when rendering
	reflectionCameraNode_ = _cameraController->getCameraNode()->CreateChild("subCamera", LOCAL);
	Camera* reflectionCamera = reflectionCameraNode_->CreateComponent<Camera>(LOCAL);
	reflectionCamera->SetFarClip(1000);
	reflectionCamera->SetViewMask(0x7fffffff); // Hide objects with only bit 31 in the viewmask (the water plane)
	reflectionCamera->SetAutoAspectRatio(false);
	reflectionCamera->SetUseReflection(true);
	reflectionCamera->SetReflectionPlane(waterPlane_);
	reflectionCamera->SetUseClipping(true); // Enable clipping of geometry behind water plane
	reflectionCamera->SetClipPlane(waterClipPlane_);
	// The water reflection texture is rectangular. Set reflection camera aspect ratio to match
	reflectionCamera->SetAspectRatio((float)graphics->GetWidth() / (float)graphics->GetHeight());
	// View override flags could be used to optimize reflection rendering. For example disable shadows
	//reflectionCamera->SetViewOverrideFlags(VO_DISABLE_SHADOWS);

	// Create a texture and setup viewport for water reflection. Assign the reflection texture to the diffuse
	// texture unit of the water material
	int texSize = 64;
	SharedPtr<Texture2D> renderTexture(new Texture2D(context_));
	renderTexture->SetSize(texSize, texSize, Graphics::GetRGBFormat(), TEXTURE_RENDERTARGET);
	renderTexture->SetFilterMode(FILTER_BILINEAR);
	RenderSurface* surface = renderTexture->GetRenderSurface();
	SharedPtr<Viewport> rttViewport(new Viewport(context_, _scene, reflectionCamera));
	surface->SetViewport(0, rttViewport);
	Material* waterMat = cache->GetResource<Material>("Materials/Water.xml");
	waterMat->SetTexture(TU_DIFFUSE, renderTexture);
}

void GameSession::drawTrees()
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();
	// Create billboard sets (floating smoke)
	const unsigned NUM_BILLBOARDNODES = 1000;
	const unsigned NUM_BILLBOARDS = 1;

	for (unsigned i = 0; i < NUM_BILLBOARDNODES; ++i)
	{
		Node* smokeNode = _scene->CreateChild("Smoke");
		Vector3 vehPosition = Vector3(Random(200.0f) - 100.0f, Random(20.0f) + 100.0f, Random(200.0f) - 100.0f);
		vehPosition.y_ = _terrain->GetHeight(vehPosition) + 2;
		smokeNode->SetPosition(vehPosition);

		BillboardSet* billboardObject = smokeNode->CreateComponent<BillboardSet>();
		billboardObject->SetNumBillboards(NUM_BILLBOARDS);
		billboardObject->SetMaterial(cache->GetResource<Material>("Materials/Tree.xml"));
		billboardObject->SetSorted(true);

		for (unsigned j = 0; j < NUM_BILLBOARDS; ++j)
		{
			Billboard* bb = billboardObject->GetBillboard(j);

			bb->position_ = Vector3(0,0,0);
			bb->size_ = Vector2(0.76 * 3, 1.0 * 3);
			//bb->rotation_ = Random() * 360.0f;
			bb->enabled_ = true;
		}

		// After modifying the billboards, they need to be "committed" so that the BillboardSet updates its internals
		billboardObject->Commit();
	}
}

void GameSession::updateWater()
{
	if (reflectionCameraNode_ != nullptr) {
		Graphics* graphics = GetSubsystem<Graphics>();
		if (reflectionCameraNode_->HasComponent<Camera>()) {
			Camera* reflectionCamera = reflectionCameraNode_->GetComponent<Camera>();
			if (reflectionCamera) {
				reflectionCamera->SetAspectRatio((float)graphics->GetWidth() / (float)graphics->GetHeight());
			}
		}
	}
}

void GameSession::exitGame()
{
	//Turn of the broadcasting
	LanBroadcast::instance().toggleBroadcast(false);
#ifdef _WIN32
	//Finally join broadcast thread
	_broadcastThread->join();
	delete _broadcastThread;
#endif
}

void GameSession::setNetworkRequestHandler(Synchronization::NetworkRequests** network)
{
    _network = network;
}

void GameSession::HandleGameEvents(StringHash eventType, VariantMap& eventData)
{
	if (eventType == E_GAME_NEW) {
		//New game should be created
		bool lan = eventData[P_SERVER_LAN].GetBool();
        bool headless = eventData[P_SERVER_HEADLESS].GetBool();
		lan = false;

		//Load the scene
		createNewGame();

		//Create the server
		startServer(lan, headless, eventData);
	}
	else if (eventType == E_GAME_JOIN) {
		//Load the scene
		createNewGame();

		String address = eventData[P_SERVER_ADDRESS].GetString();
		String port = eventData[P_SERVER_PORT].GetString();

		//Join already existing server
		if (!JoinServer(address, port)) {
			SendEvent(E_GAME_STOP);
		}
	}
}

void GameSession::subscribe()
{
	SubscribeToEvent(E_KEYDOWN, URHO3D_HANDLER(GameSession, HandleKeyDown));
	SubscribeToEvent(E_KEYUP, URHO3D_HANDLER(GameSession, HandleKeyUp));
	SubscribeToEvent(E_CLIENTCONNECTED, URHO3D_HANDLER(GameSession, HandleClientConnected));
	SubscribeToEvent(E_CLIENTDISCONNECTED, URHO3D_HANDLER(GameSession, HandleClientDisconnected));

	SubscribeToEvent(E_UPDATE, URHO3D_HANDLER(GameSession, HandleUpdate));
	SubscribeToEvent(E_POSTUPDATE, URHO3D_HANDLER(GameSession, HandlePostUpdate));

	//Handle any incomming network messages
	SubscribeToEvent(E_NETWORKMESSAGE, URHO3D_HANDLER(GameSession, HandleNetworkMessage));

	//When we connect to server
	SubscribeToEvent(E_SERVERCONNECTED, URHO3D_HANDLER(GameSession, HandleServerConnected));

	SubscribeToEvent(E_PHYSICSPRESTEP, URHO3D_HANDLER(GameSession, HandlePhysicsPreStep));

	//Register for our custom event which will send the clients thei IDS
	GetSubsystem<Network>()->RegisterRemoteEvent(E_CLIENT_ID);
    GetSubsystem<Network>()->RegisterRemoteEvent(E_CLIENT_NODE_CHANGED);

    GetSubsystem<Network>()->RegisterRemoteEvent(E_UPDATE_GUI);
    GetSubsystem<Network>()->RegisterRemoteEvent(E_UPDATE_SCORE);
    GetSubsystem<Network>()->RegisterRemoteEvent(E_CP_POINTS_CHANGED);
    GetSubsystem<Network>()->RegisterRemoteEvent(E_GUI_POINTS_CHANGED);
    GetSubsystem<Network>()->RegisterRemoteEvent(E_PREDICT_NODE_POSITION);

	SubscribeToEvent(E_CLIENT_ID, URHO3D_HANDLER(GameSession, HandleRetrieveClientId));
    SubscribeToEvent(E_CLIENT_NODE_CHANGED, URHO3D_HANDLER(GameSession, HandleRetrieveClientId));

	SubscribeToEvent(E_CLIENTIDENTITY, URHO3D_HANDLER(GameSession, HandleClientIdentity));

	SubscribeToEvent(E_PHYSICS_STEP_CHANGED, URHO3D_HANDLER(GameSession, HandlePhysicsChanged));
	SubscribeToEvent(E_PHYSICS_SUBSTEP_CHANGED, URHO3D_HANDLER(GameSession, HandlePhysicsChanged));
	SubscribeToEvent(E_DRAW_PHYSICS, URHO3D_HANDLER(GameSession, HandlePhysicsChanged));
	SubscribeToEvent(E_PHYSICS_GRAVITY, URHO3D_HANDLER(GameSession, HandlePhysicsChanged));

	SubscribeToEvent(E_POSTRENDERUPDATE, URHO3D_HANDLER(GameSession, drawDebug));

    SubscribeToEvent(E_PREDICT_NODE_POSITION, URHO3D_HANDLER(GameSession, HandleNodePrediction));

    SubscribeToEvent(E_SUBMIT_SCORE, URHO3D_HANDLER(GameSession, HandleSubmitScore));

}

void GameSession::drawDebug(StringHash eventType, VariantMap& eventData)
{
	if (!_drawPhysics) {
		return;
	}

	DebugRenderer * dbgRenderer = _scene->GetComponent<DebugRenderer>();
	if (dbgRenderer)
	{
		// Draw navmesh data
		//DynamicNavigationMesh * navMesh = _scene->GetComponent<DynamicNavigationMesh>();
		//navMesh->DrawDebugGeometry(dbgRenderer, false);

		// Draw Physics data :
		PhysicsWorld * phyWorld = _scene->GetComponent<PhysicsWorld>();
		phyWorld->DrawDebugGeometry(dbgRenderer, false);
	}
}

void GameSession::HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
	using namespace KeyDown;
	int key = eventData[P_KEY].GetInt();
}

void GameSession::HandleKeyUp(StringHash eventType, VariantMap& eventData)
{
	using namespace KeyDown;
	int key = eventData[P_KEY].GetInt();

	if (key == KEY_ESCAPE) {
		//Remove all the vehicles from the map
        Network* network = GetSubsystem<Network>();
        if (network->IsServerRunning()) {
            network->StopServer();
        }
        else {
            network->Disconnect();
        }
		SendEvent(E_GAME_STOP);
	}
}

void GameSession::startServer(bool lanServer, bool headless, VariantMap& eventData)
{
    URHO3D_LOGINFO("Starting server with the following options:");
    URHO3D_LOGINFOF("AI Following: %d", eventData[P_GAME_SETTINGS_AI_FOLLOW].GetBool());
    URHO3D_LOGINFOF("Cars: %d", eventData[P_GAME_SETTINGS_CAR_COUNT].GetInt());
    URHO3D_LOGINFOF("Sleds: %d", eventData[P_GAME_SETTINGS_SLED_COUNT].GetInt());
    URHO3D_LOGINFOF("Starting vehicle: %d", eventData[P_GAME_SETTINGS_START_VEHICLE].GetInt());
	ResourceCache* cache = GetSubsystem<ResourceCache>();
	Network* network = GetSubsystem<Network>();

	//If we cannot create server, we should try using different port
	while (!network->StartServer(_serverPort)) {
		_serverPort++;
	}

	//If this is an online server, we should let our web server know about this one
	if (!lanServer) {
        Synchronization::RequestInfo info;
        info.addGetVariable("port", String(_serverPort));
        info.addGetVariable("size", String(32));
        info.addGetVariable("players", String(1));
        info.addGetVariable("map", String(0));
        info.addGetVariable("version", VERSION);
		Synchronization::RequestInfo* request =  (*_network)->addNewRequest(Synchronization::NEW_SERVER, info);
	}
    {
        Synchronization::RequestInfo info;
        info.addGetVariable("version", VERSION);
        (*_network)->addNewRequest(Synchronization::NEW_GAME_SESSION, info);
    }

#ifdef _WIN32
	//Let the lan broadcaster know, how many players are currently on the server and what is the servers size
	//_broadcastThread = new std::thread(broadcastThreadFunction, _serverPort);
#endif

	//LanBroadcast::instance().setCurrentPlayerCount(1);
	//LanBroadcast::instance().setServerSize(32);

    addVehicles(eventData[P_GAME_SETTINGS_SLED_COUNT].GetInt(), eventData[P_GAME_SETTINGS_CAR_COUNT].GetInt());
    //addHumans();

    if (!headless) {
        Node* start = _scene->GetChild("startNode", true);
        Light* light = start->GetComponent<Light>();
        light->SetShadowCascade(CascadeParameters(10.0f, 50.0f, 200.0f, 0.0f, 0.8f));
        _player = _scene->GetComponent<Players>()->createPlayer(true);
        _player->getControlledNode()->SetPosition(_terrain->GetNode()->GetWorldRotation() * start->GetWorldPosition());
        _player->setName("Server player");
        _player->setHealth(100);
        if (eventData[P_GAME_SETTINGS_START_VEHICLE].GetInt() == 0) {
            Sled* sled = _scene->GetComponent<Usables>()->getNearestSled(_player->getControlledNode()->GetPosition());
            if (sled) {
                _player->enterDriveableObject(sled);
            }
            else {
                NewVehicle* vehicle = _scene->GetComponent<Usables>()->getNearestVehicle(_player->getControlledNode()->GetPosition());
                if (vehicle) {
                    _player->enterDriveableObject(vehicle);
                }

            }
        }
        else {
            NewVehicle* vehicle = _scene->GetComponent<Usables>()->getNearestVehicle(_player->getControlledNode()->GetPosition());
            if (vehicle) {
                _player->enterDriveableObject(vehicle);
            }
            else {
                Sled* sled = _scene->GetComponent<Usables>()->getNearestSled(_player->getControlledNode()->GetPosition());
                if (sled) {
                    _player->enterDriveableObject(sled);
                }
            }
        }
        _playerId = _player->GetID();
        VariantMap map;
        map[P_PLAYER_ID] = _playerId;
        SendEvent(E_SET_PLAYER_ID, map);
        map[P_PLAYER_NODE_PTR] = _player->getControlledNode();
        if (eventData[P_GAME_SETTINGS_AI_FOLLOW].GetBool()) {
            SendEvent(E_AI_SET_TARGET_NODE, map);
            //SendEvent(E_AI_REMOVE_TARGET_NODE, map);
        }
    }
	SendEvent(E_GAME_COUNTDOWN_START);
}

bool GameSession::JoinServer(String address, String port)
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();
	Network* network = GetSubsystem<Network>();

	if (address.Empty()) {
		address = "localhost"; // Use localhost to connect if nothing else specified
	}

	//Convert port string to unsigned short
	unsigned short portValue = (unsigned short) strtoul(port.CString(), NULL, 0);

	//Player identity information
	VariantMap map;
	map[P_PLAYER_NAME] = "Client";

	// Connect to server, specify scene to use as a client for replication
	if (network->Connect(address, portValue, _scene, map)) {
		Node* terrain = _scene->GetChild("terrainNode", true);
		_terrain = terrain->GetComponent<Terrain>();
		return true;
	}
	else {
		//URHO3D_LOGERRORF("Failed to connect to server %d:%d!", address, portValue);
		return false;
	}
}

void GameSession::HandleClientConnected(StringHash eventType, VariantMap& eventData)
{
	using namespace ClientConnected;
	Connection* sender = static_cast<Connection*>(eventData[P_CONNECTION].GetPtr());

	// When a client connects, assign to scene to begin scene replication
	Connection* newConnection = static_cast<Connection*>(eventData[P_CONNECTION].GetPtr());
	newConnection->SetScene(_scene);

	//Also let our LAN broadcaster know, that we have more players in this server
	const Vector<SharedPtr<Connection> >& connections = GetSubsystem<Network>()->GetClientConnections();
	//LanBroadcast::instance().setCurrentPlayerCount(connections.Size() + 1);
}

void GameSession::HandleClientDisconnected(StringHash eventType, VariantMap& eventData)
{
	using namespace ClientDisconnected;
	Connection* sender = static_cast<Connection*>(eventData[P_CONNECTION].GetPtr());
	//Find player information for the client, who is disconnecting
	if (!_clientPlayers[sender]) {
		return;
	}
	auto player = _clientPlayers[sender];
	_scene->GetComponent<Players>()->removePlayer(player->GetID());

	_clientPlayers.Erase(sender);
	//Let the lan broadcaster know, that there are less servers now on the server
	const Vector<SharedPtr<Connection> >& connections = GetSubsystem<Network>()->GetClientConnections();
	LanBroadcast::instance().setCurrentPlayerCount(connections.Size());
}

void GameSession::HandleUpdate(StringHash eventType, VariantMap& eventData)
{
	float timeStep = eventData[Update::P_TIMESTEP].GetFloat();

	Input* input = GetSubsystem<Input>();

    if (!GetSubsystem<Graphics>()) {
        return;
    }

    bool touchInput = false;
    for (unsigned i = 0; i < input->GetNumTouches(); ++i)
    {
        TouchState* state = input->GetTouch(i);
        if (!state->touchedElement_)    // Touch on empty space
        {
            if (state->delta_.x_ || state->delta_.y_)
            {
                touchInput = true;
                Graphics* graphics = GetSubsystem<Graphics>();
                _yaw += TOUCH_SENSITIVITY * _cameraController->getCamera()->GetFov() / graphics->GetHeight() * state->delta_.x_;
                _pitch += TOUCH_SENSITIVITY * _cameraController->getCamera()->GetFov() / graphics->GetHeight() * state->delta_.y_;

                // Construct new orientation for the camera scene node from yaw and pitch; roll is fixed to zero
            }
        }
    }

    if (GetSubsystem<Console>()->IsVisible()) {
        //Disable any actions while console is visible
        _controls.Set(PLAYER_FORWARD, false);
        _controls.Set(PLAYER_BACK, false);
        _controls.Set(PLAYER_LEFT, false);
        _controls.Set(PLAYER_RIGHT, false);
        _controls.Set(PLAYER_USE, false);
        _controls.Set(PLAYER_RESET, false);
        _controls.Set(PLAYER_SPRINT, false);
        _controls.Set(PLAYER_CAMERA, false);
        _controls.Set(PLAYER_JUMP, false);
    }
    else {
        const float MOUSE_SENSITIVITY = 0.1f;
        // Use this frame's mouse motion to adjust camera node yaw and pitch. Clamp the pitch between -90 and 90 degrees
        IntVector2 mouseMove = input->GetMouseMove();

        if (!touchInput) {
            _yaw += MOUSE_SENSITIVITY*mouseMove.x_;
            _pitch += MOUSE_SENSITIVITY*mouseMove.y_;
        }
        _pitch = Clamp(_pitch, -90.0f, 90.0f);

        _controls.yaw_ = _yaw;
        _controls.pitch_ = _pitch;

        _controls.Set(PLAYER_FORWARD, input->GetKeyDown(KEY_W));
        _controls.Set(PLAYER_BACK, input->GetKeyDown(KEY_S));
        _controls.Set(PLAYER_LEFT, input->GetKeyDown(KEY_A));
        _controls.Set(PLAYER_RIGHT, input->GetKeyDown(KEY_D));
        _controls.Set(PLAYER_USE, input->GetKeyDown(KEY_E));
        _controls.Set(PLAYER_RESET, input->GetKeyDown(KEY_R));
        _controls.Set(PLAYER_SPRINT, input->GetQualifierDown(1));
        _controls.Set(PLAYER_CAMERA, input->GetKeyDown(KEY_V));
        _controls.Set(PLAYER_JUMP, input->GetKeyDown(KEY_SPACE));

        if (input->GetKeyPress(KEY_TAB)) {
            SendEvent(E_TOGGLE_SCORE);
        }
    }

	/*if (input->GetKeyPress(KEY_J)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("Vibrance", true);
		_viewport->SetRenderPath(effectRenderPath);
	}
	if (input->GetKeyPress(KEY_U)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("Vibrance", false);
		_viewport->SetRenderPath(effectRenderPath);
	}

	if (input->GetKeyPress(KEY_K)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("GammaCorrection", true);
		_viewport->SetRenderPath(effectRenderPath);
	}
	if (input->GetKeyPress(KEY_I)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("GammaCorrection", false);
		_viewport->SetRenderPath(effectRenderPath);
	}

	if (input->GetKeyPress(KEY_L)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("Bloom", true);
		_viewport->SetRenderPath(effectRenderPath);
	}
	if (input->GetKeyPress(KEY_O)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("Bloom", false);
		_viewport->SetRenderPath(effectRenderPath);
	}

	if (input->GetKeyPress(KEY_H)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("Toon", true);
		_viewport->SetRenderPath(effectRenderPath);
	}
	if (input->GetKeyPress(KEY_Y)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("Toon", false);
		_viewport->SetRenderPath(effectRenderPath);
	}

	if (input->GetKeyPress(KEY_G)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("FXAA3", true);
		_viewport->SetRenderPath(effectRenderPath);
	}
	if (input->GetKeyPress(KEY_T)) {
		SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
		effectRenderPath->SetEnabled("FXAA3", false);
		_viewport->SetRenderPath(effectRenderPath);
	}*/

	if (_cameraController) {
		_cameraController->setControls(_controls);
	}
}

void GameSession::HandlePostUpdate(StringHash eventType, VariantMap& eventData)
{
    const float timeStep = eventData[PostUpdate::P_TIMESTEP].GetFloat();

	if (_cameraController) {
		if (_player) {
			if (_player->getCameraNode()) {
				_cameraController->setTarget(_player->getCameraNode());
			}
		}
		_cameraController->PostUpdate(timeStep);
		//updateWater();
	}

	if (_player) {
		if (_player->getControlledNode()) {
		}
		else {
			_player->setControlledNode(_scene->GetNode(_playerId));
		}
	}
}

void GameSession::HandleNetworkMessage(StringHash eventType, VariantMap& eventData)
{
	Network* network = GetSubsystem<Network>();

	using namespace NetworkMessage;

	Connection* sender = static_cast<Connection*>(eventData[P_CONNECTION].GetPtr());

	int msgID = eventData[P_MESSAGEID].GetInt();
	if (msgID == MESSAGE_PING_REQUEST) {
		//Server sent client a ping request, we should respond with a blank message
		VectorBuffer msg;
		sender->SendMessage(MESSAGE_PING_RESPONSE, false, false, msg);
	}
	else if (msgID == MESSAGE_PING_RESPONSE) {
		//Client sent back ping response, calculate how much time it took to receive this information
		_clientPlayers[sender]->setPing(Time::GetSystemTime() - _clientPlayers[sender]->getPingRequestTime());
	}
}

void GameSession::HandleClientIdentity(StringHash eventType, VariantMap& eventData)
{
	using namespace ClientIdentity;
	Connection* sender = static_cast<Connection*>(eventData[P_CONNECTION].GetPtr());

	OnePlayer* player = _scene->GetComponent<Players>()->createPlayer(true);
	player->setName(eventData[P_PLAYER_NAME].GetString());
	player->setHealth(100);
	player->getControlledNode()->SetOwner(sender);

	Node* playerNode = player->getControlledNode();

	//Set which player is linked to this client connectionse
	_clientPlayers[sender] = player;

    //Send client his node ID
	VariantMap map;
    //In this case we need to send the Node ID as a player ID
    //So the client can  query the scene and find the node he's controlling
	map[P_PLAYER_ID] = player->getControlledNode()->GetID();
    player->setPlayerConnection(sender);
    _scene->GetComponent<Usables>()->sendOutPredictedNodes();
	sender->SendRemoteEvent(E_CLIENT_ID, true, map);
}

void GameSession::HandleServerConnected(StringHash eventType, VariantMap& eventData)
{
	Network* network = GetSubsystem<Network>();
	Connection* serverConnection = network->GetServerConnection();

	VectorBuffer msg;
	String name("Arnis");
	msg.WriteString(name);
	serverConnection->SendMessage(MESSAGE_INTRODUCTION, true, true, msg);
}


void GameSession::HandlePhysicsPreStep(StringHash eventType, VariantMap& eventData)
{
	Network* network = GetSubsystem<Network>();
	Connection* serverConnection = network->GetServerConnection();

    Input* input = GetSubsystem<Input>();
    UI* ui = GetSubsystem<UI>();
	
	if (network->IsServerRunning()) {

		const Vector<SharedPtr<Connection> >& connections = network->GetClientConnections();
		for (unsigned i = 0; i < connections.Size(); ++i) {
			Connection* connection = connections[i];
			if (!_clientPlayers[connection]) {
				continue;
			}
			_clientPlayers[connection]->setControls(connection->GetControls());
		}

		if (_cameraController && _cameraController->isFreelookMode()) {
			//send empty controls to player
			_player->setControls(Controls());
		}
		else {
			if (_player) {
				_player->setControls(_controls);
			}
		}
	} else if (serverConnection) {

			//Check if none of the ui elements are focused and the mouse is free to use
			if (!ui->GetFocusElement()) {
				//Send server our controls
				if (_cameraController && _cameraController->isFreelookMode()) {
					//send empty controls to server
					serverConnection->SetControls(Controls());
				}
				else {
					serverConnection->SetControls(_controls);
				}

			}

		}

}

void GameSession::HandleRetrieveClientId(StringHash eventType, VariantMap& eventData)
{
    if (eventType == E_CLIENT_ID) {
        //Get the Node ID which the player is controlling
        _playerId = static_cast<unsigned short>(eventData[P_PLAYER_ID].GetUInt());
        URHO3D_LOGDEBUGF("Retrieved client id %d", _playerId);

        if (_scene && _scene->HasComponent<Players>()) {
            _player = _scene->GetComponent<Players>()->createPlayer(false, _playerId);
            VariantMap map;
            map[P_PLAYER_ID] = _playerId;
            SendEvent(E_SET_PLAYER_ID, map);
        }
    }
    else if (E_CLIENT_NODE_CHANGED) {
        if (!GetSubsystem<Network>()->IsServerRunning()) {
            unsigned int playerId = static_cast<unsigned short>(eventData[P_PLAYER_ID].GetUInt());
            unsigned int nodeID = static_cast<unsigned short>(eventData[P_PLAYER_NODE_ID].GetUInt());

            Node* n = _scene->GetNode(nodeID);
            VariantMap map;
            map[P_PLAYER_ID] = _playerId;
            SendEvent(E_SET_PLAYER_ID, map);
            if (n) {
                _player->setCameraNode(n);
            }
        }
    }
}

void GameSession::drawAimRay(float yaw, float pitch, Node* node)
{
	//This will draw 3D line to show where the player is aiming
	Quaternion rotation3D(pitch, yaw, 0.0f);
	DebugRenderer* debug = _scene->GetComponent<DebugRenderer>();
	debug->AddLine(node->GetPosition(), node->GetPosition() + rotation3D * Vector3::FORWARD * 100, Color(1, 1, 1));
}

void GameSession::cleanup()
{
	_scene->GetComponent<Players>()->cleanup();
	_scene->RemoveComponent<Players>();
    _scene->RemoveComponent<Trees>();
	_scene->GetComponent<Usables>()->destroyAllSleds();
	_scene->GetComponent<Usables>()->destroyAllVehicles();
	_scene->RemoveComponent<Usables>();
	_scene->RemoveComponent<Gui>();
	_scene->RemoveComponent<CameraController>();
	_scene->Remove();
}

void GameSession::HandlePhysicsChanged(StringHash eventType, VariantMap& eventData)
{
	if (!_scene) return;

	if (eventType == E_PHYSICS_STEP_CHANGED) {
		_scene->GetComponent<PhysicsWorld>()->SetFps(eventData[P_VALUE].GetInt());
		URHO3D_LOGINFO("Physics step changed to " + String(_scene->GetComponent<PhysicsWorld>()->GetFps()));
	}
	else if (eventType == E_PHYSICS_SUBSTEP_CHANGED) {
		_scene->GetComponent<PhysicsWorld>()->SetMaxSubSteps(eventData[P_VALUE].GetInt());
		URHO3D_LOGINFO("Physics substep changed to " + String(_scene->GetComponent<PhysicsWorld>()->GetFps()));
	}
	else if (eventType == E_DRAW_PHYSICS) {
		_drawPhysics = (eventData[P_VALUE].GetInt() > 0) ? true : false;
		URHO3D_LOGINFO("Physics draw changed to " + String(_drawPhysics));
	}
	else if (eventType == E_PHYSICS_GRAVITY) {
		Vector3 gravity = eventData[P_VALUE].GetVector3();
		_scene->GetComponent<PhysicsWorld>()->SetGravity(gravity);
		URHO3D_LOGINFO("Gravity changed to  " + String(gravity.y_));
	}
}

void GameSession::HandleNodePrediction(StringHash eventType, VariantMap& eventData)
{
    unsigned int nodeId = eventData[P_NODE_ID].GetUInt();
    if (_scene) {
        Node* predictNode = _scene->GetNode(nodeId);
        if (predictNode) {
          // predictNode->SetInterceptNetworkUpdate("Network Position", true);
        }
    }
}

void GameSession::HandleSubmitScore(StringHash eventType, VariantMap& eventData)
{
    if (_network) {
        String name = eventData[P_PLAYER_NAME].GetString();
        unsigned int vehicleType = eventData[P_VEHICLE_TYPE].GetUInt();
        String vehicleTypeName = (vehicleType == 0) ? "sled" : "car";
        (*_network)->addNewRequest(Synchronization::RequestType::LATEST_VERSION);
        float racetime = eventData[P_RACE_TIME].GetFloat();
        int racetimeConverted = racetime * 1000;
        unsigned int checkpoints = eventData[P_CHECKPOINT_COUNT].GetUInt();

        Synchronization::RequestInfo info;
        info.addPostVariable("nickname", name);
        info.addPostVariable("version", VERSION);
        info.addPostVariable("vehicle_type", vehicleTypeName);
        info.addPostVariable("bot_vehicles", String(_vehicleCount));
        info.addPostVariable("bot_sleds", String(_sledCount));
        info.addPostVariable("racetime", String(racetimeConverted));
        info.addPostVariable("checkpoints", String(checkpoints));
        (*_network)->addNewRequest(Synchronization::RequestType::SUBMIT_SCORE, info);
    }
}

void GameSession::InitTouchInput()
{

    ResourceCache* cache = GetSubsystem<ResourceCache>();
    Input* input = GetSubsystem<Input>();
    XMLFile* layout = cache->GetResource<XMLFile>("UI/ScreenJoystick_Samples.xml");
    const String& patchString = "<patch> \
            <remove sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]/attribute[@name='Is Visible']\" />\
            <replace sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]/element[./attribute[@name='Name' and @value='Label']]/attribute[@name='Text']/@value\">RESET</replace>\
            <add sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]\">\
                <element type=\"Text\">\
                    <attribute name=\"Name\" value=\"KeyBinding\" />\
                    <attribute name=\"Text\" value=\"R\" />\
                </element>\
            </add>\
        </patch>";

    if (!patchString.Empty())
    {
        // Patch the screen joystick layout further on demand
        SharedPtr<XMLFile> patchFile(new XMLFile(context_));
        if (patchFile->FromString(patchString))
            layout->Patch(patchFile);
    }
    unsigned screenJoystickIndex_ = (unsigned)input->AddScreenJoystick(layout, cache->GetResource<XMLFile>("UI/DefaultStyle.xml"));
    unsigned screenJoystickSettingsIndex_ = M_MAX_UNSIGNED;
    input->SetScreenJoystickVisible(screenJoystickSettingsIndex_, true);
}