namespace MenuScreen {

    Sprite@ fromSprite;
    Sprite@ toSprite;
    Sprite@ mapSprite;
    Array<Sprite@> path;
    Vector2 fromLocation(190, 220);
    Vector2 toLocation(410, 380);
    const float DRAW_PATH_TIMEOUT = 0.1f;
    Vector2 direction = Vector2(1, 0);
    
    const float DOT_MARGIN = 20.0f;
    const float PATH_FILL_SPEED = 1.0f;

    Button@ startButton;
    Button@ exitButton;
    Text@ loadingText;
    bool started = false;

    void CreateScreen()
    {
        input.mouseVisible = true;
        mapSprite = ui.root.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/world_map.jpg");
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        mapSprite.texture = logoTexture;

        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;

        // Set logo sprite scale
        mapSprite.SetScale(1);

        toLocation * mapSprite.scale.length;
        fromLocation * mapSprite.scale.length;

        // Set logo sprite size
        mapSprite.SetSize(textureWidth, textureHeight);

        //mapSprite.position = Vector2(textureWidth/2, -textureHeight/2);

        // Set logo sprite hot spot
        //mapSprite.SetHotSpot(textureWidth / 2, textureHeight / 2);

        // Set logo sprite alignment
        mapSprite.SetAlignment(HA_CENTER, VA_CENTER);
        mapSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        mapSprite.opacity = 1.0;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        mapSprite.priority = -100;

        SubscribeToEvent("Update", "MenuScreen::HandleUpdate");

        CreateFromSprite();
        CreateToSprite();
        CreatePath();

        CreateButtons();
    }

    void CreateButtons()
    {
        XMLFile@ uiStyle = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
        // Set style to the UI root so that elements will inherit it
        ui.root.defaultStyle = uiStyle;

        Font@ font = cache.GetResource("Font", GUIHandler::GUI_FONT);

        // Create the button and center the text onto it
        startButton = ui.root.CreateChild("Button");
        startButton.SetStyleAuto();
        startButton.SetPosition(-20, -80);
        startButton.SetSize(100, 40);
        startButton.SetAlignment(HA_RIGHT, VA_BOTTOM);

        Text@ startButtonText = startButton.CreateChild("Text");
        startButtonText.SetAlignment(HA_CENTER, VA_CENTER);
        startButtonText.SetFont(font, 30);
        startButtonText.text = "Start";
        SubscribeToEvent(startButton, "Released", "MenuScreen::HandleNewGame");

        // Create the button and center the text onto it
        exitButton = ui.root.CreateChild("Button");
        exitButton.SetStyleAuto();
        exitButton.SetPosition(-20, -20);
        exitButton.SetSize(100, 40);
        exitButton.SetAlignment(HA_RIGHT, VA_BOTTOM);

        Text@ exitButtonText = exitButton.CreateChild("Text");
        exitButtonText.SetAlignment(HA_CENTER, VA_CENTER);
        exitButtonText.SetFont(font, 30);
        exitButtonText.text = "Exit";
        SubscribeToEvent(exitButton, "Released", "MenuScreen::HandleExitGame");
    }

    void HandleNewGame(StringHash eventType, VariantMap& eventData)
    {
        Destroy();
        SetLoadingText();
        DelayedExecute(2.0, false, "void MenuScreen::StartGame()");
    }

    void StartGame()
    {
        Destroy();
        if (!started) {
            SendEvent("NewGame");
            started = true;
        }
    }

    void HandleExitGame(StringHash eventType, VariantMap& eventData)
    {
        engine.Exit();
    }

    void SetLoadingText()
    {
        loadingText = ui.root.CreateChild("Text");
        loadingText.text = "Please wait... Crashing the plane...";
        loadingText.SetFont(cache.GetResource("Font", "Fonts/PainttheSky-Regular.otf"), 40);
        loadingText.textAlignment = HA_CENTER; // Center rows in relation to each other

        // Position the text relative to the screen center
        loadingText.horizontalAlignment = HA_RIGHT;
        loadingText.verticalAlignment = VA_BOTTOM;
        loadingText.SetPosition(-20, -20);
    }

