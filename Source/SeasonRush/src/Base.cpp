#include <Urho3D/Urho3DAll.h>
#include "Base.h"
#include "DebugDraw.h"
#include "MainMenu.h"
#include "Console/ConsoleCommandController.h"
#include "Network/NetworkRequests.h"
#include "Config/Config.h"
#include "Events.h"
#include <fstream>
#include <iostream>
#include "version.h"
#include <iostream>

using namespace std;

Base::Base(Context * context) :
Application(context),
_debugElements(true),
_cameraYaw(0)
{
	DebugDraw::RegisterObject(context);
	MainMenu::RegisterObject(context);
	GameSession::RegisterObject(context);
	ConsoleCommandController::RegisterObject(context);
	Synchronization::NetworkRequests::RegisterObject(context);
	Splash::RegisterObject(context);
}

Base::~Base()
{
    Config::instance().write();
}

void Base::Setup()
{
    engineParameters_["Headless"] = Config::instance().getConfig().headless;
	engineParameters_["FullScreen"] = Config::instance().getConfig().fullscreen;
	engineParameters_["WindowWidth"] = Config::instance().getConfig().width;
	engineParameters_["WindowHeight"] = Config::instance().getConfig().height;
	engineParameters_["WindowResizable"] = false;
	engineParameters_["WindowTitle"] = "Season Rush";
	engineParameters_["Borderless"] = false;
	engineParameters_["TextureQuality"] = 2;
	engineParameters_["Multisample"] = 1;
	engineParameters_["VSync"] = false;
	engineParameters_["FrameLimiter"] = true;
	engineParameters_["TripleBuffer"] = false;
    engineParameters_["LogLevel"] = LOG_DEBUG;
    engineParameters_["Sound"] = true;
    engineParameters_["WindowIcon"] = "Data/Textures/christmas/game_icon.ico";

    if (Config::instance().getConfig().headless) {
        OpenConsoleWindow();
        URHO3D_LOGINFOF("Server version %s", VERSION);
    }
    else {
        URHO3D_LOGINFOF("Current version %s", VERSION);
    }
}

void Base::Start()
{
	//Disable timestamps in console logs
	GetSubsystem<Log>()->SetTimeStamp(false);

	_scene = new Scene(context_);

    //Subscribe to basic events
    subscribe();

    _network = new Synchronization::NetworkRequests(context_);

#ifdef SKIP_SPLASH_SCREEN
	startMenu(E_SPLASHSCREEN_END, VariantMap());
    VariantMap map;
    map[P_GAME_SETTINGS_START_VEHICLE] = 1;
    map[P_GAME_SETTINGS_CAR_COUNT] = 50;
    map[P_GAME_SETTINGS_SLED_COUNT] = 50;
    map[P_GAME_SETTINGS_AI_FOLLOW] = 0;
    SendEvent(E_GAME_NEW, map);
#else
    if (engineParameters_["Headless"].GetBool()) {
        VariantMap map;
        map[P_GAME_SETTINGS_START_VEHICLE] = 1;
        map[P_GAME_SETTINGS_CAR_COUNT] = 1;
        map[P_GAME_SETTINGS_SLED_COUNT] = 1;
        map[P_GAME_SETTINGS_AI_FOLLOW] = 0;
        SendEvent(E_GAME_NEW, map);
    }
    else {
        // Let's setup a scene to render.
        _splash = _scene->CreateComponent<Splash>();
        _splash->show();
        SubscribeToEvent(E_SPLASHSCREEN_END, URHO3D_HANDLER(Base, startMenu));
    }
#endif

}

