// Urho2D sprite example.
// This sample demonstrates:
//     - Creating a 2D scene with spriter animation
//     - Displaying the scene using the Renderer subsystem
//     - Handling keyboard to move and zoom 2D camera

#include "Scripts/Utilities/Sample.as"
#include "Scripts/Character/Character.as"
#include "Scripts/Camera/Follow.as"

//String platform = GetPlatform();
//log.Info("Platform")
class Client
{
    //Connection@ connection;
    Node@ object;
}

Node@ controllerCharacterNode;
Text@ instructionText;
// UDP port we will use
const uint SERVER_PORT = 2345;
Array<Client@> clients;
uint clientObjectID = 0;

Text@ bytesIn;
Text@ bytesOut;

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

    DelayedExecute(3.0, false, "void StartServer()");

    //StartServer();
}

void Stop()
{
    if (controllerCharacterNode !is null) {
        controllerCharacterNode.Remove();
    }

    instructionText.Remove();
    bytesIn.Remove();
    bytesOut.Remove();
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


    bytesIn = ui.root.CreateChild("Text");
    bytesIn.text = "";
    bytesIn.SetFont(cache.GetResource("Font", "Fonts/Anonymous Pro.ttf"), 10);
    bytesIn.textAlignment = HA_CENTER; // Center rows in relation to each other

    // Position the text relative to the screen center
    bytesIn.horizontalAlignment = HA_LEFT;
    bytesIn.verticalAlignment = VA_BOTTOM;
    bytesIn.SetPosition(0, -10);

    bytesOut = ui.root.CreateChild("Text");
    bytesOut.text = "";
    bytesOut.SetFont(cache.GetResource("Font", "Fonts/Anonymous Pro.ttf"), 10);
    bytesOut.textAlignment = HA_CENTER; // Center rows in relation to each other

    // Position the text relative to the screen center
    bytesOut.horizontalAlignment = HA_LEFT;
    bytesOut.verticalAlignment = VA_BOTTOM;
    bytesOut.SetPosition(0, -20);
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

    SubscribeToEvent("ClientConnected", "HandleClientConnected");
    SubscribeToEvent("ClientDisconnected", "HandleClientDisconnected");
    //network.RegisterRemoteEvent("ClientObjectID");
    SubscribeToEvent("ClientObjectID", "HandleClientObjectID");

    // Subscribe to fixed timestep physics updates for setting or applying controls
    SubscribeToEvent("PhysicsPreStep", "HandlePhysicsPreStep");
}

void HandleClientConnected(StringHash eventType, VariantMap& eventData)
{
    // When a client connects, assign to scene to begin scene replication
    /*Connection@ newConnection = eventData["Connection"].GetPtr();
    newConnection.scene = scene_;

    Node@ node = CreateCharacter(false);
    Client newClient;
    newClient.connection = newConnection;
    newClient.object = node;
    clients.Push(newClient);

    // Finally send the object's node ID using a remote event
    VariantMap remoteEventData;
    remoteEventData["ID"] = node.id;
    newConnection.SendRemoteEvent("ClientObjectID", true, remoteEventData);
    */
}

void HandleClientDisconnected(StringHash eventType, VariantMap& eventData)
{
    /*
    // When a client disconnects, remove the controlled object
    Connection@ connection = eventData["Connection"].GetPtr();
    for (uint i = 0; i < clients.length; ++i)
    {
        if (clients[i].connection is connection)
        {
            log.Info("Deleting disconnected client character");
            clients[i].object.Remove();
            clients.Erase(i);
            break;
        }
    }
    */
}

