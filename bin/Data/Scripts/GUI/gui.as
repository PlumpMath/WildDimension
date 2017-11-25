#include "GUI/notifications.as"
#include "GUI/missions.as"

namespace GUIHandler {

    const String GUI_FONT = "Fonts/PainttheSky-Regular.otf";
    const int GUI_FONT_SIZE = Helpers::getHeightByPercentage(0.03);
    const int GUI_NOTES_FONT_SIZE = Helpers::getHeightByPercentage(0.03);
    const int GUI_TIPS_FONT_SIZE = Helpers::getHeightByPercentage(0.03);

    const float MAX_OPACITY = 0.99f;

    Text@ bytesIn;
    Text@ bytesOut;
    Text@ inventoryList;
    Text@ spawnerDebug;
    UIElement@ eventLog;
    Array<Text@> latestEvents;

    Sprite@ notesSprite;
    Array<Text@> notesLines;

    Text@ positionText;

    class Tip {
        Sprite@ sprite;
        Text@ text;
        float lifetime;
    };
    Tip tip;

    Sprite@ crosshair;

    void CreateGUI()
    {
        MissionsGUI::Init();

        CreateNetworkTrafficDebug();
        CreateInventory();
        CreateEventLog();
        CreatePositionText();
        CreateNotes();
        CreateDreamCloudSprite();

        Notifications::Init();

        Subscribe();
        RegisterConsoleCommands();
        CreateCrosshair();

        CreateSpawnerDebug();
    }

    void CreateCrosshair()
    {
        if (engine.headless) {
            return;
        }
        // Get logo texture
        Texture2D@ texture = cache.GetResource("Texture2D", "Textures/crosshair.png");
        if (texture is null)
            return;

        // Create logo sprite and add to the UI layout
        crosshair = ui.root.CreateChild("Sprite");

        // Set logo sprite texture
        crosshair.texture = texture;

        int textureWidth = texture.width;
        int textureHeight = texture.height;

        // Set logo sprite scale
        crosshair.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        crosshair.SetSize(textureWidth, textureHeight);

        // Set logo sprite hot spot
        crosshair.SetHotSpot(textureWidth/2, textureHeight/2);

        // Set logo sprite alignment
        crosshair.SetAlignment(HA_CENTER, VA_CENTER);

        // Make logo not fully opaque to show the scene underneath
        crosshair.opacity = 0.3f;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        crosshair.priority = -100;
    }

    void CreateDreamCloudSprite()
    {
        if (engine.headless) {
            return;
        }
        // Get logo texture
        Texture2D@ texture = cache.GetResource("Texture2D", "Textures/dream_cloud.png");
        if (texture is null)
            return;

        // Create logo sprite and add to the UI layout
        tip.sprite = ui.root.CreateChild("Sprite");

        // Set logo sprite texture
        tip.sprite.texture = texture;

        int textureWidth = Helpers::getWidthByPercentage(0.3);
        int textureHeight = texture.height * Helpers::getRatio(texture.width, textureWidth);

        // Set logo sprite size
        tip.sprite.SetSize(textureWidth, textureHeight);

        // Set logo sprite hot spot
        tip.sprite.SetHotSpot(textureWidth, 0);

        // Set logo sprite alignment
        tip.sprite.SetAlignment(HA_RIGHT, VA_TOP);

        // Make logo not fully opaque to show the scene underneath
        tip.sprite.opacity = 0.0f;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        tip.sprite.priority = -100;
        tip.sprite.position = Vector2(-Helpers::getHeightByPercentage(0.07), Helpers::getHeightByPercentage(0.07));

        tip.text = tip.sprite.CreateChild("Text");
        tip.text.text = "";//String(i) + "element";
        tip.text.SetFont(cache.GetResource("Font", GUI_FONT), GUI_TIPS_FONT_SIZE);
        tip.text.textAlignment = HA_LEFT; // Center rows in relation to each other
        tip.text.color = Color(0.5, 0.5, 0.5);

        // Position the text relative to the screen center
        tip.text.horizontalAlignment = HA_LEFT;
        tip.text.verticalAlignment = VA_TOP;
        tip.text.SetPosition(Helpers::getHeightByPercentage(0.16), Helpers::getHeightByPercentage(0.08));
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

        float w = graphics.width;
        int textureWidth = Helpers::getWidthByPercentage(0.15);
        int textureHeight = notesTexture.height * Helpers::getRatio(notesTexture.width, textureWidth);

        // Set logo sprite scale
        //notesSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        notesSprite.SetSize(textureWidth, textureHeight);
        notesSprite.position = Vector2(-Helpers::getWidthByPercentage(0.02), -Helpers::getWidthByPercentage(0.02));

        // Set logo sprite hot spot
        notesSprite.SetHotSpot(textureWidth, textureHeight);

        // Set logo sprite alignment
        notesSprite.SetAlignment(HA_RIGHT, VA_BOTTOM);

        // Make logo not fully opaque to show the scene underneath
        notesSprite.opacity = MAX_OPACITY;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        notesSprite.priority = -100;

        UIElement@ missions = notesSprite.CreateChild("UIElement");

        // Position the text relative to the screen center
        missions.horizontalAlignment = HA_LEFT;
        missions.verticalAlignment = VA_TOP;
        missions.SetPosition(Helpers::getWidthByPercentage(0.01), Helpers::getWidthByPercentage(0.01));

        for (int i = 0; i < 10; i++) {
            Text@ oneLine = missions.CreateChild("Text");
            oneLine.text = "Item " + i;//String(i) + "element";
            oneLine.SetFont(cache.GetResource("Font", GUI_FONT), GUI_NOTES_FONT_SIZE);
            oneLine.textAlignment = HA_LEFT; // Center rows in relation to each other
            oneLine.color = Color(1, 0, 0);

            // Position the text relative to the screen center
            oneLine.horizontalAlignment = HA_LEFT;
            oneLine.verticalAlignment = VA_TOP;
            oneLine.SetPosition(Helpers::getWidthByPercentage(0.015), i * GUI_NOTES_FONT_SIZE + 2);
            notesLines.Push(oneLine);
        }
    }