void Base::startMenu(StringHash eventType, VariantMap& eventData)
{
#ifndef SKIP_SPLASH_SCREEN
	_scene->RemoveComponent<Splash>();
#endif // ! SKIP_FLASH_SCREEN

    GetSubsystem<Input>()->SetMouseVisible(true);
    GetSubsystem<Input>()->SetMouseGrabbed(true);

	ResourceCache* cache = GetSubsystem<ResourceCache>();
	GetSubsystem<UI>()->GetRoot()->SetDefaultStyle(cache->GetResource<XMLFile>("UI/DefaultStyle.xml"));

	XMLFile* sceneFile = cache->GetResource<XMLFile>("Scenes/Menu.xml");
	_scene->LoadXML(sceneFile->GetRoot());

	createBackgroundImage();

	_scene->CreateComponent<MainMenu>();
    if (_scene->HasComponent<MainMenu>()) {
        _scene->GetComponent<MainMenu>()->draw();
    }

	//Create camera
	_cameraNode = _scene->CreateChild("Camera", LOCAL);
	Camera* camera = _cameraNode->CreateComponent<Camera>(LOCAL);
	_cameraNode->SetPosition(Vector3(20, 20, 20));
	_cameraNode->LookAt(Vector3(0, 0, 0));
	camera->SetFarClip(1000);

	Renderer* renderer = GetSubsystem<Renderer>();
    if (renderer) {
        _viewport = new Viewport(context_, _scene, _cameraNode->GetComponent<Camera>());
        SharedPtr<RenderPath> effectRenderPath = _viewport->GetRenderPath()->Clone();
        effectRenderPath->Append(cache->GetResource<XMLFile>("PostProcess/AutoExposure.xml"));
        effectRenderPath->Append(cache->GetResource<XMLFile>("PostProcess/BloomHDR.xml"));
        //effectRenderPath->Append(cache->GetResource<XMLFile>("PostProcess/Blur.xml"));
        // Make the bloom mixing parameter more pronounced
        //effectRenderPath->SetShaderParameter("AutoExposureAdaptRate", 0.1);
        effectRenderPath->SetEnabled("AutoExposure", true);
        effectRenderPath->SetEnabled("BloomHDR", true);
        //effectRenderPath->SetEnabled("Blur", true);
        _viewport->SetRenderPath(effectRenderPath);

        renderer->SetViewport(0, _viewport);
    }

	if (_debugElements) {
		createDebugElements();
	}

	// Create console
    _console = engine_->CreateConsole();
    if (_console) {
        _console->GetCloseButton()->SetVisible(false);
        _console->SetCommandInterpreter("Console");
        _console->SetDefaultStyle(cache->GetResource<XMLFile>("UI/DefaultStyle.xml"));
        _console->GetBackground()->SetOpacity(0.8f);
        _console->SetNumRows(GetSubsystem<Graphics>()->GetHeight() / 28);
        _console->SetNumBufferedRows(10 * _console->GetNumRows());
        _console->SetCommandInterpreter(GetTypeName());
        _console->SetVisible(false);
    }

    /**
    * Create console command controller
    */
    _consoleCommandController = new ConsoleCommandController(context_);

    parseCommandLineFile();

}

void Base::createBackgroundImage()
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();
	UI* ui = GetSubsystem<UI>();
    Graphics* graphics = GetSubsystem<Graphics>();
    if (graphics) {
        _backgroundImage = new BorderImage(context_);
        //backgroundImage->SetName("Splash");
        Texture2D* texture = cache->GetResource<Texture2D>("Textures/christmas/background.jpg");
        _backgroundImage->SetTexture(texture); // Set texture
        _backgroundImage->SetBlendMode(BlendMode::BLEND_ALPHA);
        _backgroundImage->SetSize(graphics->GetWidth(), graphics->GetHeight());
        _backgroundImage->SetAlignment(HA_CENTER, VA_CENTER);
        _backgroundImage->SetFullImageRect();
        _backgroundImage->SetBringToBack(true);
        ui->GetRoot()->AddChild(_backgroundImage);
        //GetSubsystem<Engine>()->RunFrame(); // Render Splash immediately

        // Get rendering window size as floats
        float width = (float)graphics->GetWidth();
        float height = (float)graphics->GetHeight();

        Texture2D* snowflakeTexture = cache->GetResource<Texture2D>("Textures/christmas/snowflake.png");
        for (int i = 0; i < 100; i++) {
            Sprite* sprite = new Sprite(context_);
            sprite->SetTexture(snowflakeTexture);
            sprite->SetPosition(Random() * width, Random() * height);
            sprite->SetSize(IntVector2(30, 30));
            sprite->SetRotation(Random() * 360.0f);
            sprite->SetScale(Random(1.0f) + 0.5f);
            sprite->SetBlendMode(BLEND_ADD);
            sprite->SetVar(SNOWFLAKE_SPEED, Vector2(5.0f + Random(10.0f), 10.0f + Random(30.0f)));
            _backgroundImage->AddChild(sprite);
            _snowflakes.Push(SharedPtr<Sprite>(sprite));
        }
    }
}

void Base::moveSnowflakes(float timestep)
{
	Graphics* graphics = GetSubsystem<Graphics>();
    if (!graphics) {
        return;
    }

	float width = (float)graphics->GetWidth();
	float height = (float)graphics->GetHeight();

	// Go through all sprites
	for (unsigned i = 0; i < _snowflakes.Size(); ++i)
	{
		Sprite* sprite = _snowflakes[i];

		// Rotate
		float newRot = sprite->GetRotation() + timestep * 10.0f;
		sprite->SetRotation(newRot);

		// Move, wrap around rendering window edges
		Vector2 newPos = sprite->GetPosition() + sprite->GetVar(SNOWFLAKE_SPEED).GetVector2() * timestep;
		float border = 40;
		if (newPos.x_ < -border)
			newPos.x_ = width + border;
		if (newPos.x_ >= width + border)
			newPos.x_ = -border;
		if (newPos.y_ < -border)
			newPos.y_ = height + border;
		if (newPos.y_ >= height + border)
			newPos.y_ = -border;
		sprite->SetPosition(newPos);
	}
}