void HandleClientObjectID(StringHash eventType, VariantMap& eventData)
{
    clientObjectID = eventData["ID"].GetUInt();
    log.Info("Client Object ID" + String(clientObjectID));
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    if (clientObjectID > 0 && controllerCharacterNode is null) {
        controllerCharacterNode = scene_.GetNode(clientObjectID);
    }

    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();

    // Move the camera, scale movement with time step
    MoveCamera(timeStep);

    if (controllerCharacterNode !is null) {
        FollowCharacter(cameraNode, controllerCharacterNode, timeStep);
    }

    /*Connection@ serverConnection = network.serverConnection;
    if (serverConnection !is null) {
        if (bytesIn !is null) {
            bytesIn.text = "KBytes In: " + String(serverConnection.bytesInPerSec / 1024);
        }
        if (bytesOut !is null) {
            bytesOut.text = "KBytes Out: " + String(serverConnection.bytesOutPerSec / 1024);
        }
    } else if (network.serverRunning) {
        float bIn;
        float bOut;
        bIn = 0;
        bOut = 0;
        for (uint i = 0; i < clients.length; ++i)
        {
            bIn += clients[i].connection.bytesInPerSec;
            bOut += clients[i].connection.bytesOutPerSec;
        }
        bIn /= 1024;
        bOut /= 1024;
        if (bytesIn !is null) {
            bytesIn.text = "KBytes In: " + String(bIn);
        }
        if (bytesOut !is null) {
            bytesOut.text = "KBytes Out: " + String(bOut);
        }
    }*/
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
    if (controllerCharacterNode is null) {
        return;
    }
    Sprite2D@ ballSprite = cache.GetResource("Sprite2D", "Urho2D/Ball.png");

    Node@ node  = scene_.CreateChild("RigidBody", REPLICATED);
    Vector3 pos = controllerCharacterNode.position;
    pos.y++;
    node.position = pos;

    // Create rigid body
    RigidBody2D@ body = node.CreateComponent("RigidBody2D", REPLICATED);
    body.bodyType = BT_DYNAMIC;
    body.angularDamping = 0.9f;
    body.mass = 100;
    //body.allowSleep = false;

    StaticSprite2D@ staticSprite = node.CreateComponent("StaticSprite2D", REPLICATED);
    staticSprite.sprite = ballSprite;

    // Create circle
    CollisionCircle2D@ circle = node.CreateComponent("CollisionCircle2D", REPLICATED);
    // Set radius
    circle.radius = 0.16f;
    // Set density
    circle.density = 1.0f;
    // Set friction.
    circle.friction = 0.5f;
    // Set restitution
    circle.restitution = 0.9f;
    // if (spriterAnimatedSprite !is null) {
    //     spriterAnimationSet = spriterAnimatedSprite.animationSet;
    //     spriterAnimationIndex = (spriterAnimationIndex + 1) % spriterAnimationSet.numAnimations;
    //     spriterAnimatedSprite.SetAnimation(spriterAnimationSet.GetAnimation(spriterAnimationIndex), LM_FORCE_LOOPED);
    // }
}

void StartServer()
{
    /*if (network.serverRunning) {
        return;
    }

    network.StartServer(SERVER_PORT);
    */
    CreateWorld();
    controllerCharacterNode = CreateCharacter(true);
}

Node@ CreateCharacter(bool local)
{
    Node@ node = scene_.CreateChild("Character", REPLICATED);
    Character@ character = cast<Character>(node.CreateScriptObject(scriptFile, "Character", LOCAL));
    character.SetNode(node);
    character.SetLocal(local);
    character.Init();
    return node;
}

