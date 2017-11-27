namespace SplashScreen {

    Sprite@ logoSprite;
    Sprite@ backgroundSprite;
    float opacity; //current opacity
    bool show;
    const float FADE_SPEED = 10.5f; //How fast the logo should fade in and fade out
    bool ended = false;
    Array<String> textures;
    uint currentIndex = 0;
    int dirX = -1;
    int dirY = -1;
    float scaleFront = 1.0f;
    float scaleBack = 1.0f;
    const float SCALE_FRONT_SPEED = 0.00;
    const float SCALE_BACK_SPEED = 0.04;

    /**
     * List of all the logos which we need to show in the splash screen
     */
    void InitList()
    {
        textures.Push("Textures/Logo/logo.png");
        textures.Push("Textures/Logo/Game_logo.png");
    }

    void SetBackground()
    {
        backgroundSprite = ui.root.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/Logo/Game_logo_background.jpg");
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        backgroundSprite.texture = logoTexture;
        //backgroundSprite.blendMode = BLEND_SUBTRACTALPHA;

        float textureWidth = logoTexture.width;
        float textureHeight = logoTexture.height;

        // Set logo sprite scale
        //backgroundSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        float width = graphics.width * 0.6;
        float ratio = width / textureWidth;
        int newWidth = width;
        int newHeight = textureHeight * ratio;
        backgroundSprite.SetSize(newWidth, newHeight);

        //backgroundSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Set logo sprite hot spot
        backgroundSprite.SetHotSpot(newWidth / 2, newHeight / 2);

        // Set logo sprite alignment
        backgroundSprite.SetAlignment(HA_CENTER, VA_CENTER);
        //logoSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        backgroundSprite.opacity = 0.0;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        backgroundSprite.priority = -110;
    }

    void SetTexture()
    {
        Destroy();
        logoSprite = ui.root.CreateChild("Sprite");
        if (currentIndex == 1) {
            SetBackground();
        }
        Texture2D@ logoTexture = cache.GetResource("Texture2D", textures[currentIndex]);
        logoSprite.texture = logoTexture;

        float textureWidth = logoTexture.width;
        float textureHeight = logoTexture.height;

        // Set logo sprite scale
        //logoSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        float width = graphics.width * 0.8;
        float ratio = width / textureWidth;
        int newWidth = width;
        int newHeight = textureHeight * ratio;
        logoSprite.SetSize(newWidth, newHeight);

        //logoSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Set logo sprite hot spot
        logoSprite.SetHotSpot(newWidth / 2, newHeight / 2);

        // Set logo sprite alignment
        logoSprite.SetAlignment(HA_CENTER, VA_CENTER);
        //logoSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        logoSprite.opacity = opacity;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        logoSprite.priority = -100;
        //DelayedExecute(10.0, false, "void SplashScreen::HandleSplashEnd()");

    }

    void CreateSplashScreen()
    {
        InitList();
        opacity = 0.f;
        show = true;

        SubscribeToEvent("Update", "SplashScreen::HandleUpdate");

        SetTexture();
    }

    void Destroy()
    {
        if (logoSprite !is null) {
            logoSprite.Remove();
        }
        if (backgroundSprite !is null) {
            backgroundSprite.Remove();
        }
    }

    void HandleSplashEnd()
    {
        Destroy();
        SendEvent("SplashScreenEnd");
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        if (show) {
            opacity += timeStep * FADE_SPEED;
            if (opacity > 0.99f) {
                opacity = 0.99f;
                show = false;
            }
        } else if (!ended) {
            opacity -= timeStep * FADE_SPEED;
            if (opacity < 0.0f) {
                opacity = 0.0f;
                currentIndex++;
                if (currentIndex >= textures.length) {
                    ended = true;
                    HandleSplashEnd();
                } else {
                    show = true;
                    SetTexture();
                }
            }
        }
        if (backgroundSprite !is null) {
            if (opacity > 0.99f) {
                opacity = 0.99f;
            }
            backgroundSprite.opacity = opacity;
            logoSprite.opacity = 1.0f;
            scaleBack += timeStep * SCALE_BACK_SPEED;
            scaleFront += timeStep * SCALE_FRONT_SPEED;

            backgroundSprite.SetScale(scaleBack);
            logoSprite.SetScale(scaleFront);
        } else {
            if (opacity > 0.99f) {
                opacity = 0.99f;
            }
            logoSprite.opacity = opacity;
        }
    }
}
