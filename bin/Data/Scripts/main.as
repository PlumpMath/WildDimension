// Common sample initialization as a framework for all samples.
//    - Set custom window title and icon;
//    - Create Console and Debug HUD, and use F1 and F2 key to toggle them;
//    - Toggle rendering options from the keys 1-8;
//    - Take screenshots with key 9;
//    - Handle Esc key down to hide Console or exit application;
//    - Init touch input on mobile platform using screen joysticks (patched for each individual sample)

#include "Helpers/gui_scale.as"
#include "Console/console.as"
#include "Network/network.as"

#include "GUI/gui.as"
#include "GUI/finish.as"

#include "Player/player.as"
#include "Pacman/pacman.as"
#include "Snake/snake.as"

#include "Tree/apple_tree.as"
#include "Tree/raspberry_bush.as"

#include "Clouds/clouds.as"

#include "Tools/Axe.as"
#include "Tools/Trap.as"
#include "Tools/ActiveTool.as"
#include "Tools/pickable.as"
#include "Tools/inventory.as"
#include "Tools/flag.as"
#include "Tools/crafting.as"
#include "Tools/tent.as"
#include "Tools/campfire.as"
#include "Tools/lighter.as"
#include "Tools/torch.as"

#include "Sounds/sounds.as"
#include "Camp/camp.as"

#include "Achievements/achievements.as"
#include "Achievements/axe.as"
#include "Achievements/trap.as"
#include "Achievements/hit.as"
#include "Achievements/branch.as"
#include "Achievements/places.as"

#include "Missions/missions.as"

#include "Screens/splash.as"
#include "Screens/menu.as"

#include "EnvironmentObjects/env_objects.as"

#include "Places/places.as"

#include "Spawn/spawn.as"

#include "GUI/pause.as"

const String VERSION_NUMBER = "0.1.0";
Text@ versionText;

Scene@ scene_;
uint screenJoystickIndex = M_MAX_UNSIGNED; // Screen joystick index for navigational controls (mobile platforms only)
uint screenJoystickSettingsIndex = M_MAX_UNSIGNED; // Screen joystick index for settings (mobile platforms only)
bool touchEnabled = false; // Flag to indicate whether touch input has been enabled
bool paused = false; // Pause flag
bool drawDebug = false; // Draw debug geometry flag
Node@ cameraNode; // Camera scene node
float yaw = 0.0f; // Camera yaw angle
float pitch = 0.0f; // Camera pitch angle
const float TOUCH_SENSITIVITY = 2;
MouseMode useMouseMode_ = MM_ABSOLUTE;
Camera@ camera;
const float YAW_SENSITIVITY = 0.1f;
int currentBlur = 0;

const uint COLLISION_TERRAIN_LEVEL = 1;
const uint COLLISION_PACMAN_LEVEL = 2;
const uint COLLISION_SNAKE_HEAD_LEVEL = 4;
const uint COLLISION_SNAKE_BODY_LEVEL = 8;
const uint COLLISION_PLAYER_LEVEL = 16;
const uint COLLISION_PICKABLE_LEVEL = 32;
const uint COLLISION_FOOD_LEVEL = 64;
const uint COLLISION_TREE_LEVEL = 128;
const uint COLLISION_STATIC_OBJECTS = 256;

const uint VIEW_MASK_STATIC_OBJECT = 1;
const uint VIEW_MASK_INTERACTABLE = 2;

const float JOYSTICK_DEAD_ZONE = 0.3f;

const int DISTANCE_FACTOR = 500;

bool isMobilePlatform = false;
Controls oldControls;

Viewport@ viewport;
const uint GAME_STATE_MENU = 0;
const uint GAME_STATE_GAME = 1;
const uint GAME_STATE_PAUSE = 2;

uint gameState = GAME_STATE_MENU;

