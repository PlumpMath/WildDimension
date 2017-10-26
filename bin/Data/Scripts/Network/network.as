namespace NetworkHandler {
    // UDP port we will use
    const uint SERVER_PORT = 2345;

    void StartServer()
    {
        NetworkHandler::StopServer();
        network.StartServer(SERVER_PORT);
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
            //clientObjectID = 0;
        }
        // Or if we were running a server, stop it
        else if (network.serverRunning)
        {
            NetworkHandler::DisconnectClients();
            network.StopServer();
        }
    }

    void Connect()
    {
        NetworkHandler::StopServer();
        String address = "127.0.0.1";
        network.Connect(address, SERVER_PORT, scene_);
    }
}