void CreateWorld()
{

    Sprite2D@ boxSprite = cache.GetResource("Sprite2D", "Urho2D/Box.png");
    Sprite2D@ ballSprite = cache.GetResource("Sprite2D", "Urho2D/Ball.png");
    Sprite2D@ groundTexture = cache.GetResource("Sprite2D", "Urho2D/Ground.png");
    groundTexture.rectangle = IntRect(0, 0, 32, 32);
    
    float oneBoxSize = 0.32f * 1;
    for (int i = -500; i <= 500; ++i) {
        // Create ground.
        Node@ groundNode = scene_.CreateChild("Ground", REPLICATED);
        groundNode.position = Vector3(i * oneBoxSize, -3.4f + Abs(i) * Sin(Abs(i/50.0f)), 0.0f);
        groundNode.scale = Vector3(1.0f, 1.0f, 0.0f);

        // Create 2D rigid body for gound
        RigidBody2D@ groundBody = groundNode.CreateComponent("RigidBody2D", REPLICATED);

        StaticSprite2D@ groundSprite = groundNode.CreateComponent("StaticSprite2D", REPLICATED);
        groundSprite.sprite = groundTexture;

        // Create box collider for ground
        CollisionBox2D@ groundShape = groundNode.CreateComponent("CollisionBox2D", REPLICATED);
        // Set box size
        groundShape.size = Vector2(oneBoxSize, oneBoxSize);
        //groundShape.size = Vector2(1, 1);
        // Set friction
        groundShape.friction = 0.5f;
    }

    const uint NUM_OBJECTS = 50;
    for (uint i = 0; i < NUM_OBJECTS; ++i)
    {
        Node@ node  = scene_.CreateChild("RigidBody", REPLICATED);
        node.position = Vector3(Random(-2.0f, 2.0f), 5.0f + i * 0.1f, 0.0f);

        // Create rigid body
        RigidBody2D@ body = node.CreateComponent("RigidBody2D", REPLICATED);
        body.bodyType = BT_DYNAMIC;
        body.angularDamping = 0.9f;
        //body.allowSleep = false;

        StaticSprite2D@ staticSprite = node.CreateComponent("StaticSprite2D", REPLICATED);

        if (i % 2 == 0)
        {
            staticSprite.sprite = boxSprite;

            // Create box
            CollisionBox2D@ box = node.CreateComponent("CollisionBox2D", REPLICATED);
            // Set size
            box.size = Vector2(0.32f, 0.32f);
            // Set density
            box.density = 1.0f;
            // Set friction
            box.friction = 0.5f;
            // Set restitution
            box.restitution = 0.5f;
        }
        else
        {
            staticSprite.sprite = ballSprite;

            // Create circle
            CollisionCircle2D@ circle = node.CreateComponent("CollisionCircle2D", REPLICATED);
            // Set radius
            circle.radius = 0.16f;
            // Set density
            circle.density = 1.0f;
            // Set friction.
            circle.friction = 0.5f;
            // Set restitution
            circle.restitution = 0.7f;
        }
    }
}

void Connect()
{   
    Disconnect();
    String address = "127.0.0.1";
    if (address.empty)
        address = "localhost"; // Use localhost to connect if nothing else specified

    // Connect to server, specify scene to use as a client for replication
    //clientObjectID = 0; // Reset own object ID from possible previous connection
    //network.Connect(address, SERVER_PORT, scene_);
}

void Disconnect()
{
    /*Connection@ serverConnection = network.serverConnection;
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
        //scene_.Clear(true, false);
    }

    controllerCharacterNode = null;
    */

}

void HandlePhysicsPreStep(StringHash eventType, VariantMap& eventData)
{
    // This function is different on the client and server. The client collects controls (WASD controls + yaw angle)
    // and sets them to its server connection object, so that they will be sent to the server automatically at a
    // fixed rate, by default 30 FPS. The server will actually apply the controls (authoritative simulation.)
    //Connection@ serverConnection = network.serverConnection;

    Controls controls;

    // Copy mouse yaw
    //controls.yaw = yaw;

    // Only apply WASD controls if there is no focused UI element
    if (ui.focusElement is null)
    {
        controls.Set(CTRL_FORWARD, input.keyDown[KEY_W]);
        controls.Set(CTRL_BACK, input.keyDown[KEY_S]);
        controls.Set(CTRL_LEFT, input.keyDown[KEY_A]);
        controls.Set(CTRL_RIGHT, input.keyDown[KEY_D]);
        controls.Set(CTRL_JUMP, input.keyDown[KEY_SPACE]);
    } else {
        controls.Set(CTRL_FORWARD, false);
        controls.Set(CTRL_BACK, false);
        controls.Set(CTRL_LEFT, false);
        controls.Set(CTRL_RIGHT, false);
        controls.Set(CTRL_JUMP, false);
    }

    Character@ character = cast<Character>(controllerCharacterNode.GetScriptObject());
    if (character !is null) {
        character.SetControls(controls);
    }
    // Client: collect controls
    /*if (serverConnection !is null)
    {

        serverConnection.controls = controls;
        // In case the server wants to do position-based interest management using the NetworkPriority components, we should also
        // tell it our observer (camera) position. In this sample it is not in use, but eg. the NinjaSnowWar game uses it
        serverConnection.position = cameraNode.position;
    }
    // Server: apply controls to client objects
    /*else if (network.serverRunning)
    {
        if (controllerCharacterNode !is null) {
            Character@ character = cast<Character>(controllerCharacterNode.GetScriptObject());
            character.SetControls(controls);
        }
        for (uint i = 0; i < clients.length; ++i) {
            if (clients[i].object !is null) {
                Character@ character = cast<Character>(clients[i].object.GetScriptObject());
                character.SetControls(clients[i].connection.controls);
            }
        }

    }*/
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