void Base::parseCommandLineFile()
{
    if (!_consoleCommandController) {
        return;
    }

    URHO3D_LOGINFO("Reading and running commands defined in Data/Commands.txt");

    using namespace std;
    ifstream file;
    string line;
    file.open("Data/Commands.txt");
    if (file.is_open()) {
        while (getline(file, line)) {
            _consoleCommandController->parse(String(line.c_str()));
        }
        file.close();
    }
}

void Base::toggleBackgroundImage(bool val)
{
    if (GetSubsystem<Graphics>()) {
        _backgroundImage->SetVisible(val);
        _backgroundImage->SetBringToBack(true);
    }
}

void Base::Stop()
{

}

void Base::HandleKeyUp(StringHash eventType, VariantMap& eventData)
{
	using namespace KeyDown;
	int key = eventData[P_KEY].GetInt();

	/*if (key == KEY_ESC) {
		engine_->Exit();
	}*/

	//console key
	if (key == 96 && _console) {
		//Console stuff
		_console->Toggle();
		_console->GetLineEdit()->SetText("");
		_console->GetCloseButton()->SetVisible(false);
		_console->SetCommandInterpreter("Application");
	}

    if (key == KEY_PRINTSCREEN) {
        Graphics* graphics = GetSubsystem<Graphics>();
        Image screenshot(context_);
        graphics->TakeScreenShot(screenshot);
        // Here we save in the Data folder with date and time appended
        screenshot.SavePNG(GetSubsystem<FileSystem>()->GetProgramDir() + "Data/Screenshot_" +
            Time::GetTimeStamp().Replaced(':', '_').Replaced('.', '_').Replaced(' ', '_') + ".png");
    }
}

void Base::HandlePostUpdate(StringHash eventType, VariantMap& eventData)
{
	float timeStep = eventData[PostUpdate::P_TIMESTEP].GetFloat();
	_cameraYaw += timeStep * 10;  // Rotate camera N degrees each second
	/// Create a offset
	Quaternion q = Quaternion(_cameraYaw, Vector3::UP);   // Construct rotation
	Vector3 cameraOffset(30, -15, 30);  // Camera offset relative to target node
	Vector3 cameraPosition = Vector3(32, 84, -70) - (q * cameraOffset);  // New rotated camera position with whatever offset you want

    if (_cameraNode) {
        _cameraNode->SetPosition(cameraPosition);  // Set new camera position and lookat values
        _cameraNode->LookAt(Vector3(32, 84, -70));
        //_cameraNode->LookAt(Vector3(0, 0, 0));
    }

	moveSnowflakes(timeStep);
}

void Base::subscribe()
{
	SubscribeToEvent(E_KEYUP, URHO3D_HANDLER(Base, HandleKeyUp));

    SubscribeToEvent(E_BROADCAST_STEER, URHO3D_HANDLER(Base, HandleRemoteSteer));
    SubscribeToEvent(E_BROADCAST_NEW_VERSION, URHO3D_HANDLER(Base, HandleNewerVersion));

	//Our game events
	SubscribeToEvent(E_GAME_EXIT, URHO3D_HANDLER(Base, HandleGameEvents));
	SubscribeToEvent(E_GAME_NEW, URHO3D_HANDLER(Base, HandleGameEvents));
	SubscribeToEvent(E_GAME_STOP, URHO3D_HANDLER(Base, HandleGameEvents));
	SubscribeToEvent(E_GAME_JOIN, URHO3D_HANDLER(Base, HandleGameEvents));

	SubscribeToEvent(E_CONSOLECOMMAND, URHO3D_HANDLER(Base, HandleConsoleCommand));

	SubscribeToEvent(E_POSTUPDATE, URHO3D_HANDLER(Base, HandlePostUpdate));

	//Register to network response events
	SubscribeToEvent(E_HTTP_RESPONSE, URHO3D_HANDLER(Base, HandleHttpResponse));

	//Register to debug level changes
	SubscribeToEvent(E_DEBUG_TOGGLE, URHO3D_HANDLER(Base, HandleDebugLevel));

    SubscribeToEvent(E_GRAPHICS_CHANGED, URHO3D_HANDLER(Base, HandleGraphicsChanged));

    SubscribeToEvent(E_LOAD_LEADERBOARD, URHO3D_HANDLER(Base, HandleRetrieveLeaderboard));
}

