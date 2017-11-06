namespace GUIHandler {
    Sprite@ logoSprite;
    Text@ bytesIn;
    Text@ bytesOut;

    void CreateGUI()
    {
        CreateLogo();
        CreateNetworkTrafficDebug();
    }

    void CreateLogo()
    {
        if (engine.headless) {
            return;
        }
        // Get logo texture
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/FishBoneLogo.png");
        if (logoTexture is null)
            return;

        // Create logo sprite and add to the UI layout
        logoSprite = ui.root.CreateChild("Sprite");

        // Set logo sprite texture
        logoSprite.texture = logoTexture;

        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;

        // Set logo sprite scale
        logoSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        logoSprite.SetSize(textureWidth, textureHeight);

        // Set logo sprite hot spot
        logoSprite.SetHotSpot(textureWidth, textureHeight);

        // Set logo sprite alignment
        logoSprite.SetAlignment(HA_RIGHT, VA_BOTTOM);

        // Make logo not fully opaque to show the scene underneath
        logoSprite.opacity = 0.9f;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        logoSprite.priority = -100;
    }

    void RemoveLogo()
    {
        if (logoSprite !is null) {
            logoSprite.Remove();
            logoSprite = null;
        }
    }

    void Subscribe()
    {
        SubscribeToEvent("ToggleLogo", "GUIHandler::ToggleLogo");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "logo";
        data["CONSOLE_COMMAND_EVENT"] = "ToggleLogo";
        SendEvent("ConsoleCommandAdd", data);
    }

    void Destroy()
    {
        RemoveLogo();
        if (bytesIn !is null) {
            bytesIn.Remove();
        }
        if (bytesOut !is null) {
            bytesOut.Remove();
        }
    }

    void CreateNetworkTrafficDebug()
    {
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

    void ToggleLogo()
    {
        if (logoSprite !is null) {
            RemoveLogo();
        } else {
            CreateLogo();
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        Connection@ serverConnection = network.serverConnection;
        if (serverConnection !is null) {
            if (bytesIn !is null) {
                bytesIn.text = "Bytes In: " + String(serverConnection.bytesInPerSec);
            }
            if (bytesOut !is null) {
                bytesOut.text = "Bytes Out: " + String(serverConnection.bytesOutPerSec);
            }
        } else if (network.serverRunning) {
            float bIn;
            float bOut;
            bIn = 0;
            bOut = 0;
            for (uint i = 0; i < network.clientConnections.length; i++) {
                bIn += network.clientConnections[i].bytesInPerSec;
                bOut += network.clientConnections[i].bytesOutPerSec;
            }
            //bIn /= 1024;
            //bOut /= 1024;
            if (bytesIn !is null) {
                bytesIn.text = "Bytes In: " + String(bIn);
            }
            if (bytesOut !is null) {
                bytesOut.text = "Bytes Out: " + String(bOut);
            }
        }
    }
}