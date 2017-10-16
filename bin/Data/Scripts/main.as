// Urho2D sprite example.
// This sample demonstrates:
//     - Creating a 2D scene with spriter animation
//     - Displaying the scene using the Renderer subsystem
//     - Handling keyboard to move and zoom 2D camera

#include "Scripts/Utilities/Sample.as"
#include "Scripts/Character/Character.as"

Node@ spriterNode;
Node@ spriterNode2;
Text@ instructionText;
int spriterAnimationIndex = 0;
// UDP port we will use
const uint SERVER_PORT = 2345;

void Start()
{
    // Execute the common startup for samples
    SampleStart();

    // Create the scene content
    CreateScene();

    // Create the UI content
    CreateInstructions();

    // Setup the viewport for displaying the scene
    SetupViewport();

    // Set the mouse mode to use in the sample
    SampleInitMouseMode(MM_FREE);

    // Hook up to the frame update events
    SubscribeToEvents();

    DelayedExecute(1.0, false, "void Trigger()");

    StartServer();
}

void Stop()
{
    spriterNode.Remove();
    instructionText.Remove();
    Disconnect();
}

void CreateScene()
{
    scene_ = Scene();

    scene_.CreateComponent("DebugRenderer");
    PhysicsWorld2D@ physicsWorld = scene_.CreateComponent("PhysicsWorld2D");

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

    Sprite2D@ boxSprite = cache.GetResource("Sprite2D", "Urho2D/Box.png");
    Sprite2D@ ballSprite = cache.GetResource("Sprite2D", "Urho2D/Ball.png");

    // Create ground.
    Node@ groundNode = scene_.CreateChild("Ground");
    groundNode.position = Vector3(0.0f, -1.4f, 0.0f);
    groundNode.scale = Vector3(200.0f, 1.0f, 0.0f);

    // Create 2D rigid body for gound
    RigidBody2D@ groundBody = groundNode.CreateComponent("RigidBody2D");

    StaticSprite2D@ groundSprite = groundNode.CreateComponent("StaticSprite2D");
    groundSprite.sprite = boxSprite;

    // Create box collider for ground
    CollisionBox2D@ groundShape = groundNode.CreateComponent("CollisionBox2D");
    // Set box size
    groundShape.size = Vector2(0.32f, 0.32f);
    // Set friction
    groundShape.friction = 0.5f;

    const uint NUM_OBJECTS = 100;
    for (uint i = 0; i < NUM_OBJECTS; ++i)
    {
        Node@ node  = scene_.CreateChild("RigidBody");
        node.position = Vector3(Random(-0.1f, 0.1f), 5.0f + i * 0.4f, 0.0f);

        // Create rigid body
        RigidBody2D@ body = node.CreateComponent("RigidBody2D");
        body.bodyType = BT_DYNAMIC;
        body.allowSleep = false;

        StaticSprite2D@ staticSprite = node.CreateComponent("StaticSprite2D");

        if (i % 2 == 0)
        {
            staticSprite.sprite = boxSprite;

            // Create box
            CollisionBox2D@ box = node.CreateComponent("CollisionBox2D");
            // Set size
            box.size = Vector2(0.32f, 0.32f);
            // Set density
            box.density = 1.0f;
            // Set friction
            box.friction = 0.5f;
            // Set restitution
            box.restitution = 0.1f;
        }
        else
        {
            staticSprite.sprite = ballSprite;

            // Create circle
            CollisionCircle2D@ circle = node.CreateComponent("CollisionCircle2D");
            // Set radius
            circle.radius = 0.16f;
            // Set density
            circle.density = 1.0f;
            // Set friction.
            circle.friction = 0.5f;
            // Set restitution
            circle.restitution = 0.1f;
        }
    }

}

void CreateInstructions()
{
    // Construct new Text object, set string to display and font to use
    instructionText = ui.root.CreateChild("Text");
    instructionText.text = "Use A/D to move!";
    instructionText.SetFont(cache.GetResource("Font", "Fonts/Anonymous Pro.ttf"), 15);
    instructionText.textAlignment = HA_CENTER; // Center rows in relation to each other

    // Position the text relative to the screen center
    instructionText.horizontalAlignment = HA_CENTER;
    instructionText.verticalAlignment = VA_CENTER;
    instructionText.SetPosition(0, ui.root.height / 4);
}

void SetupViewport()
{
    // Set up a viewport to the Renderer subsystem so that the 3D scene can be seen. We need to define the scene and the camera
    // at minimum. Additionally we could configure the viewport screen size and the rendering path (eg. forward / deferred) to
    // use, but now we just use full screen and default render path configured in the engine command line options
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;
}

