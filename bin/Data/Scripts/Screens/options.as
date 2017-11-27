namespace Options {
    const float MAX_OPACITY = 0.99f;
    Sprite@ optionsSprite;

    void Create()
    {
        // Get logo texture
        Texture2D@ notesTexture = cache.GetResource("Texture2D", "Textures/paper.png");
        if (notesTexture is null) {
            return;
        }

        // Create logo sprite and add to the UI layout
        optionsSprite = ui.root.CreateChild("Sprite");

        // Set logo sprite texture
        optionsSprite.texture = notesTexture;

        float w = graphics.width;
        int textureWidth = Helpers::getWidthByPercentage(0.5);
        int textureHeight = notesTexture.height * Helpers::getRatio(notesTexture.width, textureWidth);

        // Set logo sprite scale
        //notesSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        optionsSprite.SetSize(textureWidth, textureHeight);
        optionsSprite.position = Vector2(-Helpers::getWidthByPercentage(0.02), -Helpers::getWidthByPercentage(0.02));

        // Set logo sprite hot spot
        optionsSprite.SetHotSpot(textureWidth/2, textureHeight/2);

        // Set logo sprite alignment
        optionsSprite.SetAlignment(HA_CENTER, VA_CENTER);

        // Make logo not fully opaque to show the scene underneath
        optionsSprite.opacity = MAX_OPACITY;
        optionsSprite.visible = false;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        optionsSprite.priority = 100;
    }

    void Destroy()
    {
        if (optionsSprite !is null) {
            optionsSprite.Remove();
        }
    }

    void Show()
    {
        optionsSprite.visible = true;
    }

    void Hide()
    {
        optionsSprite.visible = false;
    }
}