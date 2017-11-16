namespace NetworkHandler {
    // UDP port we will use
    const uint SERVER_PORT = 11223;
    Node@ terrainNode;
    Terrain@ terrain;

    void LoadScene()
    {
        File file("Data/Map/Map.json", FILE_READ);
        scene_.LoadJSON(file);
    }

    void CreateScene()
    {

    }

    void StartServer()
    {
        input.mouseVisible = false;
        //network.simulatedLatency = 500;
        //network.simulatedPacketLoss = 0.9;
        NetworkHandler::StopServer();
        //network.StartServer(SERVER_PORT);

        network.updateFps = 10;

        terrainNode = scene_.GetChild("Terrain");
        terrain = terrainNode.GetComponent("Terrain");
        // Create a Zone component for ambient lighting & fog control
        Node@ zoneNode = scene_.CreateChild("Zone");
        Zone@ zone = zoneNode.CreateComponent("Zone");
        zone.boundingBox = BoundingBox(-1000.0f, 1000.0f);
        zone.ambientColor = Color(0.4, 0.4, 0.4);
        //zone.fogColor = Color(0.3f, 0.3f, 0.3f);
        zone.fogStart = 100.0f;
        zone.fogEnd = 500.0f;
        zone.occluder = true;
        /*
        // Create a directional light without shadows
        Node@ lightNode1 = scene_.CreateChild("DirectionalLight");
        lightNode1.direction = Vector3(0.5f, -1.0f, 0.5f);
        Light@ light1 = lightNode1.CreateComponent("Light");
        light1.lightType = LIGHT_DIRECTIONAL;
        light1.color = Color(0.8f, 0.8f, 0.8f);
        light1.specularIntensity = 0.2f;
        light1.castShadows = true;
        light1.shadowBias = BiasParameters(0.00025f, 0.5f);
        light1.shadowCascade = CascadeParameters(10.0f, 50.0f, 200.0f, 0.0f, 0.8f);
        
        /*
        // Create a "floor" consisting of several tiles
        /*for (int y = -50; y <= 50; ++y)
        {
            for (int x = -50; x <= 50; ++x)
            {
                Node@ floorNode = scene_.CreateChild("FloorTile");
                floorNode.position = Vector3(x * 20.5f, -0.5f, y * 20.5f);
                floorNode.scale = Vector3(20.0f, 1.0f, 20.f);
                StaticModel@ floorObject = floorNode.CreateComponent("StaticModel");
                floorObject.model = cache.GetResource("Model", "Models/Box.mdl");
                floorObject.material = cache.GetResource("Material", "Materials/Stone.xml");
            }
        }*/

        // Create skybox. The Skybox component is used like StaticModel, but it will be always located at the camera, giving the
        // illusion of the box planes being far away. Use just the ordinary Box model and a suitable material, whose shader will
        // generate the necessary 3D texture coordinates for cube mapping
        /*Node@ skyNode = scene_.CreateChild("Sky");
        skyNode.SetScale(500.0); // The scale actually does not matter
        skyNode.position = Vector3(0, 0, 0);

        Skybox@ skybox = skyNode.CreateComponent("Skybox");
        skybox.model = cache.GetResource("Model", "Models/SkyDome.mdl");
        skybox.material = cache.GetResource("Material", "Materials/Skybox.xml");

        // Create heightmap terrain
        terrainNode = scene_.CreateChild("Terrain");
        //terrainNode.scale = Vector3(0.1f, 0.1f, 0.1f);
        //terrainNode.position = Vector3(0.0f, -10.0f, 0.0f);
        terrain = terrainNode.CreateComponent("Terrain");
        terrain.patchSize = 64;
        terrain.spacing = Vector3(1.0f, 0.5f, 1.0f); // Spacing between vertices and vertical resolution of the height map
        terrain.smoothing = true;
        terrain.heightMap = cache.GetResource("Image", "Textures/HeightMap.png");
        terrain.material = cache.GetResource("Material", "Materials/Terrain.xml");
        // The terrain consists of large triangles, which fits well for occlusion rendering, as a hill can occlude all
        // terrain patches and other objects behind it
        terrain.occluder = true;

        RigidBody@ body = terrainNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_TERRAIN_LEVEL; // Use layer bitmask 2 for static geometry
        body.restitution = 0.5f;
        CollisionShape@ shape = terrainNode.CreateComponent("CollisionShape");
        shape.SetTerrain();*/

        ActiveTool::Create();
        for (int i = -5; i < 5; i+=5) {
            for (int j = -5; j < 5; j+=5) {
                Vector3 position = Vector3(i * 40 + Random(20.0f), 0.0, j * 40 + Random(20.0f));
                Pacman::Create(position);
            }
        }

        for (int i = -5; i < 5; i+=5) {
            for (int j = -5; j < 5; j+=5) {
                Vector3 position = Vector3(i * 20 + Random(30.0f), 0.0, j * 20 + Random(30.0f));
                Snake::Create(position);
            }
        }

        for (int i = -10; i < 10; i+=1) {
            for (int j = -10; j < 10; j+=1) {
                Vector3 position = Vector3(i * 41 + Random(30.0f), 0.0, j * 37 + Random(30.0f));
                //RandomTree::Create(position);
                position.x += Random(10.0f);
                position.z += Random(10.0f);
                RandomRock::Create(position);
            }
        }

        for (int i = -10; i < 10; i+=1) {
            for (int j = -10; j < 10; j+=1) {
                Vector3 position = Vector3(i * 41 + Random(30.0f), 0.0, j * 33 + + Random(30.0f));
                AppleTree::Create(position);

                position.x += 2.0f + Random(5.0f);
                position.z += 2.0f + Random(5.0f);
                Axe::CreatePickable(position);
                position.x += 2.0f + Random(5.0f);
                position.z += 2.0f + Random(5.0f);
                Trap::CreatePickable(position);
            }
        }

        for (int i = -10; i < 10; i+=1) {
            for (int j = -10; j < 10; j+=1) {
                Vector3 position = Vector3(i * 26 + Random(20.0f), 0.0, j * 26 + Random(20.0f));
                RaspberryBush::Create(position);
            }
        }

        for (int i = -10; i < 10; i+=4) {
            for (int j = -10; j < 10; j+=4) {
                Vector3 position = Vector3(i * 100 + Random(300.0f), 0.0, j * 100 + + Random(300.0f));
                Clouds::Create(position);
            }
        }

        for (int i = -5; i < 5; i+=5) {
            for (int j = -5; j < 5; j+=5) {
                Vector3 position = Vector3(i * 37 + Random(20.0f), 0.0, j * 37 + Random(20.0f));
                Camp::Create(position);
            }
        }

        for (int i = -10; i < 10; i+=2) {
            for (int j = -10; j < 10; j+=2) {
                Vector3 position = Vector3(i * 100 + Random(50.0f), 0.0, j * 100 + Random(50.0f));
                EnvObjects::Create(position, "Models/Models/Large_rock.mdl");
                position = Vector3(i * 66 + Random(50.0f), 0.0, j * 55 + Random(50.0f));
                EnvObjects::Create(position, "Models/Models/Medium_rock.mdl");
                position = Vector3(i * 48 + Random(50.0f), 0.0, j * 37 + Random(50.0f));
                EnvObjects::Create(position, "Models/Models/Big_tree.mdl");
                position = Vector3(i * 98 + Random(50.0f), 0.0, j * 67 + Random(50.0f));
                EnvObjects::Create(position, "Models/Models/Big_tree2.mdl");
                position = Vector3(i * 88 + Random(50.0f), 0.0, j * 59 + Random(50.0f));
                EnvObjects::Create(position, "Models/Models/Big_tree3.mdl");
            }
        }

        GameSounds::PlayAmbient(GameSounds::AMBIENT_SOUND);

        /*File file("Map.xml", FILE_WRITE);
        scene_.SaveXML(file);

        File file2("Map.json", FILE_WRITE);
        scene_.SaveJSON(file2);*/

    }

    
    void Subscribe()
    {
        SubscribeToEvent("ClientConnected", "NetworkHandler::HandleClientConnected");
        SubscribeToEvent("ClientDisconnected", "NetworkHandler::HandleClientDisconnected");
        SubscribeToEvent("ServerConnected", "NetworkHandler::HandleConnectionStatus");
        SubscribeToEvent("ClientIdentity", "NetworkHandler::HandleClientIdentity");
        SubscribeToEvent("ClientsList", "NetworkHandler::HandleClientsList");
        //SubscribeToEvent("ServerDisconnected", "HandleConnectionStatus");

        Clouds::Subscribe();
        Pacman::Subscribe();
        Snake::Subscribe();

        RegisterConsoleCommands();
        Clouds::RegisterConsoleCommands();
        Pacman::RegisterConsoleCommands();
        Snake::RegisterConsoleCommands();

        //Tools
        Inventory::Subscribe();
        ActiveTool::Subscribe();
        Axe::Subscribe();
        Trap::Subscribe();
        
        RandomRock::Subscribe();
        RandomRock::RegisterConsoleCommands();

        Inventory::RegisterConsoleCommands();
        ActiveTool::RegisterConsoleCommands();
        Axe::RegisterConsoleCommands();
        Trap::RegisterConsoleCommands();
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "clientlist";
        data["CONSOLE_COMMAND_EVENT"] = "ClientsList";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "start";
        data["CONSOLE_COMMAND_EVENT"] = "StartServer";

        data["CONSOLE_COMMAND_NAME"] = "connect";
        data["CONSOLE_COMMAND_EVENT"] = "ConnectToServer";

        data["CONSOLE_COMMAND_NAME"] = "disconnect";
        data["CONSOLE_COMMAND_EVENT"] = "DisconnectFromServer";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandleConnectionStatus(StringHash eventType, VariantMap& eventData)
    {
        
    }

    void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
    {
        ActiveTool::HandleUpdate(eventType, eventData);
        Pacman::HandleUpdate(eventType, eventData);
        Snake::HandleUpdate(eventType, eventData);
        AppleTree::HandleUpdate(eventType, eventData);
        RaspberryBush::HandleUpdate(eventType, eventData);
        Clouds::HandleUpdate(eventType, eventData);

        //Get client terrain if it not exist
        if (terrain is null && scene_ !is null) {
            terrainNode = scene_.GetChild("Terrain");
            if (terrainNode !is null) {
                terrain = terrainNode.GetComponent("Terrain");
            }
        }
        // Take the frame time step, which is stored as a float
        float timeStep = eventData["TimeStep"].GetFloat();
        // Get the light and billboard scene nodes
        Array<Node@> lightNodes = scene_.GetChildrenWithComponent("Light");
        Array<Node@> billboardNodes = scene_.GetChildrenWithComponent("BillboardSet");

        const float LIGHT_ROTATION_SPEED = 0.50f;
        const float BILLBOARD_ROTATION_SPEED = 50.0f;

        // Rotate the lights around the world Y-axis
        for (uint i = 0; i < lightNodes.length; ++i)
            lightNodes[i].Rotate(Quaternion(0.0f, LIGHT_ROTATION_SPEED * timeStep, 0.0f), TS_WORLD);

        // Rotate the individual billboards within the billboard sets, then recommit to make the changes visible
        for (uint i = 0; i < billboardNodes.length; ++i)
        {
            BillboardSet@ billboardObject = billboardNodes[i].GetComponent("BillboardSet");

            for (uint j = 0; j < billboardObject.numBillboards; ++j)
            {
                Billboard@ bb = billboardObject.billboards[j];
                bb.rotation += BILLBOARD_ROTATION_SPEED * timeStep;
            }

            billboardObject.Commit();
        }
    }

    void DisconnectClients()
    {
        for (uint i = 0; i < network.clientConnections.length; i++) {
            network.clientConnections[i].Disconnect();
        }
    }

    void StopServer()
    {
        Connection@ serverConnection = network.serverConnection;
        // If we were connected to server, disconnect. Or if we were running a server, stop it. In both cases clear the
        // scene of all replicated content, but let the local nodes & components (the static world + camera) stay
        if (serverConnection !is null)
        {
            serverConnection.Disconnect();
             scene_.Clear(true, false);
        }
        // Or if we were running a server, stop it
        else if (network.serverRunning)
        {
            NetworkHandler::DisconnectClients();
            network.StopServer();
             scene_.Clear(true, false);
        }
    }

    void Connect()
    {
        NetworkHandler::StopServer();
        //String address = "miegamicis.asuscomm.com";
        String address = "127.0.0.1";
        VariantMap map;
        map["USER_NAME"] = "123";
        network.Connect(address, SERVER_PORT, scene_, map);
    }

    void HandleClientConnected(StringHash eventType, VariantMap& eventData)
    {
        // When a client connects, assign to scene to begin scene replication
        Connection@ newConnection = eventData["Connection"].GetPtr();
        newConnection.scene = scene_;
    }

    void HandleClientDisconnected(StringHash eventType, VariantMap& eventData)
    {
        // When a client connects, assign to scene to begin scene replication
        Connection@ newConnection = eventData["Connection"].GetPtr();
        log.Info("Client " + newConnection.identity["USER_NAME"].GetString() + " disconnected");
    }

    void HandleClientIdentity(StringHash eventType, VariantMap& eventData)
    {
        String name = eventData["USER_NAME"].GetString();
        Connection@ newConnection = eventData["Connection"].GetPtr();
        log.Info(newConnection.ToString() + " identified himself as '" + name + "'");
    }

    void Destroy()
    {
        
    }

    void HandleClientsList(StringHash eventType, VariantMap& eventData)
    {
        log.Info("");
        log.Info("#### CLIENT LIST ####");
        for (uint i = 0; i < network.clientConnections.length; i++) {
            log.Info("# Client: " + network.clientConnections[i].identity["USER_NAME"].GetString() + ", Ping: " + String(network.clientConnections[i].roundTripTime) + ", IP: " + network.clientConnections[i].ToString());
        }
        log.Info("#####################");
        log.Info("");
    }
}