void MoveCamera(float timeStep)
{
    // Do not move if the UI has a focused element (the console)
    if (ui.focusElement !is null)
        return;

    // Movement speed as world units per second
    const float MOVE_SPEED = 4.0f;

    if (input.keyDown[KEY_N]) {
        StartServer();
    }
    if (input.keyDown[KEY_J]) {
        Connect();
    }


    if (input.keyDown[KEY_PAGEUP])
    {
        Camera@ camera = cameraNode.GetComponent("Camera");
        camera.zoom = camera.zoom * 1.01f;
    }

    if (input.keyDown[KEY_PAGEDOWN])
    {
        Camera@ camera = cameraNode.GetComponent("Camera");
        camera.zoom = camera.zoom * 0.99f;
    }

    if (input.keyPress[KEY_P]) 
        drawDebug = !drawDebug; // Toggle debug geometry with space
}

void SubscribeToEvents()
{
    // Subscribe HandleUpdate() function for processing update events
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("MouseButtonDown", "HandleMouseButtonDown");

    // Unsubscribe the SceneUpdate event from base class to prevent camera pitch and yaw in 2D sample
    UnsubscribeFromEvent("SceneUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();

    // Move the camera, scale movement with time step
    MoveCamera(timeStep);
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    if (!drawDebug)
        return;
    // If draw debug mode is enabled, draw viewport debug geometry, which will show eg. drawable bounding boxes and skeleton
    // bones. Note that debug geometry has to be separately requested each frame. Disable depth test so that we can see the
    // bones properly
    // if (drawDebug)a
    PhysicsWorld2D@ physicsWorld = scene_.GetComponent("PhysicsWorld2D");
    renderer.DrawDebugGeometry(true);
    physicsWorld.DrawDebugGeometry();
}

void HandleMouseButtonDown(StringHash eventType, VariantMap& eventData)
{
    // if (spriterAnimatedSprite !is null) {
    //     spriterAnimationSet = spriterAnimatedSprite.animationSet;
    //     spriterAnimationIndex = (spriterAnimationIndex + 1) % spriterAnimationSet.numAnimations;
    //     spriterAnimatedSprite.SetAnimation(spriterAnimationSet.GetAnimation(spriterAnimationIndex), LM_FORCE_LOOPED);
    // }
}

void StartServer()
{
    if (network.serverRunning) {
        return;
    }

    spriterNode = scene_.CreateChild("Character", REPLICATED);

    spriterNode.CreateScriptObject(scriptFile, "Character");
    network.StartServer(SERVER_PORT);
}

void Connect()
{   
    String address = "127.0.0.1";
    if (address.empty)
        address = "localhost"; // Use localhost to connect if nothing else specified

    // Connect to server, specify scene to use as a client for replication
    //clientObjectID = 0; // Reset own object ID from possible previous connection
    network.Connect(address, SERVER_PORT, scene_);
}

void Disconnect()
{
    Connection@ serverConnection = network.serverConnection;
    // If we were connected to server, disconnect. Or if we were running a server, stop it. In both cases clear the
    // scene of all replicated content, but let the local nodes & components (the static world + camera) stay
    if (serverConnection !is null)
    {
        serverConnection.Disconnect();
        scene_.Clear(true, false);
        //clientObjectID = 0;
    }
    // Or if we were running a server, stop it
    else if (network.serverRunning)
    {
        network.StopServer();
        scene_.Clear(true, false);
    }

}


void Trigger()
{
    log.Info("Delayed:" + GetOSVersion());
    log.Info("Delayed:" + GetPlatform());
    //DelayedExecute(1.0, false, "void Trigger()");
}

// Create XML patch instructions for screen joystick layout specific to this sample app
String patchInstructions =
        "<patch>" +
        "    <remove sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]/attribute[@name='Is Visible']\" />" +
        "    <replace sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]/element[./attribute[@name='Name' and @value='Label']]/attribute[@name='Text']/@value\">Zoom In</replace>" +
        "    <add sel=\"/element/element[./attribute[@name='Name' and @value='Button0']]\">" +
        "        <element type=\"Text\">" +
        "            <attribute name=\"Name\" value=\"KeyBinding\" />" +
        "            <attribute name=\"Text\" value=\"PAGEUP\" />" +
        "        </element>" +
        "    </add>" +
        "    <remove sel=\"/element/element[./attribute[@name='Name' and @value='Button1']]/attribute[@name='Is Visible']\" />" +
        "    <replace sel=\"/element/element[./attribute[@name='Name' and @value='Button1']]/element[./attribute[@name='Name' and @value='Label']]/attribute[@name='Text']/@value\">Zoom Out</replace>" +
        "    <add sel=\"/element/element[./attribute[@name='Name' and @value='Button1']]\">" +
        "        <element type=\"Text\">" +
        "            <attribute name=\"Name\" value=\"KeyBinding\" />" +
        "            <attribute name=\"Text\" value=\"PAGEDOWN\" />" +
        "        </element>" +
        "    </add>" +
        "</patch>";
