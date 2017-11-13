namespace MenuScreen {

    Sprite@ fromSprite;
    Sprite@ toSprite;
    Sprite@ mapSprite;
    Sprite@ boardSprite;
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

    float scale = 1.1f;
    bool zoomIn = true;

    float rotation = 0.0f;
    bool clockwise = true;

    Vector2 boardInitialPosition;
    Vector2 boardDirection;

    void CreateBoard()
    {
        boardSprite = ui.root.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/board.jpg");
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        boardSprite.texture = logoTexture;

        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;

        // Set logo sprite scale
        boardSprite.SetScale(1);

        // Set logo sprite size
        boardSprite.SetSize(textureWidth, textureHeight);

        //mapSprite.position = Vector2(textureWidth/2, -textureHeight/2);

        // Set logo sprite hot spot
        boardSprite.SetHotSpot(textureWidth / 2, textureHeight / 2);

        // Set logo sprite alignment
        boardSprite.SetAlignment(HA_CENTER, VA_CENTER);
        //mapSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        boardSprite.opacity = 1.0;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        boardSprite.priority = -110;

        boardInitialPosition = boardSprite.position;
        boardDirection = Vector2(-0.4, -0.7);
    }

    void CreateScreen()
    {
        input.mouseVisible = true;

        CreateBoard();

        mapSprite = boardSprite.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/world_map.jpg");
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        mapSprite.texture = logoTexture;

        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;

        // Set logo sprite scale
        mapSprite.SetScale(scale);

        toLocation * mapSprite.scale.length;
        fromLocation * mapSprite.scale.length;

        // Set logo sprite size
        mapSprite.SetSize(textureWidth, textureHeight);

        //mapSprite.position = Vector2(textureWidth/2, -textureHeight/2);

        // Set logo sprite hot spot
        mapSprite.SetHotSpot(textureWidth / 2, textureHeight / 2);

        // Set logo sprite alignment
        mapSprite.SetAlignment(HA_CENTER, VA_CENTER);
        //mapSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

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
        UnsubscribeFromEvents(startButton);
        Destroy();
        SetLoadingText();
        DelayedExecute(1.0, false, "void MenuScreen::StartGame()");
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
        if (boardSprite !is null) {
            boardSprite.Remove();
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        if (zoomIn) {
            scale += timeStep / 50.0f;
            if (scale > 2.0f) {
                zoomIn = false;
            }
        } else {
            scale -= timeStep / 50.0f;
            if (scale < 0.8f) {
                zoomIn = true;
            }
        }
        if (clockwise) {
            rotation += timeStep;
            if (rotation > 5.0f) {
                clockwise = false;
            }
        } else {
            rotation -= timeStep;
            if (rotation < -5.0f) {
                clockwise = true;
            }
        }
        Vector2 boardDiff = boardInitialPosition - boardSprite.position;
        boardSprite.position -= boardDirection * timeStep * 10.0f;
        if (boardDiff.x < -100) {
            boardDirection.x  = 1;
        }
        if (boardDiff.x > 100) {
            boardDirection.x = -1;
        }
        if (boardDiff.y < -100) {
            boardDirection.y = 1;
        }
        if (boardDiff.y > 100) {
            boardDirection.y = -1;
        }

        boardSprite.rotation = rotation;
        boardSprite.SetScale(scale);
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