void Base::createDebugElements()
{
	DebugDraw* debugDrawer = _scene->CreateComponent<DebugDraw>();
	debugDrawer->showVersion();
}

void Base::HandleGameEvents(StringHash eventType, VariantMap& eventData)
{
	if (eventType == E_GAME_NEW || eventType == E_GAME_JOIN) {
		toggleBackgroundImage(false);
		//New game button pressed
		_session = new GameSession(context_);
		_session->setNetworkRequestHandler(&_network);
        if (_scene->HasComponent<MainMenu>()) {
            _scene->GetComponent<MainMenu>()->show(false);
        }
        eventData[P_SERVER_HEADLESS] = engineParameters_["Headless"].GetBool();
		_session->HandleGameEvents(eventType, eventData);
	}
	else if (eventType == E_GAME_EXIT) {
		engine_->Exit();
	}
	else if (eventType == E_GAME_STOP) {
		if (_console && _console->IsVisible()) {
			_console->Toggle();
		}
		if (_session) {
			_session->cleanup();
			_session = nullptr;
		}
		toggleBackgroundImage(true);
        if (_scene->HasComponent<MainMenu>()) {
            _scene->GetComponent<MainMenu>()->show(true);
        }

        GetSubsystem<Input>()->SetMouseGrabbed(false);
        GetSubsystem<Input>()->SetMouseVisible(true);

		Renderer* renderer = GetSubsystem<Renderer>();
        if (renderer) {
            renderer->SetViewport(0, _viewport);
        }
	}
}

void Base::HandleConsoleCommand(StringHash eventType, VariantMap& eventData)
{
	using namespace ConsoleCommand;
	if (eventData[ConsoleCommand::P_ID].GetString() == GetTypeName()) {
		//Let our console command controller deal with this message
		_consoleCommandController->parse(eventData[P_COMMAND].GetString());
	}
}

void Base::HandleHttpResponse(StringHash eventType, VariantMap& eventData)
{
	using namespace Synchronization;
	RequestType type = (RequestType) eventData[P_REQUEST_TYPE].GetInt();
	switch (type) {
	case RequestType::LATEST_VERSION:
		if (_scene->HasComponent<DebugDraw>()) {
			_scene->GetComponent<DebugDraw>()->showLatestVersionAvailable(eventData[P_REQUEST_VALUE].GetString());
		}
		break;
	case RequestType::SERVER_LIST:
		break;
	}
}

void Base::HandleDebugLevel(StringHash eventType, VariantMap& eventData)
{
	int level = eventData[P_DEBUG_LEVEL].GetInt();

	//Make sure that the debug hud is created
	if (level > 0 && !_debugHud) {
		ResourceCache* cache = GetSubsystem<ResourceCache>();
		//Create debug view
		XMLFile* debugXmlFile = cache->GetResource<XMLFile>("UI/DefaultStyle.xml");
		_debugHud = engine_->CreateDebugHud();
		_debugHud->SetDefaultStyle(debugXmlFile);
		//dh->SetMode(DEBUGHUD_SHOW_ALL);
		_debugHud->SetMode(DEBUGHUD_SHOW_STATS);
	}

	if (_debugHud) {
		switch (level) {
		case 0:
			_debugHud->SetMode(DEBUGHUD_SHOW_NONE);
			break;
		case 1:
			_debugHud->SetMode(DEBUGHUD_SHOW_PROFILER);
			break;
		case 2:
			_debugHud->SetMode(DEBUGHUD_SHOW_STATS);
			break;
		case 3:
			_debugHud->SetMode(DEBUGHUD_SHOW_ALL);
			break;
		}
	}
}


void Base::HandleGraphicsChanged(StringHash eventType, VariantMap& eventData)
{
    _backgroundImage->SetSize(GetSubsystem<Graphics>()->GetWidth(), GetSubsystem<Graphics>()->GetHeight());
}

void Base::HandleRetrieveLeaderboard(StringHash eventType, VariantMap& eventData)
{
    if (_network) {
        _network->addNewRequest(Synchronization::RequestType::LEADERBOARD);
    }
}

void Base::HandleRemoteSteer(StringHash eventType, VariantMap& eventData)
{
    String dir = eventData[P_VALUE].GetString();
    URHO3D_LOGINFO("Remote steer detected! " + dir);
}

void Base::HandleNewerVersion(StringHash eventType, VariantMap& eventData)
{
    String ver = eventData[P_VALUE].GetString();
    URHO3D_LOGINFO("Newer game version available! " + ver);
    if (!_scene->HasComponent<DebugDraw>()) {
        DebugDraw* debugDrawer = _scene->CreateComponent<DebugDraw>();
    }
    _scene->GetComponent<DebugDraw>()->showLatestVersionAvailable(ver);
}