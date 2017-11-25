namespace MissionsGUI {
	const float MAX_OPACITY = 0.99;
	const String GUI_FONT = "Fonts/PainttheSky-Regular.otf";
    const int GUI_FONT_SIZE = Helpers::getHeightByPercentage(0.04);

	Sprite@ missionsSprite;
	Text@ missionText;

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
    }

    void Destroy()
    {
    	if (missionText !is null) {
    		missionText.Remove();
    	}
    	if (missionsSprite !is null) {
    		missionsSprite.Remove();
    	}
    }

    void Subscribe()
    {
        SubscribeToEvent("ToggleQuestLog", "MissionsGUI::HandleToggleQuestLog");
    }

    void HandleToggleQuestLog(StringHash eventType, VariantMap& eventData)
    {
    	if (missionsSprite.opacity == 0.0f) {
    		missionsSprite.opacity = MAX_OPACITY;
    		missionText.opacity = MAX_OPACITY;
    		missionText.text = Missions::GetActiveMission().description;
    	} else {
    		missionsSprite.opacity = 0.0f;
    		missionText.opacity = 0.0f;
    	}
    }
}