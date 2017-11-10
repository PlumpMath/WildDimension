namespace GUIHandler {

    const String GUI_FONT = "Fonts/PainttheSky-Regular.otf";
    const int GUI_FONT_SIZE = 20;
    const int GUI_NOTES_FONT_SIZE = 14;

    Sprite@ logoSprite;
    Text@ bytesIn;
    Text@ bytesOut;
    Text@ inventoryList;
    UIElement@ eventLog;
    Array<Text@> latestEvents;

    Sprite@ notesSprite;
    Array<Text@> notesLines;

    Text@ positionText;

    void CreateGUI()
    {
        //CreateLogo();
        CreateNetworkTrafficDebug();
        CreateInventory();
        CreateEventLog();
        CreatePositionText();
        CreateNotes();
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

    void CreateNotes()
    {
        if (engine.headless) {
            return;
        }
        // Get logo texture
        Texture2D@ notesTexture = cache.GetResource("Texture2D", "Textures/notes.png");
        if (notesTexture is null) {
            return;
        }

        // Create logo sprite and add to the UI layout
        notesSprite = ui.root.CreateChild("Sprite");

        // Set logo sprite texture
        notesSprite.texture = notesTexture;

        int textureWidth = notesTexture.width / 2;
        int textureHeight = notesTexture.height / 2;

        // Set logo sprite scale
        //notesSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        notesSprite.SetSize(textureWidth, textureHeight);
        notesSprite.position = Vector2(-10, 10);

        // Set logo sprite hot spot
        notesSprite.SetHotSpot(textureWidth, 0);

        // Set logo sprite alignment
        notesSprite.SetAlignment(HA_RIGHT, VA_TOP);

        // Make logo not fully opaque to show the scene underneath
        notesSprite.opacity = 1.0f;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        notesSprite.priority = -100;

        UIElement@ missions = notesSprite.CreateChild("UIElement");

        // Position the text relative to the screen center
        missions.horizontalAlignment = HA_LEFT;
        missions.verticalAlignment = VA_TOP;
        missions.SetPosition(-10, 10);

        for (int i = 0; i < 10; i++) {
            Text@ oneLine = missions.CreateChild("Text");
            oneLine.text = "";//String(i) + "element";
            oneLine.SetFont(cache.GetResource("Font", GUI_FONT), GUI_NOTES_FONT_SIZE);
            oneLine.textAlignment = HA_LEFT; // Center rows in relation to each other
            oneLine.color = Color(1, 0, 0);

            // Position the text relative to the screen center
            oneLine.horizontalAlignment = HA_LEFT;
            oneLine.verticalAlignment = VA_TOP;
            oneLine.SetPosition(25, i * GUI_NOTES_FONT_SIZE + 2);
            notesLines.Push(oneLine);
        }
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
        SubscribeToEvent("UpdateInventoryGUI", "GUIHandler::HandleUpdateInventoryGUI");
        SubscribeToEvent("UpdateEventLogGUI", "GUIHandler::HandleUpdateEventLog");
        SubscribeToEvent("UpdateMissionsGUI", "GUIHandler::HandleUpdateMissionsGUI");
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
        if (inventoryList !is null) {
            inventoryList.Remove();
        }
        if (eventLog !is null) {
            eventLog.RemoveAllChildren();
            eventLog.Remove();
            latestEvents.Clear();
        }
        if (positionText !is null) {
            positionText.Remove();
        }
        if (notesSprite !is null) {
            notesSprite.Remove();
        }
    }

    void CreateNetworkTrafficDebug()
    {
        bytesIn = ui.root.CreateChild("Text");
        bytesIn.text = "";
        bytesIn.SetFont(cache.GetResource("Font", GUI_FONT), GUI_FONT_SIZE);
        bytesIn.textAlignment = HA_CENTER; // Center rows in relation to each other

        // Position the text relative to the screen center
        bytesIn.horizontalAlignment = HA_LEFT;
        bytesIn.verticalAlignment = VA_BOTTOM;
        bytesIn.SetPosition(0, -10);

        bytesOut = ui.root.CreateChild("Text");
        bytesOut.text = "";
        bytesOut.SetFont(cache.GetResource("Font", GUI_FONT), GUI_FONT_SIZE);
        bytesOut.textAlignment = HA_CENTER; // Center rows in relation to each other

        // Position the text relative to the screen center
        bytesOut.horizontalAlignment = HA_LEFT;
        bytesOut.verticalAlignment = VA_BOTTOM;
        bytesOut.SetPosition(0, -20);
    }

    void CreateInventory()
    {
        inventoryList = ui.root.CreateChild("Text");
        inventoryList.text = "";
        inventoryList.SetFont(cache.GetResource("Font", GUI_FONT), GUI_FONT_SIZE);
        inventoryList.textAlignment = HA_CENTER; // Center rows in relation to each other

        // Position the text relative to the screen center
        inventoryList.horizontalAlignment = HA_RIGHT;
        inventoryList.verticalAlignment = VA_BOTTOM;
        inventoryList.SetPosition(-20, -200);
    }

    void CreatePositionText()
    {
        positionText = ui.root.CreateChild("Text");
        positionText.text = "";
        positionText.SetFont(cache.GetResource("Font", GUI_FONT), GUI_FONT_SIZE);
        positionText.textAlignment = HA_LEFT; // Center rows in relation to each other

        // Position the text relative to the screen center
        positionText.horizontalAlignment = HA_LEFT;
        positionText.verticalAlignment = VA_TOP;
        positionText.SetPosition(20, 20);
    }

    void CreateEventLog()
    {
        eventLog = ui.root.CreateChild("UIElement");

        // Position the text relative to the screen center
        eventLog.horizontalAlignment = HA_LEFT;
        eventLog.verticalAlignment = VA_BOTTOM;
        eventLog.SetPosition(20, -100);

        for (int i = 0; i < 20; i++) {
            Text@ oneLine = eventLog.CreateChild("Text");
            oneLine.text = "";//String(i) + "element";
            oneLine.SetFont(cache.GetResource("Font", GUI_FONT), GUI_FONT_SIZE);
            oneLine.textAlignment = HA_CENTER; // Center rows in relation to each other

            // Position the text relative to the screen center
            oneLine.horizontalAlignment = HA_LEFT;
            oneLine.verticalAlignment = VA_BOTTOM;
            oneLine.SetPosition(0, i * -20);
            latestEvents.Push(oneLine);
        }
    }

    void HandleUpdateMissionsGUI(StringHash eventType, VariantMap& eventData)
    {
        log.Info("HandleUpdateMissionsGUI");
        for (uint i = 0; i < notesLines.length; i++) {
            notesLines[i].text = "";
        }
        for (uint i = 0; i < Missions::missionList.length; i++) {
            if (i < notesLines.length) {
                if (Missions::missionList[i].completed) {
                    notesLines[i].color = Color(0.1f, 0.9f, 0.1f);
                } else {
                    notesLines[i].color = Color(0.9f, 0.1f, 0.1f);
                }
                notesLines[i].text = Missions::missionList[i].shortDescription;
            }
        }
    }

    void HandleUpdateEventLog(StringHash eventType, VariantMap& eventData)
    {
        for (uint i = latestEvents.length - 1; i > 0; i--) {
            latestEvents[i].text = latestEvents[i-1].text;
        }
        latestEvents[0].text = eventData["Message"].GetString();
    }

    void HandleUpdateInventoryGUI(StringHash eventType, VariantMap& eventData)
    {
        String itemList = "";
        for (uint i = 0; i < Inventory::items.length; i++) {
            itemList += Inventory::items[i].name + ": " + Inventory::items[i].count + "\n";   
        }
        inventoryList.text = itemList;
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
        if (positionText !is null) {
            positionText.text = "X: " + String(cameraNode.worldPosition.x) + "\n" + "Y: " + String(cameraNode.worldPosition.y) + "\n" + "Z: " + String(cameraNode.worldPosition.z);
        }
    }
}