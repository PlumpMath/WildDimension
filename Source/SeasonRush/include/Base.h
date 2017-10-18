#pragma once
#include <Urho3D/Engine/Application.h>
#include "Console/ConsoleCommandController.h"
#include "Network/NetworkRequests.h"
#include "Screens/Splash.h"
#include "GameSession.h"
#include <iostream>
#include "Events.h"

//#define SKIP_SPLASH_SCREEN

using namespace Urho3D;

static const StringHash SNOWFLAKE_SPEED("SnowflakeSpeed");

using namespace std;

class Base : public Application
{
private:
	/**
	 * Subscribe to the basic events
	 */
	void subscribe();

	/**
	 * Create debug elements
	 */
	void createDebugElements();

	/**
	 * Do we need to draw debug elements on the screen
	 */
	bool _debugElements;

	/**
	 * Scene for main menu
	 */
	SharedPtr<Scene> _scene;

	/**
	 * Viewport for main menu screen
	 */
	SharedPtr<Viewport> _viewport;

	/**
	 * Camera node
	 */
	SharedPtr<Node> _cameraNode;

	/**
	 * Pointer to console object
	 */
	SharedPtr<Console> _console;

	/**
	 * Class which will actually parse entered console commands
	 */
	SharedPtr<ConsoleCommandController> _consoleCommandController;

    /**
     * Network requests handler
     */
	Synchronization::NetworkRequests* _network;

	float _cameraYaw;

	/**
	 * Create version n
	 */
	void createVersionLabel();

	/**
	 * Main debug hud element
	 */
    SharedPtr<DebugHud> _debugHud;

    SharedPtr<Splash> _splash;

	SharedPtr<GameSession> _session;

	void createBackgroundImage();

	void toggleBackgroundImage(bool val);

	SharedPtr<BorderImage> _backgroundImage;

	Vector<SharedPtr<Sprite>> _snowflakes;

	void moveSnowflakes(float timestep);

    /**
     * Run commands listed in Data/Commands.txt file
     */
    void parseCommandLineFile();

public:
	Base(Context * context);
	~Base();

	virtual void Setup();
	virtual void Start();
	virtual void Stop();

	void startMenu(StringHash eventType, VariantMap& eventData);

	/**
	 * Triggered when keyboard key is released
	 */
	void HandleKeyUp(StringHash eventType, VariantMap& eventData);

	/**
	 * Handle our game events start, stop, exit
	 */
	void HandleGameEvents(StringHash eventType, VariantMap& eventData);

	/**
	 * Triggered when console command in entered
	 */
	void HandleConsoleCommand(StringHash eventType, VariantMap& eventData);

	/**
	* Handle update each frame
	*/
	void HandlePostUpdate(StringHash eventType, VariantMap& eventData);

	/**
	* Handle events which are sent when any of the http requests are done
	*/
	void HandleHttpResponse(StringHash eventType, VariantMap& eventData);

	/**
	* Handle debug level changes
	*/
	void HandleDebugLevel(StringHash eventType, VariantMap& eventData);

    void HandleGraphicsChanged(StringHash eventType, VariantMap& eventData);

    void HandleRetrieveLeaderboard(StringHash eventType, VariantMap& eventData);

    void HandleRemoteSteer(StringHash eventType, VariantMap& eventData);

    void HandleNewerVersion(StringHash eventType, VariantMap& eventData);
};
