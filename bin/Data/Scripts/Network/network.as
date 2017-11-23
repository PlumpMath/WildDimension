namespace NetworkHandler {
    // UDP port we will use
    const uint SERVER_PORT = 11223;
    Node@ terrainNode;
    Terrain@ terrain;

    const float LIGHT_CHANGE_SPEED = 0.5f;
    class Sunlight {
        Node@ node;
        Light@ light;
        Color color;
        float currentIntensity;
        float targetIntensity;
        float intensityBeforeChange;
        float transitionTime;
        bool change;
        int hour;

        Color ambientColor;
        Color fogColor;
        Zone@ zone;
    };

    Sunlight sunlight;

    class Stats {
        float gameTime;
        bool finished;
    }

    Stats stats;

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
        sunlight.change = false;
        sunlight.hour = 9;
        sunlight.ambientColor = Color(0.1, 0.1, 0.1);
        sunlight.fogColor = Color(0.8f, 0.8f, 0.7f);
        SendEvent("HourChange");

        Places::Init();
        Spawn::Init();
        stats.gameTime = 0.0f;
        stats.finished = false;
        input.mouseVisible = false;
        //network.simulatedLatency = 500;
        //network.simulatedPacketLoss = 0.9;
        NetworkHandler::StopServer();
        //network.StartServer(SERVER_PORT);

        network.updateFps = 10;

        Node@ zoneNode = scene_.CreateChild("Zone");
        sunlight.zone = zoneNode.CreateComponent("Zone");
        // Set same volume as the Octree, set a close bluish fog and some ambient light
        sunlight.zone.boundingBox = BoundingBox(-10000.0f, 10000.0f);
        sunlight.zone.ambientColor = sunlight.ambientColor;
        sunlight.zone.fogColor = sunlight.fogColor;
        sunlight.zone.fogStart = 500.0f;
        sunlight.zone.fogEnd = 1000.0f;
        /*Array<Terrain@> terrains;
        for (int x = 0; x < 1; x++) {
            for (int y = 0; y < 1; y++) {
                int num = x * 4 + y;

                //North - ziemeļi
                //South - Dienvidi
                //West - Rietumi
                //East - austrumi
                x = 2; y = 2;
                //void SetNeighbors(TerrainPatch* north, TerrainPatch* south, TerrainPatch* west, TerrainPatch* east);
                terrainNode = scene_.CreateChild("Terrain");
                Image@ mapTexture = cache.GetResource("Image", "Textures/Map/HeightMap-" + x + "-" + y + ".png");
                terrainNode.position = Vector3(y * (mapTexture.height - 64), 0, x * -(mapTexture.width - 64));
                //terrainNode.scale = Vector3(0.1f, 0.1f, 0.1f);
                //terrainNode.position = Vector3(0.0f, -10.0f, 0.0f);

                int textureWidth = mapTexture.width;
                int textureHeight = mapTexture.height;

                terrain = terrainNode.CreateComponent("Terrain");
                terrain.patchSize = 64;
                terrainNode.SetScale(10.0f);
                terrain.spacing = Vector3(1.0f, 1.0f, 1.0f); // Spacing between vertices and vertical resolution of the height map
                terrain.smoothing = true;
                terrain.heightMap = mapTexture;
                terrain.material = cache.GetResource("Material", "Materials/Terrain-" + x + "-" + y + ".xml");
                // The terrain consists of large triangles, which fits well for occlusion rendering, as a hill can occlude all
                // terrain patches and other objects behind it
                terrain.occluder = true;
                terrains.Push(terrain);

                RigidBody@ body = terrainNode.CreateComponent("RigidBody");
                body.collisionLayer = COLLISION_TERRAIN_LEVEL; // Use layer bitmask 2 for static geometry
                body.restitution = 0.5f;
                CollisionShape@ shape = terrainNode.CreateComponent("CollisionShape");
                shape.SetTerrain();
            }
        }*/
        terrainNode = scene_.GetChild("Terrain");
        terrain = terrainNode.GetComponent("Terrain");
        /*for (int x = 0; x < 4; x++) {
            for (int y = 0; y < 4; y++) {
                int num = x * 4 + y;
                Terrain@ north;
                Terrain@ south;
                Terrain@ west;
                Terrain@ east;
                if (y > 0) {
                    int numN = x * 4 + y - 1;
                    north = terrains[numN];
                }
                if (y < 3) {
                    int numS = x * 4 + y + 1;
                    south = terrains[numS];   
                }
                if (x > 0) {
                    int numW = (x - 1) * 4 + y;
                    west = terrains[numW];
                }
                if (x < 3) {
                    int numE = (x + 1) * 4 + y;
                    east = terrains[numE];   
                }
                terrains[num].SetNeighbors(north, south, west, east);
            }
        }*/
        
        // Create a directional light without shadows
        /*Node@ lightNode1 = scene_.CreateChild("DirectionalLight");
        lightNode1.direction = Vector3(0.5f, -1.0f, 0.5f);
        Light@ light1 = lightNode1.CreateComponent("Light");
        light1.lightType = LIGHT_DIRECTIONAL;
        light1.color = Color(0.8f, 0.8f, 0.8f);
        light1.specularIntensity = 0.2f;
        light1.castShadows = true;
        light1.shadowBias = BiasParameters(0.00025f, 0.5f);
        light1.shadowCascade = CascadeParameters(10.0f, 50.0f, 200.0f, 0.0f, 0.8f);*/
        
        
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
        */
        /*
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

        Vector3 campfirePosition = Places::getPlacePosition("Campfire");
        campfirePosition.x += 5.0f + Random(10.0f);
        campfirePosition.z += 5.0f + Random(10.0f);
        Pickable::Create(campfirePosition, "Stem", "Models/Models/Stem.mdl");

        Vector3 airplanePosition = Places::getPlacePosition("Airplane");
        airplanePosition.x += 10.0f;
        Pickable::Create(airplanePosition, "Backpack", "Models/TeaPot.mdl", 2.0f);

        ActiveTool::Create();

        for (int i = -15; i < 15; i+=3) {
            for (int j = -15; j < 15; j+=3) {
                Vector3 position = Vector3(i * 141 + Random(130.0f), 0.0, j * 133 + + Random(130.0f));
                AppleTree::Create(position);
            }
        }

        for (int i = -15; i < 15; i+=5) {
            for (int j = -15; j < 15; j+=5) {
                Vector3 position = Vector3(i * 126 + Random(120.0f), 0.0, j * 126 + Random(120.0f));
                RaspberryBush::Create(position);
            }
        }

        Vector3 position = Vector3(37 + Random(20.0f), 0.0, 37 + Random(20.0f));
        Camp::Create(position);

        for (int i = -25; i < 25; i+=6) {
            for (int j = -25; j < 25; j+=6) {
                Vector3 position = Vector3(i * 100 + Random(100.0f), 0.0, j * 100 + Random(100.0f));
                EnvObjects::Create(position, "Models/Models/Large_rock.mdl", true, "Rock");
                position = Vector3(i * 66 + Random(100.0f), 0.0, j * 66 + Random(100.0f));
                EnvObjects::Create(position, "Models/Models/Medium_rock.mdl", true, "Rock");
                position = Vector3(i * 48 + Random(100.0f), 0.0, j * 48 + Random(100.0f));
                EnvObjects::Create(position, "Models/Models/Big_tree.mdl", true, "Tree");
                position = Vector3(i * 98 + Random(100.0f), 0.0, j * 98 + Random(100.0f));
                EnvObjects::Create(position, "Models/Models/Big_tree2.mdl", true, "Tree");
                position = Vector3(i * 110 + Random(100.0f), 0.0, j * 110 + Random(100.0f));
                EnvObjects::Create(position, "Models/Models/Big_tree3.mdl", true, "Tree");

                /*position = Vector3(i * 78 + Random(200.0f), 0.0, j * 56 + Random(200.0f));
                EnvObjects::Create(position, "Models/Models/House1.mdl", true, "House1");
                position = Vector3(i * 68 + Random(200.0f), 0.0, j * 134 + Random(200.0f));
                EnvObjects::Create(position, "Models/Models/House2.mdl", true, "House2");
                position = Vector3(i * 215 + Random(200.0f), 0.0, j * 156 + Random(200.0f));
                EnvObjects::Create(position, "Models/Models/House3.mdl", true, "House3");*/
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
        SubscribeToEvent("SaveMap", "NetworkHandler::HandleSaveMap");
        SubscribeToEvent("HourChange", "NetworkHandler::HandleDayNightTime");
        //SubscribeToEvent("ServerDisconnected", "HandleConnectionStatus");

        Clouds::Subscribe();
        Pacman::Subscribe();
        Snake::Subscribe();

        RegisterConsoleCommands();
        Clouds::RegisterConsoleCommands();
        Pacman::RegisterConsoleCommands();
        Snake::RegisterConsoleCommands();

        //Tools
        Inventory::Init();
        ActiveTool::Subscribe();

        ActiveTool::RegisterConsoleCommands();

        Pickable::Subscribe();
        Pickable::RegisterConsoleCommands();

        EnvObjects::Subscribe();
        EnvObjects::RegisterConsoleCommands();
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

        data["CONSOLE_COMMAND_NAME"] = "save_map";
        data["CONSOLE_COMMAND_EVENT"] = "SaveMap";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "hour_increase";
        data["CONSOLE_COMMAND_EVENT"] = "HourChange";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandleConnectionStatus(StringHash eventType, VariantMap& eventData)
    {
        
    }

    void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
    {
        if (stats.finished) {
            return;
        } else {
            ActiveTool::HandleUpdate(eventType, eventData);
            Pacman::HandleUpdate(eventType, eventData);
            Snake::HandleUpdate(eventType, eventData);
            AppleTree::HandleUpdate(eventType, eventData);
            RaspberryBush::HandleUpdate(eventType, eventData);
            Clouds::HandleUpdate(eventType, eventData);
            EnvObjects::HandlePostUpdate(eventType, eventData);
            Spawn::HandleUpdate(eventType, eventData);
            Craft::HandleKeys();
        }

        //Get client terrain if doesn't exist
        if (terrain is null && scene_ !is null) {
            terrainNode = scene_.GetChild("Terrain");
            if (terrainNode !is null) {
                terrain = terrainNode.GetComponent("Terrain");
            }
        }
        // Take the frame time step, which is stored as a float
        float timeStep = eventData["TimeStep"].GetFloat();

        //Handle light intensity change
        if (sunlight.change && sunlight.light !is null && sunlight.zone !is null) {
            float diff = sunlight.targetIntensity - sunlight.intensityBeforeChange;
            sunlight.transitionTime += timeStep * LIGHT_CHANGE_SPEED;
            if (sunlight.transitionTime > 1.0f) {
                sunlight.transitionTime = 1.0f;
                sunlight.change = false;
            }
            sunlight.currentIntensity = sunlight.intensityBeforeChange + diff * sunlight.transitionTime;
            sunlight.light.color = Color(sunlight.color.r * sunlight.currentIntensity, sunlight.color.g * sunlight.currentIntensity, sunlight.color.b * sunlight.currentIntensity);
            sunlight.zone.ambientColor = Color(sunlight.ambientColor.r * sunlight.currentIntensity, sunlight.ambientColor.g * sunlight.currentIntensity, sunlight.ambientColor.b * sunlight.currentIntensity);
            sunlight.zone.fogColor = Color(sunlight.fogColor.r * sunlight.currentIntensity, sunlight.fogColor.g * sunlight.currentIntensity, sunlight.fogColor.b * sunlight.currentIntensity);
        }

        stats.gameTime += timeStep;
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

    void HandleSaveMap(StringHash eventType, VariantMap& eventData)
    {
        File file("Data/Map/Map.json", FILE_WRITE);
        scene_.SaveJSON(file);
    }

    void HandlePhysicsPreStep(StringHash eventType, VariantMap& eventData)
    {
        if (stats.finished) {
            return;
        }
        Player::HandlePhysicsPreStep(eventType, eventData);
    }

    float GetHourLightIntensity(int hour) {
        if (hour <= 1) {
            return 0.01;
        }
        if (hour <= 3) {
            return 0.1;
        }
        if (hour <= 4) {
            return 0.15;
        }
        if (hour <= 5) {
            return 0.3;
        }
        if (hour <= 6) {
            return 0.4;
        }
        if (hour <= 7) {
            return 0.6;
        }
        if (hour <= 8) {
            return 0.8;
        }
        if (hour <= 9) {
            return 0.85;
        }
        if (hour <= 10) {
            return 0.9;
        }
        if (hour <= 12) {
            return 0.95;
        }
        if (hour <= 18) {
            return 1.0;
        }
        if (hour <= 19) {
            return 0.9;
        }
        if (hour <= 20) {
            return 0.8;
        }
        if (hour <= 21) {
            return 0.6;
        }
        if (hour <= 22) {
            return 0.4;
        }
        if (hour <= 23) {
            return 0.2;
        }

        return 0.1f;
    }

    void HandleDayNightTime(StringHash eventType, VariantMap& eventData)
    {

        log.Warning("Current hour: " + sunlight.hour + ", intensity = " + GetHourLightIntensity(sunlight.hour));
        if (eventData.Contains("Hour")) {
            uint hour = eventData["Hour"].GetUInt();
            sunlight.hour = hour;
        } else {
            sunlight.hour++;
        }
        log.Warning("New hour: " + sunlight.hour + ", intensity = " + GetHourLightIntensity(sunlight.hour));
        if (sunlight.hour > 23) {
            sunlight.hour = 0;
        }
        if (sunlight.node is null) {
            sunlight.node = scene_.GetChild("DirectionalLight");
        }
        if (sunlight.light is null) {
            sunlight.light = sunlight.node.GetComponent("Light");
            sunlight.currentIntensity = GetHourLightIntensity(sunlight.hour);
            sunlight.color = Color(0.8, 0.8, 0.8, 1);
        }

        sunlight.change = true;
        sunlight.targetIntensity = GetHourLightIntensity(sunlight.hour);
        sunlight.intensityBeforeChange = sunlight.currentIntensity;
        sunlight.transitionTime = 0.0f;
    }
}