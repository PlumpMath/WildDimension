// Common sample initialization as a framework for all samples.
//    - Set custom window title and icon;
//    - Create Console and Debug HUD, and use F1 and F2 key to toggle them;
//    - Toggle rendering options from the keys 1-8;
//    - Take screenshots with key 9;
//    - Handle Esc key down to hide Console or exit application;
//    - Init touch input on mobile platform using screen joysticks (patched for each individual sample)

#include "Console/console.as"

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

void Start()
{
    if (GetPlatform() == "Android" || GetPlatform() == "iOS" || input.touchEmulation)
        // On mobile platform, enable touch by adding a screen joystick
        InitTouchInput();
    else if (input.numJoysticks == 0)
        // On desktop platform, do not detect touch when we already got a joystick
        SubscribeToEvent("TouchBegin", "HandleTouchBegin");

    // Set custom window Title & Icon
    SetWindowTitleAndIcon();

    // Create console and debug HUD
    CreateDebugHud();
    
    ConsoleHandler::CreateConsole();

    // Subscribe key down event
    SubscribeToEvent("KeyDown", "HandleKeyDown");

    // Subscribe key up event
    SubscribeToEvent("KeyUp", "HandleKeyUp");

    // Subscribe scene update event
    SubscribeToEvent("SceneUpdate", "HandleSceneUpdate");

    ConsoleHandler::Subscribe();

    CreateScene();

    SetupViewport();
}

void CreateScene()
{
    scene_ = Scene();

    scene_.CreateComponent("DebugRenderer");
    //PhysicsWorld2D@ physicsWorld = scene_.CreateComponent("PhysicsWorld2D");


    // Create the Octree component to the scene. This is required before adding any drawable components, or else nothing will
    // show up. The default octree volume will be from (-1000, -1000, -1000) to (1000, 1000, 1000) in world coordinates; it
    // is also legal to place objects outside the volume but their visibility can then not be checked in a hierarchically
    // optimizing manner
    scene_.CreateComponent("Octree");

    //physicsWorld2D.DrawDebugGeometry(scene_.GetComponent("DebugRenderer"), true);    

    // Create a scene node for the camera, which we will move around
    // The camera will use default settings (1000 far clip distance, 45 degrees FOV, set aspect ratio automatically)
    cameraNode = scene_.CreateChild("Camera", LOCAL);
    // Set an initial position for the camera scene node above the plane
    cameraNode.position = Vector3(0.0f, 0.0f, -10.0f);

    Camera@ camera = cameraNode.CreateComponent("Camera", LOCAL);
    camera.orthographic = true;
    camera.orthoSize = graphics.height * PIXEL_SIZE;
    camera.zoom = 1.0f * Min(graphics.width / 1280.0f, graphics.height / 800.0f); // Set zoom according to user's resolution to ensure full visibility (initial zoom (1.5) is set for full visibility at 1280x800 resolution)

}

void SetupViewport()
{
    // Set up a viewport to the Renderer subsystem so that the 3D scene can be seen. We need to define the scene and the camera
    // at minimum. Additionally we could configure the viewport screen size and the rendering path (eg. forward / deferred) to
    // use, but now we just use full screen and default render path configured in the engine command line options
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;
}

void InitTouchInput()
{
    touchEnabled = true;

    XMLFile@ layout = cache.GetResource("XMLFile", "UI/ScreenJoystick_Samples.xml");
    if (!patchInstructions.empty)
    {
        // Patch the screen joystick layout further on demand
        XMLFile@ patchFile = XMLFile();
        if (patchFile.FromString(patchInstructions))
            layout.Patch(patchFile);
    }
    screenJoystickIndex = input.AddScreenJoystick(layout, cache.GetResource("XMLFile", "UI/DefaultStyle.xml"));
    input.screenJoystickVisible[0] = true;
}

void SampleInitMouseMode(MouseMode mode)
{
  useMouseMode_ = mode;

    if (GetPlatform() != "Web")
    {
      if (useMouseMode_ == MM_FREE)
          input.mouseVisible = true;

      if (useMouseMode_ != MM_ABSOLUTE)
      {
          input.mouseMode = useMouseMode_;
          if (console.visible)
              input.SetMouseMode(MM_ABSOLUTE, true);
      }
    }
    else
    {
        input.mouseVisible = true;
        SubscribeToEvent("MouseButtonDown", "HandleMouseModeRequest");
        SubscribeToEvent("MouseModeChanged", "HandleMouseModeChange");
    }
}

void SetWindowTitleAndIcon()
{
    Image@ icon = cache.GetResource("Image", "Textures/UrhoIcon.png");
    graphics.windowIcon = icon;
    graphics.windowTitle = "Main.as";
}

void CreateDebugHud()
{
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
            else
                engine.Exit();
        }
    }
}

void HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
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
        else if (key == '1')
        {
            int quality = renderer.textureQuality;
            ++quality;
            if (quality > QUALITY_HIGH)
                quality = QUALITY_LOW;
            renderer.textureQuality = quality;
        }

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

                    yaw += TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.x;
                    pitch += TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.y;

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
    InitTouchInput();
    UnsubscribeFromEvent("TouchBegin");
}

// If the user clicks the canvas, attempt to switch to relative mouse mode on web platform
void HandleMouseModeRequest(StringHash eventType, VariantMap& eventData)
{
    if (console !is null && console.visible)
        return;

    if (useMouseMode_ == MM_ABSOLUTE)
        input.mouseVisible = false;
    else if (useMouseMode_ == MM_FREE)
        input.mouseVisible = true;

    input.mouseMode = useMouseMode_;
}

void HandleMouseModeChange(StringHash eventType, VariantMap& eventData)
{
    bool mouseLocked = eventData["MouseLocked"].GetBool();
    input.SetMouseVisible(!mouseLocked);
}


// Create XML patch instructions for screen joystick layout specific to this sample app
String patchInstructions =
        "<patch>" +
        // "    <remove sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]/attribute[@name='Is Visible']\" />" +
        // "    <replace sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]/element[./attribute[@name='Name' and @value='Label']]/attribute[@name='Text']/@value\">Zoom In</replace>" +
        // "    <add sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]\">" +
        // "        <element type=\"Text\">" +
        // "            <attribute name=\"Name\" value=\"KeyBinding\" />" +
        // "            <attribute name=\"Text\" value=\"PAGEUP\" />" +
        // "        </element>" +
        // "    </add>" +
        // "    <remove sel=\"/element/element[./attribute[@name='Name' and @value='Button1']]/attribute[@name='Is Visible']\" />" +
        // "    <replace sel=\"/element/element[./attribute[@name='Name' and @value='Button1']]/element[./attribute[@name='Name' and @value='Label']]/attribute[@name='Text']/@value\">Zoom Out</replace>" +
        // "    <add sel=\"/element/element[./attribute[@name='Name' and @value='Button1']]\">" +
        // "        <element type=\"Text\">" +
        // "            <attribute name=\"Name\" value=\"KeyBinding\" />" +
        // "            <attribute name=\"Text\" value=\"PAGEDOWN\" />" +
        // "        </element>" +
        // "    </add>" +
        "    <remove sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]/attribute[@name='Is Visible']\" />" +
        "    <replace sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]/element[./attribute[@name='Name' and @value='Label']]/attribute[@name='Text']/@value\">JUMP</replace>" +
        "    <add sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]\">" +
        "        <element type=\"Text\">" +
        "            <attribute name=\"Name\" value=\"KeyBinding\" />" +
        "            <attribute name=\"Text\" value=\"SPACE\" />" +
        "        </element>" +
        "    </add>" +
        
        "</patch>";