void Start()
{
    versionText = ui.root.CreateChild("Text");
    versionText = ui.root.CreateChild("Text");
    versionText.text = "v" + VERSION_NUMBER;
    versionText.color = Color(0.2, 0.9, 0.2);
    versionText.SetFont(cache.GetResource("Font", "Fonts/BlueHighway.ttf"), 10);
    versionText.textAlignment = HA_CENTER; // Center rows in relation to each other

    // Position the text relative to the screen center
    versionText.horizontalAlignment = HA_LEFT;
    versionText.verticalAlignment = VA_TOP;
    versionText.SetPosition(10, 0);

    //graphics.SetMode(graphics.desktopResolution[0].x, graphics.desktopResolution[0].y, true, false, false, false, false, false, graphics.multiSample, 0, 60);
    
    cache.autoReloadResources = true;

    XMLFile@ uiStyle = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    // Set style to the UI root so that elements will inherit it
    ui.root.defaultStyle = uiStyle;

    // Set custom window Title & Icon
    SetWindowTitleAndIcon();

    // Create console and debug HUD
    CreateDebugHud();
    
    ConsoleHandler::CreateConsole();
    ConsoleHandler::Subscribe();

    PauseMenuGUI::Init();

    // Subscribe key down event
    SubscribeToEvent("KeyDown", "HandleKeyDown");

    SubscribeToEvent("ResumeGame", "HandleResumeGame");

    // Subscribe key up event
    SubscribeToEvent("KeyUp", "HandleKeyUp");

    // Subscribe scene update event
    SubscribeToEvent("SceneUpdate", "HandleSceneUpdate");

    SubscribeToEvent("ReloadAll", "HandleReload");
    SubscribeToEvent("Exit", "HandleExit");

    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
    SubscribeToEvent("ToggleDebugDraw", "HandleToggleDebugDraw");

    SubscribeToEvent("SplashScreenEnd", "HandleSplashScreenEnd");
    SubscribeToEvent("NewGame", "HandleNewGame");

    if (engine.headless) {
        NetworkHandler::StartServer();
    } else {
        SplashScreen::CreateSplashScreen();
    }
}

void RegisterConsoleCommands()
{
    VariantMap data;
    data["CONSOLE_COMMAND_NAME"] = "reload";
    data["CONSOLE_COMMAND_EVENT"] = "ReloadAll";
    SendEvent("ConsoleCommandAdd", data);

    data["CONSOLE_COMMAND_NAME"] = "exit";
    data["CONSOLE_COMMAND_EVENT"] = "Exit";
    SendEvent("ConsoleCommandAdd", data);

    data["CONSOLE_COMMAND_NAME"] = "physics_draw";
    data["CONSOLE_COMMAND_EVENT"] = "ToggleDebugDraw";
    SendEvent("ConsoleCommandAdd", data);
}

void HandleExit(StringHash eventType, VariantMap& eventData)
{
    engine.Exit();
}

void HandleSplashScreenEnd(StringHash eventType, VariantMap& eventData)
{
    MenuScreen::CreateScreen();
}

void HandleNewGame(StringHash eventType, VariantMap& eventData)
{
    if (GetPlatform() == "Android" || GetPlatform() == "iOS" || input.touchEmulation) {
        // On mobile platform, enable touch by adding a screen joystick
        isMobilePlatform = true;
        gameController.CreateController();
    } else if (input.numJoysticks == 0) {
        // On desktop platform, do not detect touch when we already got a joystick
        //SubscribeToEvent("TouchBegin", "HandleTouchBegin");
    }

    SubscribeToEvent("PostUpdate", "HandlePostUpdate");
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("PhysicsPreStep", "HandlePhysicsPreStep");

    FinishGUI::Subscribe();
    FinishGUI::RegisterConsoleCommands();

    NetworkHandler::Subscribe();

    CreateScene();
    SetupViewport();

    GUIHandler::CreateGUI();
    Player::CreatePlayer();

    Achievements::Init();
    Achievements::Subscribe();
    Achievements::RegisterConsoleCommands();

    Craft::Init();

    RegisterConsoleCommands();

    Missions::Init();
}

void HandleToggleDebugDraw(StringHash eventType, VariantMap& eventData)
{
    drawDebug = !drawDebug;
}

void Stop()
{
    if (versionText !is null) {
        versionText.Remove();
    }
    cache.ReleaseAllResources();
    NetworkHandler::StopServer();
    NetworkHandler::Destroy();
    ConsoleHandler::Destroy();
    GUIHandler::Destroy();
    SplashScreen::Destroy();
    MenuScreen::Destroy();
    FinishGUI::Destroy();
    PauseMenuGUI::Destroy();
    scene_.Remove();
}

