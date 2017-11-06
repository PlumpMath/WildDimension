namespace NetworkHandler {
    // UDP port we will use
    const uint SERVER_PORT = 11223;
    Node@ terrainNode;
    Terrain@ terrain;

    void StartServer()
    {
        //network.simulatedLatency = 500;
        //network.simulatedPacketLoss = 0.9;
        NetworkHandler::StopServer();
        //network.StartServer(SERVER_PORT);

        network.updateFps = 10;

        // Create a Zone component for ambient lighting & fog control
        Node@ zoneNode = scene_.CreateChild("Zone");
        Zone@ zone = zoneNode.CreateComponent("Zone");
        zone.boundingBox = BoundingBox(-1000.0f, 1000.0f);
        zone.ambientColor = Color(0.2f, 0.2f, 0.05f);
        zone.fogStart = 50.0f;
        zone.fogEnd = 500.0f;

        // Create a directional light without shadows
        Node@ lightNode1 = scene_.CreateChild("DirectionalLight");
        lightNode1.direction = Vector3(0.5f, -1.0f, 0.5f);
        Light@ light1 = lightNode1.CreateComponent("Light");
        light1.lightType = LIGHT_DIRECTIONAL;
        light1.color = Color(0.8f, 0.8f, 0.8f);
        light1.specularIntensity = 1.0f;
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
        Node@ skyNode = scene_.CreateChild("Sky");
        skyNode.SetScale(500.0); // The scale actually does not matter
        Skybox@ skybox = skyNode.CreateComponent("Skybox");
        skybox.model = cache.GetResource("Model", "Models/Box.mdl");
        skybox.material = cache.GetResource("Material", "Materials/Skybox.xml");

        // Create heightmap terrain
        terrainNode = scene_.CreateChild("Terrain");
        //terrainNode.scale = Vector3(0.1f, 0.1f, 0.1f);
        //terrainNode.position = Vector3(0.0f, -10.0f, 0.0f);
        terrain = terrainNode.CreateComponent("Terrain");
        terrain.patchSize = 64;
        terrain.spacing = Vector3(2.0f, 0.5f, 2.0f); // Spacing between vertices and vertical resolution of the height map
        terrain.smoothing = true;
        terrain.heightMap = cache.GetResource("Image", "Textures/HeightMap.png");
        terrain.material = cache.GetResource("Material", "Materials/Terrain.xml");
        // The terrain consists of large triangles, which fits well for occlusion rendering, as a hill can occlude all
        // terrain patches and other objects behind it
        terrain.occluder = true;

        RigidBody@ body = terrainNode.CreateComponent("RigidBody");
        body.collisionLayer = 2; // Use layer bitmask 2 for static geometry
        body.restitution = 0.5f;
        CollisionShape@ shape = terrainNode.CreateComponent("CollisionShape");
        shape.SetTerrain();

        // Create groups of mushrooms, which act as shadow casters
        const uint NUM_MUSHROOMGROUPS = 0;
        const uint NUM_MUSHROOMS = 10;

        for (uint i = 0; i < NUM_MUSHROOMGROUPS; ++i)
        {
            // First create a scene node for the group. The individual mushrooms nodes will be created as children
            //Node@ groupNode = scene_.CreateChild("MushroomGroup");
            //groupNode.position = Vector3(Random(400.0f) - 95.0f, 0.0f, Random(400.0f) - 95.0f);

            for (uint j = 0; j < NUM_MUSHROOMS; ++j)
            {
                Node@ mushroomNode = scene_.CreateChild("Mushroom");
                Vector3 position = Vector3(Random(1000.0f) - 95.0f, 0.0f, Random(1000.0f) - 95.0f);
                position.y = terrain.GetHeight(position);
                mushroomNode.position = position;
                mushroomNode.worldRotation = Quaternion(Vector3(0.0f, 1.0f, 0.0f), terrain.GetNormal(position));
                //stamushroomNode.rotation = Quaternion(0.0f, Random() * 360.0f, 0.0f);
                mushroomNode.SetScale(1.0f + Random(2.0f) * 1.0f);
                StaticModel@ mushroomObject = mushroomNode.CreateComponent("StaticModel");
                mushroomObject.model = cache.GetResource("Model", "Models/Mushroom.mdl");
                mushroomObject.material = cache.GetResource("Material", "Materials/Mushroom.xml");
                mushroomObject.castShadows = true;
            }
        }

        for (uint i = 0; i < NUM_MUSHROOMGROUPS; ++i)
        {
            // First create a scene node for the group. The individual mushrooms nodes will be created as children
            //Node@ groupNode = scene_.CreateChild("MushroomGroup");
            //groupNode.position = Vector3(Random(400.0f) - 95.0f, 0.0f, Random(400.0f) - 95.0f);

            for (uint j = 0; j < NUM_MUSHROOMS; ++j)
            {
                Node@ mushroomNode = scene_.CreateChild("Mushroom");
                Vector3 position = Vector3(Random(300.0f) - 95.0f, 0.0f, Random(300.0f) - 95.0f);
                position.y = terrain.GetHeight(position) + 10.0f;
                mushroomNode.position = position;
                mushroomNode.worldRotation = Quaternion(Vector3(0.0f, 1.0f, 0.0f), terrain.GetNormal(position));
                //stamushroomNode.rotation = Quaternion(0.0f, Random() * 360.0f, 0.0f);
                float sc = 1.0f + Random(2.0f) * 1.0f;
                Vector3 scale = Vector3(sc, sc, sc);
                mushroomNode.SetScale(sc);
                StaticModel@ mushroomObject = mushroomNode.CreateComponent("StaticModel");
                mushroomObject.model = cache.GetResource("Model", "Models/Models/Pacman.mdl");
                mushroomObject.material = cache.GetResource("Material", "Materials/Stone.xml");
                mushroomObject.castShadows = true;

                RigidBody@ body2 = mushroomNode.CreateComponent("RigidBody");
                body2.mass = 1.0f;
                body2.friction = 0.2f;
                body2.restitution = 0.1f;
                CollisionShape@ shape2 = mushroomNode.CreateComponent("CollisionShape");
                shape2.SetConvexHull(mushroomObject.model);

                ParticleEmitter@ particleEmitter = mushroomNode.CreateComponent("ParticleEmitter");
                particleEmitter.effect = cache.GetResource("ParticleEffect", "Particle/Fire.xml");
                particleEmitter.emitting = true;
            }
        }

        // Create billboard sets (floating smoke)
        const uint NUM_BILLBOARDNODES = 0;
        const uint NUM_BILLBOARDS = 10;

        for (uint i = 0; i < NUM_BILLBOARDNODES; ++i)
        {
            Node@ smokeNode = scene_.CreateChild("Smoke");
            Vector3 position = Vector3(Random(500.0f) - 100.0f, Random(50.0f) + 20.0f, Random(500.0f) - 100.0f);
            position.y = terrain.GetHeight(position) + 20.0f;
            smokeNode.position = position;
            BillboardSet@ billboardObject = smokeNode.CreateComponent("BillboardSet");
            billboardObject.numBillboards = NUM_BILLBOARDS;
            billboardObject.material = cache.GetResource("Material", "Materials/LitSmoke.xml");
            billboardObject.sorted = true;

            for (uint j = 0; j < NUM_BILLBOARDS; ++j)
            {
                Billboard@ bb = billboardObject.billboards[j];
                bb.position = Vector3(Random(12.0f) - 6.0f, Random(8.0f) - 4.0f, Random(12.0f) - 6.0f);
                bb.size = Vector2(Random(2.0f) + 3.0f, Random(2.0f) + 3.0f);
                bb.rotation = Random() * 360.0f;
                bb.enabled = true;
            }

            // After modifying the billboards, they need to be "committed" so that the BillboardSet updates its internals
            billboardObject.Commit();
        }

        // Create shadow casting spotlights
        const uint NUM_LIGHTS = 0;

        for (uint i = 0; i < NUM_LIGHTS; ++i)
        {
            Node@ lightNode = scene_.CreateChild("SpotLight");
            Light@ light = lightNode.CreateComponent("Light");

            float angle = 0.0f;

            Vector3 position((i % 3) * 60.0f - 60.0f, 95.0f, (i / 3) * 60.0f - 60.0f);
            Color color(((i + 1) & 1) * 0.5f + 0.5f, (((i + 1) >> 1) & 1) * 0.5f + 0.5f, (((i + 1) >> 2) & 1) * 0.5f + 0.5f);

            lightNode.position = position;
            lightNode.direction = Vector3(Sin(angle), -1.5f, Cos(angle));

            light.lightType = LIGHT_SPOT;
            light.range = 200.0f;
            //light.rampTexture = cache.GetResource("Texture2D", "Textures/UrhoIcon.png");
            light.fov = 45.0f;
            light.color = color;
            light.specularIntensity = 1.0f;
            light.castShadows = true;
            light.shadowBias = BiasParameters(0.00025f, 0.5f);
            light.shadowCascade = CascadeParameters(10.0f, 50.0f, 200.0f, 0.0f, 0.8f);

            // Configure shadow fading for the lights. When they are far away enough, the lights eventually become unshadowed for
            // better GPU performance. Note that we could also set the maximum distance for each object to cast shadows
            light.shadowFadeDistance = 100.0f; // Fade start distance
            light.shadowDistance = 125.0f; // Fade end distance, shadows are disabled
            // Set half resolution for the shadow maps for increased performance
            light.shadowResolution = 0.8f;
            // The spot lights will not have anything near them, so move the near plane of the shadow camera farther
            // for better shadow depth resolution
            light.shadowNearFarRatio = 0.01f;
        }

        for (int i = -5; i < 5; i+=5) {
            for (int j = -5; j < 5; j+=5) {
                Vector3 position = Vector3(i * 40 + Random(20.0f), 0.0, j * 40 + Random(20.0f));
                Pacman::Create(position);
            }
        }

        for (int i = -5; i < 5; i+=5) {
            for (int j = -5; j < 5; j+=10) {
                Vector3 position = Vector3(i * 30 + Random(30.0f), 0.0, j * 30 + Random(30.0f));
                Snake::Create(position);
            }
        }

        for (int i = -5; i < 5; i+=10) {
            for (int j = -5; j < 5; j+=10) {
                Vector3 position = Vector3(i * 1 + Random(2.0f), 0.0, j * 1 + + Random(2.0f));
                AppleTree::Create(position);
            }
        }

        for (int i = -5; i < 5; i+=5) {
            for (int j = -5; j < 5; j+=5) {
                Vector3 position = Vector3(i * 12 + Random(2.0f), 0.0, j * 12 + + Random(2.0f));
                RaspberryBush::Create(position);
            }
        }

        for (int i = -10; i < 10; i+=20) {
            for (int j = -10; j < 10; j+=20) {
                Vector3 position = Vector3(i * 1 + Random(100.0f), 0.0, j * 1 + + Random(100.0f));
                Clouds::Create(position);
            }
        }

        Axe::Create();
    }

    
    void Subscribe()
    {
        SubscribeToEvent("ClientConnected", "NetworkHandler::HandleClientConnected");
        SubscribeToEvent("ClientDisconnected", "NetworkHandler::HandleClientDisconnected");
        SubscribeToEvent("ServerConnected", "NetworkHandler::HandleConnectionStatus");
        SubscribeToEvent("ClientIdentity", "NetworkHandler::HandleClientIdentity");
        SubscribeToEvent("ClientsList", "NetworkHandler::HandleClientsList");
        //SubscribeToEvent("ServerDisconnected", "HandleConnectionStatus");
        Axe::Subscribe();
    }

    void HandleConnectionStatus(StringHash eventType, VariantMap& eventData)
    {
        
    }

    void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
    {
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