    void CreateFromSprite()
    {
        fromSprite = mapSprite.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/map_marker.png");
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        fromSprite.texture = logoTexture;

        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;

        // Set logo sprite scale
        //logoSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        fromSprite.SetSize(textureWidth/2, textureHeight/2);

        fromSprite.position = fromLocation;

        // Set logo sprite hot spot
        fromSprite.SetHotSpot(fromSprite.size.x/2, fromSprite.size.y);

        // Set logo sprite alignment
        fromSprite.SetAlignment(HA_LEFT, VA_TOP);
        //fromSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        fromSprite.opacity = 1.0;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        fromSprite.priority = -80;
    }

    void CreateToSprite()
    {
        toSprite = mapSprite.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/map_destination.png");
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        toSprite.texture = logoTexture;

        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;

        // Set logo sprite scale
        //logoSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        //toSprite.SetSize(textureWidth/2, textureHeight/2);
        toSprite.SetSize(textureWidth/2, textureHeight/2);

        toSprite.position = toLocation;

        // Set logo sprite hot spot
        toSprite.SetHotSpot(toSprite.size.x/2, toSprite.size.y);

        // Set logo sprite alignment
        toSprite.SetAlignment(HA_LEFT, VA_TOP);
        //toSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        toSprite.opacity = 1.0;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        toSprite.priority = -80;
    }

    void CreatePath()
    {
        bool reached = false;
        Vector2 position = fromSprite.position;
        while (!reached) {
            Sprite@ sprite = mapSprite.CreateChild("Sprite");
            Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/map_dot.png");
            //if (logoTexture is null)
              //  return;

            // Set logo sprite texture
            sprite.texture = logoTexture;

            int textureWidth = logoTexture.width;
            int textureHeight = logoTexture.height;

            // Set logo sprite scale
            //logoSprite.SetScale(256.0f / textureWidth);

            // Set logo sprite size
            //toSprite.SetSize(textureWidth/2, textureHeight/2);
            sprite.SetSize(16, 16);

            sprite.position = position;

            // Set logo sprite hot spot
            //sprite.SetHotSpot(sprite.size.x/2, sprite.size.y);

            // Set logo sprite alignment
            sprite.SetAlignment(HA_LEFT, VA_TOP);
            //toSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

            // Make logo not fully opaque to show the scene underneath
            sprite.opacity = 0.0f;

            // Set a low priority for the logo so that other UI elements can be drawn on top
            sprite.priority = -80;

            Vector2 diff = toLocation - position;
            direction += diff / 200;
            if (direction.length > 0) {
                direction.Normalize();
            }
            position += direction * DOT_MARGIN;

            if (position.length > toLocation.length - 10) {
                reached = true;
            }
            path.Push(sprite);
        }
    }

    void Destroy()
    {
        if (mapSprite !is null) {
            mapSprite.Remove();
        }
        if (toSprite !is null) {
            toSprite.Remove();
        }
        if (fromSprite !is null) {
            fromSprite.Remove();
        }
        if (startButton !is null) {
            startButton.Remove();
        }
        if (exitButton !is null) {
            exitButton.Remove();
        }
        if (loadingText !is null) {
            loadingText.Remove();
        }
    }

    void HandleMenuEnd()
    {
        Destroy();
        SendEvent("NewGame");
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        for (uint i = 0; i < path.length; i++) {
            if (i == 0) {
                if (path[i].opacity > 1.0f) {
                    path[i].opacity = 1.0f;
                }
                path[i].opacity += timeStep * PATH_FILL_SPEED;
            }
            if (i > 0) {
                if (path[i - 1].opacity > 0.5f) {
                    path[i].opacity += timeStep * PATH_FILL_SPEED;
                }
            }
        }
    }
}
