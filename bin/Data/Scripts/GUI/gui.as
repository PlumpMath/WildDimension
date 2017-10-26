namespace GUIHandler {
    Sprite@ logoSprite;

    void CreateGUI()
    {
        CreateLogo();
    }

    void CreateLogo()
    {
        if (engine.headless) {
            return;
        }
        log.Info("Creating logo");
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
            log.Info("Removing logo");
            logoSprite.Remove();
            logoSprite = null;
        }
    }

    void Subscribe()
    {
        SubscribeToEvent("ToggleLogo", "GUIHandler::ToggleLogo");
    }

    void Destroy()
    {
        RemoveLogo();
    }

    void ToggleLogo()
    {
        log.Info("Toggling logo");
        if (logoSprite !is null) {
            RemoveLogo();
        } else {
            CreateLogo();
        }
    }
}