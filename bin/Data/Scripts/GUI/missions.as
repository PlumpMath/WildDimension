namespace MissionsGUI {
	const float MAX_OPACITY = 0.5;
	const String GUI_FONT = "Fonts/PainttheSky-Regular.otf";
    const int GUI_FONT_SIZE = Helpers::getHeightByPercentage(0.04);

	Sprite@ missionsSprite;
	Text@ missionText;
    Sprite@ instructionsScreen;

	void Init()
	{
		Create();
		Subscribe();
	}

	void Create()
    {
        // Get logo texture
        Texture2D@ notesTexture = cache.GetResource("Texture2D", "Textures/paper.jpg");
        if (notesTexture is null) {
            return;
        }

        // Create logo sprite and add to the UI layout
        missionsSprite = ui.root.CreateChild("Sprite");

        // Set logo sprite texture
        missionsSprite.texture = notesTexture;

        float w = graphics.width;
        int textureWidth = Helpers::getWidthByPercentage(0.5);
        int textureHeight = notesTexture.height * Helpers::getRatio(notesTexture.width, textureWidth);

        // Set logo sprite scale
        //notesSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        missionsSprite.SetSize(textureWidth, textureHeight);
        missionsSprite.position = Vector2(-Helpers::getWidthByPercentage(0.02), -Helpers::getWidthByPercentage(0.02));

        // Set logo sprite hot spot
        missionsSprite.SetHotSpot(textureWidth/2, textureHeight/2);

        // Set logo sprite alignment
        missionsSprite.SetAlignment(HA_CENTER, VA_CENTER);

        // Make logo not fully opaque to show the scene underneath
        missionsSprite.opacity = 0.0f;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        missionsSprite.priority = -100;

        missionText = missionsSprite.CreateChild("Text");
        missionText.text = "";
        missionText.opacity = 0.0f;
        missionText.color = Color(0, 0, 0);
        missionText.SetFont(cache.GetResource("Font", GUI_FONT), GUI_FONT_SIZE);
        missionText.SetAlignment(HA_CENTER, VA_CENTER);
        missionText.textAlignment = HA_CENTER; // Center rows in relation to each other

        CreateInstructions();
    }

    void Destroy()
    {
    	if (missionText !is null) {
    		missionText.Remove();
    	}
    	if (missionsSprite !is null) {
    		missionsSprite.Remove();
    	}
        if (instructionsScreen !is null) {
            instructionsScreen.Remove();
        }
    }

    void Subscribe()
    {
        SubscribeToEvent("ToggleQuestLog", "MissionsGUI::HandleToggleQuestLog");
        SubscribeToEvent("HideQuestLog", "MissionsGUI::HandleHideQuestLog");
        SubscribeToEvent("ToggleInstructions", "MissionsGUI::HandleToggleInstructions");
    }

    void HandleToggleQuestLog(StringHash eventType, VariantMap& eventData)
    {
    	if (missionsSprite.opacity == 0.0f) {
    		missionsSprite.opacity = MAX_OPACITY;
    		missionText.opacity = MAX_OPACITY;
    		missionText.text = Missions::GetActiveMission().longDescription;
    	} else {
    		missionsSprite.opacity = 0.0f;
    		missionText.opacity = 0.0f;
    	}
    }

    void HandleHideQuestLog(StringHash eventType, VariantMap& eventData)
    {
        missionsSprite.opacity = 0.0f;
        missionText.opacity = 0.0f;
    }

    void HandleToggleInstructions(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Toggling instructions");
        if (instructionsScreen.visible == false) {
            instructionsScreen.visible = true;
        } else {
            instructionsScreen.visible = false;
        }
    }

    void CreateInstructions()
    {
        Texture2D@ notesTexture = cache.GetResource("Texture2D", "Textures/Screens/Instruction.png");
        if (notesTexture is null) {
            return;
        }

        // Create logo sprite and add to the UI layout
        instructionsScreen = ui.root.CreateChild("Sprite");

        // Set logo sprite texture
        instructionsScreen.texture = notesTexture;

        float w = graphics.width;
        int textureHeight = Helpers::getHeightByPercentage(0.8);
        int textureWidth = notesTexture.width * Helpers::getRatio(notesTexture.height, textureHeight);

        // Set logo sprite scale
        //notesSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        instructionsScreen.SetSize(textureWidth, textureHeight);
        instructionsScreen.position = Vector2(0, 0);

        // Set logo sprite hot spot
        instructionsScreen.SetHotSpot(textureWidth/2, textureHeight/2);

        // Set logo sprite alignment
        instructionsScreen.SetAlignment(HA_CENTER, VA_CENTER);

        // Make logo not fully opaque to show the scene underneath
        instructionsScreen.opacity = MAX_OPACITY;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        instructionsScreen.priority = 100;
        instructionsScreen.visible = false;

        Text@ instructionsText = instructionsScreen.CreateChild("Text");
        instructionsText.text = "Show controls";
        instructionsText.SetFont(cache.GetResource("Font", "Fonts/PainttheSky-Regular.otf"), 40);
        instructionsText.textAlignment = HA_CENTER; // Center rows in relation to each other
        // Position the text relative to the screen center
        instructionsText.horizontalAlignment = HA_LEFT;
        instructionsText.verticalAlignment = VA_TOP;
        instructionsText.SetPosition(textureWidth * 0.2, textureHeight * 0.01);

        Text@ objectiveText = instructionsScreen.CreateChild("Text");
        objectiveText.text = "Show current objective";
        objectiveText.SetFont(cache.GetResource("Font", "Fonts/PainttheSky-Regular.otf"), 40);
        objectiveText.textAlignment = HA_CENTER; // Center rows in relation to each other
        // Position the text relative to the screen center
        objectiveText.horizontalAlignment = HA_LEFT;
        objectiveText.verticalAlignment = VA_TOP;
        objectiveText.SetPosition(textureWidth * 0.2, textureHeight * 0.15);

        Text@ toolText = instructionsScreen.CreateChild("Text");
        toolText.text = "Change active tool";
        toolText.SetFont(cache.GetResource("Font", "Fonts/PainttheSky-Regular.otf"), 40);
        toolText.textAlignment = HA_CENTER; // Center rows in relation to each other
        // Position the text relative to the screen center
        toolText.horizontalAlignment = HA_LEFT;
        toolText.verticalAlignment = VA_TOP;
        toolText.SetPosition(textureWidth * 0.2, textureHeight * 0.30);

        Text@ movementText = instructionsScreen.CreateChild("Text");
        movementText.text = "Move";
        movementText.SetFont(cache.GetResource("Font", "Fonts/PainttheSky-Regular.otf"), 40);
        movementText.textAlignment = HA_CENTER; // Center rows in relation to each other
        // Position the text relative to the screen center
        movementText.horizontalAlignment = HA_LEFT;
        movementText.verticalAlignment = VA_TOP;
        movementText.SetPosition(textureWidth * 0.4, textureHeight * 0.5);

        Text@ sprintText = instructionsScreen.CreateChild("Text");
        sprintText.text = "Sprint";
        sprintText.SetFont(cache.GetResource("Font", "Fonts/PainttheSky-Regular.otf"), 40);
        sprintText.textAlignment = HA_CENTER; // Center rows in relation to each other
        // Position the text relative to the screen center
        sprintText.horizontalAlignment = HA_LEFT;
        sprintText.verticalAlignment = VA_TOP;
        sprintText.SetPosition(textureWidth * 0.4, textureHeight * 0.72);

        Text@ jumpText = instructionsScreen.CreateChild("Text");
        jumpText.text = "Jump";
        jumpText.SetFont(cache.GetResource("Font", "Fonts/PainttheSky-Regular.otf"), 40);
        jumpText.textAlignment = HA_CENTER; // Center rows in relation to each other
        // Position the text relative to the screen center
        jumpText.horizontalAlignment = HA_LEFT;
        jumpText.verticalAlignment = VA_TOP;
        jumpText.SetPosition(textureWidth * 0.55, textureHeight * 0.86);
    }
}