    void Subscribe()
    {
        SubscribeToEvent("UpdateInventoryGUI", "GUIHandler::HandleUpdateInventoryGUI");
        SubscribeToEvent("UpdateEventLogGUI", "GUIHandler::HandleUpdateEventLog");
        SubscribeToEvent("UpdateMissionsGUI", "GUIHandler::HandleUpdateMissionsGUI");
        SubscribeToEvent("UpdateSpawnerDebug", "GUIHandler::HandleUpdateSpawnerDebug");

        SubscribeToEvent("ShowTip", "GUIHandler::HandleShowTip");
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
        MissionsGUI::Destroy();
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
        if (tip.sprite !is null) {
            tip.sprite.Remove();
        }
        if (tip.text !is null) {
            tip.text.Remove();
        }
        if (crosshair !is null) {
            crosshair.Remove();
        }
        if (spawnerDebug !is null) {
            spawnerDebug.Remove();
        }

        latestEvents.Clear();
        notesLines.Clear();
        Notifications::Destroy();
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
        inventoryList.SetPosition(-Helpers::getWidthByPercentage(0.015), -Helpers::getHeightByPercentage(0.45));
    }

    void CreateSpawnerDebug()
    {
        spawnerDebug = ui.root.CreateChild("Text");
        spawnerDebug.text = "";
        spawnerDebug.SetFont(cache.GetResource("Font", GUI_FONT), GUI_FONT_SIZE);
        spawnerDebug.textAlignment = HA_LEFT; // Center rows in relation to each other

        // Position the text relative to the screen center
        spawnerDebug.horizontalAlignment = HA_RIGHT;
        spawnerDebug.verticalAlignment = VA_TOP;
        spawnerDebug.SetPosition(-Helpers::getWidthByPercentage(0.015), Helpers::getWidthByPercentage(0.015));
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
        if (notesLines.length == 0) {
            return;
        }
        for (uint i = 0; i < notesLines.length; i++) {
            notesLines[i].text = "";
        }
        Missions::MissionItem missionItem  = Missions::GetActiveMission();
        if (missionItem.type == Missions::TYPE_PICKUP || missionItem.type == Missions::TYPE_USE_ITEM) {
            Craft::Recipe recipe = Craft::GetRecipe(missionItem.itemName);
            if (recipe.name.length > 0) {
                notesLines[0].text = missionItem.itemName + ":";
                notesLines[0].color = Color(0.2, 0.2, 0.2);
                for (uint i = 0; i < recipe.items.length; i++) {
                    notesLines[i + 1].text = "  * " + Inventory::GetItemCount(recipe.items[i].name) + "/" + recipe.items[i].count + " " + recipe.items[i].name;
                    notesLines[i + 1].color = Color(0.3, 0.3, 0.3);
                }
                notesLines[recipe.items.length + 2].text = "Press '" + recipe.shortcutKey + "'";
                notesLines[recipe.items.length + 2].color = Color(0.6, 0.3, 0,3);
                notesLines[recipe.items.length + 3].text = "to craft it!";
                notesLines[recipe.items.length + 3].color = Color(0.6, 0.3, 0,3);
            }
        }
    }