void CreateScene()
{
    scene_ = Scene();

    scene_.CreateComponent("DebugRenderer", LOCAL);
    //PhysicsWorld2D@ physicsWorld = scene_.CreateComponent("PhysicsWorld2D");

    // Create the Octree component to the scene. This is required before adding any drawable components, or else nothing will
    // show up. The default octree volume will be from (-1000, -1000, -1000) to (1000, 1000, 1000) in world coordinates; it
    // is also legal to place objects outside the volume but their visibility can then not be checked in a hierarchically
    // optimizing manner
    scene_.CreateComponent("Octree", LOCAL);

    //physicsWorld2D.DrawDebugGeometry(scene_.GetComponent("DebugRenderer"), true);    

    if (engine.headless) {
        return;
    }
    // Create a scene node for the camera, which we will move around
    // The camera will use default settings (1000 far clip distance, 45 degrees FOV, set aspect ratio automatically)

    NetworkHandler::LoadScene();

    cameraNode = scene_.CreateChild("Camera", LOCAL);
    cameraNode.temporary = true;

    camera = cameraNode.CreateComponent("Camera", LOCAL);
    camera.orthographic = false;
    camera.fov = 60;
    camera.nearClip = 0.1f;
    camera.farClip = 1000;
    camera.orthoSize = graphics.height * PIXEL_SIZE;
    camera.zoom = 1.0f * Min(graphics.width / 1280.0f, graphics.height / 800.0f); // Set zoom according to user's resolution to ensure full visibility (initial zoom (1.5) is set for full visibility at 1280x800 resolution)
    camera.lodBias = 1.0f;

    SoundListener@ listener = cameraNode.CreateComponent("SoundListener");
    audio.listener = listener;

    NetworkHandler::StartServer();

    gameState = GAME_STATE_GAME;

}

void SetupViewport()
{
    if (engine.headless) {
        return;
    }
    // Set up a viewport to the Renderer subsystem so that the 3D scene can be seen. We need to define the scene and the camera
    // at minimum. Additionally we could configure the viewport screen size and the rendering path (eg. forward / deferred) to
    // use, but now we just use full screen and default render path configured in the engine command line options
    viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;

    RenderPath@ effectRenderPath = viewport.renderPath.Clone();
    effectRenderPath.Append(cache.GetResource("XMLFile", "PostProcess/Bloom.xml"));
    effectRenderPath.Append(cache.GetResource("XMLFile", "PostProcess/FXAA2.xml"));
    effectRenderPath.Append(cache.GetResource("XMLFile", "PostProcess/Blur.xml"));
    //effectRenderPath.Append(cache.GetResource("XMLFile", "PostProcess/AutoExposure.xml"));
    // Make the bloom mixing parameter more pronounced
    effectRenderPath.shaderParameters["BloomMix"] = Variant(Vector2(1.0f, 0.5f));
    effectRenderPath.SetEnabled("Bloom", true);
    effectRenderPath.SetEnabled("FXAA2", true);
    effectRenderPath.SetEnabled("Blur", false);
    //effectRenderPath.SetEnabled("AutoExposure", true);
    viewport.renderPath = effectRenderPath;
}

void AddBlur()
{
    currentBlur++;
    RenderPath@ effectRenderPath = viewport.renderPath.Clone();
    effectRenderPath.SetEnabled("Blur", true);
    viewport.renderPath = effectRenderPath;

    Array<Variant> parameters;
    parameters.Push(Variant(currentBlur));
    DelayedExecute(5.0, false, "void StopBlur(int)", parameters);
}

void StopBlur(int blurNum)
{
    if (blurNum != currentBlur) {
        return;
    }
    RenderPath@ effectRenderPath = viewport.renderPath.Clone();
    effectRenderPath.SetEnabled("Blur", false);
    viewport.renderPath = effectRenderPath;
}

void HandleReload(StringHash eventType, VariantMap& eventData)
{
    Stop();
    Start();
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    //input.mouseVisible = true;
    if (isMobilePlatform == false) {
        yaw += input.mouseMoveX * YAW_SENSITIVITY;
        pitch += input.mouseMoveY * YAW_SENSITIVITY;
        pitch = Clamp(pitch, -90.0f, 90.0f);
    }

    GUIHandler::HandleUpdate(eventType, eventData);
    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();
    NetworkHandler::HandlePostUpdate(eventType, eventData);

    if (isMobilePlatform) {
        Controls controls;
        gameController.UpdateControlInputs(controls);
        Variant rStick = controls.extraData["VAR_AXIS_1"];
        Variant lStick = controls.extraData["VAR_AXIS_0"];
        //Player::playerControls.Set(Player::CTRL_JUMP, input.keyDown[KEY_SPACE]);
        uint BA = 1 << 0;
        //log.Info("AAA " + input.keyDown[KEY_SPACE]);
        //log.Info("A " + controls.IsDown(BA) + "; B " + controls.IsDown(1 << 2) + "; X " + controls.IsDown(1 << 3) + "; Y" + controls.IsDown(BUTTON_Y));
        if (lStick.empty == false) {
            Player::playerControls.Set(Player::CTRL_FORWARD, false);
            Player::playerControls.Set(Player::CTRL_BACK, false);
            Player::playerControls.Set(Player::CTRL_LEFT, false);
            Player::playerControls.Set(Player::CTRL_RIGHT, false);
            Vector2 axisInput = lStick.GetVector2();
            if (axisInput.x < 0) {
                Player::playerControls.Set(Player::CTRL_LEFT, true);
            } else if (axisInput.x > 0) {
                Player::playerControls.Set(Player::CTRL_RIGHT, true);
            }
            if (axisInput.y < 0) {
                Player::playerControls.Set(Player::CTRL_FORWARD, true);
            } else if (axisInput.y > 0) {
                Player::playerControls.Set(Player::CTRL_BACK, true);
            }
            //log.Info(axisInput.x + ":" + axisInput.y);
        }
        if (rStick.empty == false) {
            float YAW_SENSITIVITY = 100.0f * timeStep;
            float PITCH_SENSITIVITY = 100.0f * timeStep;
            Vector2 axisInput = rStick.GetVector2();
            if (Abs(axisInput.x) > JOYSTICK_DEAD_ZONE) {
                yaw += axisInput.x * YAW_SENSITIVITY;
            }
            if (Abs(axisInput.y) > JOYSTICK_DEAD_ZONE) {
                pitch += axisInput.y * PITCH_SENSITIVITY;
            }
        }
        oldControls = controls;
    }
}

