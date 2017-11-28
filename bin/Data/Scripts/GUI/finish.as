namespace FinishGUI {
	const String FINISH_GUI_FONT = "Fonts/PainttheSky-Regular.otf";
    const int FINISH_GUI_FONT_SIZE = Helpers::getHeightByPercentage(0.04);

    Sprite@ scoreboard;
    Array<Text@> scoreboardLines;

    void CreateScore()
    {
        Destroy();
        VariantMap data;
        data["Hour"] = 0;
        SendEvent("HourChange", data);
        if (engine.headless) {
            return;
        }
        // Get logo texture
        Texture2D@ notesTexture = cache.GetResource("Texture2D", "Textures/notes.png");
        if (notesTexture is null) {
            return;
        }

        // Create logo sprite and add to the UI layout
        scoreboard = ui.root.CreateChild("Sprite");

        // Set logo sprite texture
        //scoreboard.texture = notesTexture;

        int textureWidth = Helpers::getWidthByPercentage(0.3);
        int textureHeight = notesTexture.height * Helpers::getRatio(notesTexture.width, textureWidth);

        // Set logo sprite scale
        //scoreboard.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        //scoreboard.SetSize(textureWidth, textureHeight);
        scoreboard.position = Vector2(-Helpers::getWidthByPercentage(0.015), -Helpers::getWidthByPercentage(0.015));

        // Set logo sprite hot spot
        scoreboard.SetHotSpot(textureWidth/2, textureHeight/2);

        // Set logo sprite alignment
        scoreboard.SetAlignment(HA_CENTER, VA_CENTER);

        // Make logo not fully opaque to show the scene underneath
        scoreboard.opacity = 1.0f;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        scoreboard.priority = -100;

        UIElement@ lines = scoreboard.CreateChild("UIElement");

        // Position the text relative to the screen center
        lines.horizontalAlignment = HA_LEFT;
        lines.verticalAlignment = VA_TOP;
        lines.SetPosition(Helpers::getWidthByPercentage(0.07), Helpers::getWidthByPercentage(0.01));

        for (int i = 0; i < 6; i++) {
            Text@ oneLine = lines.CreateChild("Text");
            oneLine.text = "";//String(i) + "element";
            oneLine.SetFont(cache.GetResource("Font", FINISH_GUI_FONT), FINISH_GUI_FONT_SIZE);
            oneLine.textAlignment = HA_LEFT; // Center rows in relation to each other
            oneLine.color = Color(0.3, 0.8, 0.3);

            // Position the text relative to the screen center
            oneLine.horizontalAlignment = HA_LEFT;
            oneLine.verticalAlignment = VA_TOP;
            oneLine.SetPosition(-Helpers::getWidthByPercentage(0.02), i * FINISH_GUI_FONT_SIZE + 2);
            scoreboardLines.Push(oneLine);
        }

        scoreboardLines[0].text = "Day 1 survived!";
        int gameTime = NetworkHandler::stats.gameTime;
        int minutes = gameTime / 60;
        String minutesString = minutes;
        if (minutes < 10) {
            minutesString = "0" + minutesString;
        }
        int seconds = gameTime - minutes * 60;
        String secondsString = seconds;
        if (seconds < 10) {
            secondsString = "0" + secondsString;
        }

        scoreboardLines[2].text = "Game time: " + minutesString + ":" + secondsString;
        scoreboardLines[3].text = "Achievements total: " + Achievements::GetTotalAchievementsCount();
        scoreboardLines[4].text = "Achievements unlocked: " + Achievements::GetCompletedAchievementsCount();
    }

    void Subscribe()
    {
        SubscribeToEvent("GameFinished", "FinishGUI::HandleGameFinished");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "finish";
        data["CONSOLE_COMMAND_EVENT"] = "GameFinished";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandleGameFinished(StringHash eventType, VariantMap& eventData)
    {
        NetworkHandler::GameEnd();
    	CreateScore();
    	GUIHandler::Destroy();
    }

    void Destroy()
    {
 		if (scoreboard !is null) {
 			scoreboard.Remove();
 		}   	
    }
}