    void HandleUpdateEventLog(StringHash eventType, VariantMap& eventData)
    {
        if (latestEvents.length == 0) {
            return;
        }
        for (uint i = latestEvents.length - 1; i > 0; i--) {
            latestEvents[i].text = latestEvents[i-1].text;
        }
        latestEvents[0].text = eventData["Message"].GetString();

        //eventData["Type"] = Notifications::NOTIFICATION_TYPE_GOOD;
        //SendEvent("AddNotification", eventData);
    }

    void HandleUpdateInventoryGUI(StringHash eventType, VariantMap& eventData)
    {
        String itemList = "";
        for (uint i = 0; i < Inventory::items.length; i++) {
            itemList += Inventory::items[i].name + ": " + Inventory::items[i].count + "\n";   
        }
        inventoryList.text = itemList;
    }

    void HandleShowTip(StringHash eventType, VariantMap& eventData)
    {
        String message = eventData["MESSAGE"].GetString();
        tip.lifetime = 30.0f;
        tip.text.text = message;
        log.Info("Showing tip: " + message);
    }

    void HandleUpdateSpawnerDebug(StringHash eventType, VariantMap& eventData)
    {
        if (spawnerDebug is null) {
            return;
        }
        spawnerDebug.text = "Spawners: " + Spawn::GetSpawnersCount();
        spawnerDebug.text += "\nUnits spawned: " + Spawn::GetSpawnedUnitsCount();
        spawnerDebug.text += "\nCloud units: " + Spawn::GetSpawnedUnitsCountByType(Spawn::SPAWN_UNIT_CLOUD);
        spawnerDebug.text += "\nRock units: " + Spawn::GetSpawnedUnitsCountByType(Spawn::SPAWN_UNIT_ROCK);
        spawnerDebug.text += "\nSnake units: " + Spawn::GetSpawnedUnitsCountByType(Spawn::SPAWN_UNIT_SNAKE);
        spawnerDebug.text += "\nPacman units: " + Spawn::GetSpawnedUnitsCountByType(Spawn::SPAWN_UNIT_PACMAN);
        spawnerDebug.text += "\nGrass units: " + Spawn::GetSpawnedUnitsCountByType(Spawn::SPAWN_UNIT_GRASS);
        spawnerDebug.text += "\nApple units: " + Spawn::GetSpawnedUnitsCountByType(Spawn::SPAWN_UNIT_APPLE);
        spawnerDebug.text += "\nRaspberry units: " + Spawn::GetSpawnedUnitsCountByType(Spawn::SPAWN_UNIT_RASPBERRY);
        spawnerDebug.text += "\nTetris units: " + EnvObjects::timedObjects.length;
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        if (tip.lifetime > 1) {
            if (tip.sprite.opacity < MAX_OPACITY) {
                tip.sprite.opacity += timeStep;
                if (tip.sprite.opacity > MAX_OPACITY) {
                    tip.sprite.opacity = MAX_OPACITY;
                }
                tip.text.opacity = tip.sprite.opacity;
            }
            tip.lifetime -= timeStep;
        } else if (tip.lifetime <= 1 && tip.lifetime > 0) {
            tip.lifetime -= timeStep;
            tip.sprite.opacity -= timeStep;
            if (tip.lifetime < 0) {
                tip.lifetime = 0;
            }
            if (tip.sprite.opacity < 0) {
                tip.sprite.opacity = 0;
            }
            tip.text.opacity = tip.sprite.opacity;
        }

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

        Notifications::HandleUpdate(eventType, eventData);

        if (input.keyPress[KEY_TAB]) {
            SendEvent("ToggleQuestLog");
        }
    }
}