void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();
    UpdateCamera(timeStep);
}

void UpdateCamera(float timeStep)
{
    if (gameState == GAME_STATE_PAUSE) {
        return;
    }
    /*if (camera !is null) {
        //yaw += TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.x;
        //yaw += timeStep * 10;s
       // pitch += TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.y;

        // Construct new orientation for the camera scene node from yaw and pitch; roll is fixed to zero
        /*cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);
        Vector3 position = Quaternion(pitch, yaw, 0.0f) * Vector3::FORWARD * timeStep * 30 + cameraNode.position;
        if (NetworkHandler::terrain !is null) {
            position.y = NetworkHandler::terrain.GetHeight(position) + 5.0f;
        }
        //cameraNode.position = position;
        yaw += input.mouseMoveX * YAW_SENSITIVITY;
        pitch += input.mouseMoveY * YAW_SENSITIVITY;
    }*/
    if (NetworkHandler::stats.finished) {
        Player::playerNode.AddChild(cameraNode);
        cameraNode.position = Vector3::BACK * 20 + Vector3::UP * 20;
        cameraNode.LookAt(Player::playerNode.position);
        Player::playerNode.Yaw(timeStep * 10);
    } else if (Player::playerNode !is null) {
        //cameraNode.rotation = Player::playerNode.rotation;
        cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);
        Vector3 position = Player::playerNode.position;
        position.y += 1;
        cameraNode.position = position;
    }
}

void SetWindowTitleAndIcon()
{
    if (engine.headless) {
        return;
    }

    Image@ icon = cache.GetResource("Image", "Textures/UrhoIcon.png");
    graphics.windowIcon = icon;
    graphics.windowTitle = "Main.as";
}

void CreateDebugHud()
{
    if (engine.headless) {
        return;
    }
    // Get default style
    XMLFile@ xmlFile = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    if (xmlFile is null)
        return;
    
    // Create debug HUD
    DebugHud@ debugHud = engine.CreateDebugHud();
    debugHud.defaultStyle = xmlFile;
}

void HandleKeyUp(StringHash eventType, VariantMap& eventData)
{
    Player::HandleKeyUp(eventType, eventData);
    int key = eventData["Key"].GetInt();

    // Close console (if open) or exit when ESC is pressed
    if (key == KEY_ESCAPE)
    {
        if (console.visible)
            console.visible = false;
        else
        {
            if (GetPlatform() == "Web")
            {
                input.mouseVisible = true;
                if (useMouseMode_ != MM_ABSOLUTE)
                    input.mouseMode = MM_FREE;
            }
            else {
                if (gameState == GAME_STATE_GAME) {
                    SendEvent("TogglePause");
                    gameState = GAME_STATE_PAUSE;
                    scene_.timeScale = 0;
                } else if (gameState == GAME_STATE_PAUSE) {
                    SendEvent("TogglePause");
                    gameState = GAME_STATE_GAME;
                    scene_.timeScale = 1.0;
                }
            }
        }
    }
}

void HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
    Player::HandleKeyDown(eventType, eventData);
    int key = eventData["Key"].GetInt();
        
    // Toggle debug HUD with F2
    if (key == KEY_F2)
        debugHud.ToggleAll();

    // Common rendering quality controls, only when UI has no focused element
    else if (ui.focusElement is null)
    {
        // Preferences / Pause
        if (key == KEY_SELECT && touchEnabled)
        {
            paused = !paused;

            if (screenJoystickSettingsIndex == M_MAX_UNSIGNED)
            {
                // Lazy initialization
                screenJoystickSettingsIndex = input.AddScreenJoystick(cache.GetResource("XMLFile", "UI/ScreenJoystickSettings_Samples.xml"), cache.GetResource("XMLFile", "UI/DefaultStyle.xml"));
            }
            else
                input.screenJoystickVisible[screenJoystickSettingsIndex] = paused;
        }

        // Texture quality
        /*else if (key == '1')
        {
            int quality = renderer.textureQuality;
            ++quality;
            if (quality > QUALITY_HIGH)
                quality = QUALITY_LOW;
            renderer.textureQuality = quality;
        }*/

        // Material quality
        else if (key == '2')
        {
            int quality = renderer.materialQuality;
            ++quality;
            if (quality > QUALITY_HIGH)
                quality = QUALITY_LOW;
            renderer.materialQuality = quality;
        }

        // Specular lighting
        else if (key == '3')
            renderer.specularLighting = !renderer.specularLighting;

        // Shadow rendering
        else if (key == '4')
            renderer.drawShadows = !renderer.drawShadows;

        // Shadow map resolution
        else if (key == '5')
        {
            int shadowMapSize = renderer.shadowMapSize;
            shadowMapSize *= 2;
            if (shadowMapSize > 2048)
                shadowMapSize = 512;
            renderer.shadowMapSize = shadowMapSize;
        }

        // Shadow depth and filtering quality
        else if (key == '6')
        {
            ShadowQuality quality = renderer.shadowQuality;
            quality = ShadowQuality(quality + 1);
            if (quality > SHADOWQUALITY_BLUR_VSM)
                quality = SHADOWQUALITY_SIMPLE_16BIT;
            renderer.shadowQuality = quality;
        }

        // Occlusion culling
        else if (key == '7')
        {
            bool occlusion = renderer.maxOccluderTriangles > 0;
            occlusion = !occlusion;
            renderer.maxOccluderTriangles = occlusion ? 5000 : 0;
        }

        // Instancing
        else if (key == '8')
            renderer.dynamicInstancing = !renderer.dynamicInstancing;

        // Take screenshot
        else if (key == '9')
        {
            Image@ screenshot = Image();
            graphics.TakeScreenShot(screenshot);
            // Here we save in the Data folder with date and time appended
            screenshot.SavePNG(fileSystem.programDir + "Data/Screenshot_" +
                time.timeStamp.Replaced(':', '_').Replaced('.', '_').Replaced(' ', '_') + ".png");
        }
    }
    ConsoleHandler::HandleKeys(key);
}

void HandleSceneUpdate(StringHash eventType, VariantMap& eventData)
{
    if (gameState == GAME_STATE_PAUSE) {
        return;
    }

    // Move the camera by touch, if the camera node is initialized by descendant sample class
    if (touchEnabled && cameraNode !is null)
    {
        for (uint i = 0; i < input.numTouches; ++i)
        {
            TouchState@ state = input.touches[i];
            if (state.touchedElement is null) // Touch on empty space
            {
                if (state.delta.x !=0 || state.delta.y !=0)
                {
                    Camera@ camera = cameraNode.GetComponent("Camera");
                    if (camera is null)
                        return;

                    //yaw += TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.x;
                    //pitch += TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.y;

                    // Construct new orientation for the camera scene node from yaw and pitch; roll is fixed to zero
                    cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);
                }
                else
                {
                    // Move the cursor to the touch position
                    Cursor@ cursor = ui.cursor;
                    if (cursor !is null && cursor.visible)
                        cursor.position = state.position;
                }
            }
        }
    }
}

void HandleTouchBegin(StringHash eventType, VariantMap& eventData)
{
    // On some platforms like Windows the presence of touch input can only be detected dynamically
    UnsubscribeFromEvent("TouchBegin");
}

void HandleResumeGame(StringHash eventType, VariantMap& eventData)
{
    gameState = GAME_STATE_GAME;
    scene_.timeScale = 1.0;
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    // If draw debug mode is enabled, draw physics debug geometry. Use depth test to make the result easier to interpret
    // Note the convenience accessor to the physics world component
    if (drawDebug) {
        scene_.physicsWorld.DrawDebugGeometry(true);
    }
}

void HandlePhysicsPreStep(StringHash eventType, VariantMap& eventData)
{
    NetworkHandler::HandlePhysicsPreStep(eventType, eventData);
}
