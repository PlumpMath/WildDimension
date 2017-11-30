#include "Screens/options.as"

namespace MenuScreen {

    const float MAX_OPACITY = 0.99f;
    const String GUI_FONT = "Fonts/PainttheSky-Regular.otf";
    const int GUI_FONT_SIZE = Helpers::getHeightByPercentage(0.04);
    const int GUI_FONT_SIZE_STORY = Helpers::getHeightByPercentage(0.026);
    const float INSTRUCTION_TIME = 5.0f;

    Sprite@ fromSprite;
    Sprite@ toSprite;
    Sprite@ mapSprite;
    Sprite@ boardSprite;
    Sprite@ pencilSprite;
    Array<Sprite@> path;
    Vector2 fromLocation(190, 220);
    Vector2 toLocation(410, 380);
    const float DRAW_PATH_TIMEOUT = 0.1f;
    Vector2 direction = Vector2(1, 0);

    Array<Button@> buttons;

    Sprite@ instructionsScreen;
    
    const float DOT_MARGIN = 20.0f;
    const float PATH_FILL_SPEED = 1.0f;

    Button@ storyCloseButton;

    Sprite@ storySprite;
    Text@ storyText;

    Text@ loadingText;
    bool started = false;

    float scale = 1.1f;
    bool zoomIn = true;

    float rotation = 0.0f;
    bool clockwise = true;

    Vector2 boardInitialPosition;
    Vector2 boardDirection;

    void AddSpriteToTable(Vector2 position, float rotation, String texture, int priority)
    {
        Sprite@ sprite = boardSprite.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", texture);
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        sprite.texture = logoTexture;

        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;

        // Set logo sprite scale
        sprite.SetScale(1);

        // Set logo sprite size
        sprite.SetSize(textureWidth, textureHeight);

        //mapSprite.position = Vector2(textureWidth/2, -textureHeight/2);

        // Set logo sprite hot spot
        sprite.SetHotSpot(textureWidth / 2, textureHeight / 2);

        // Set logo sprite alignment
        sprite.SetAlignment(HA_CENTER, VA_CENTER);
        //mapSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        sprite.opacity = MAX_OPACITY;
        sprite.position = position;
        sprite.blendMode = BLEND_REPLACE;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        sprite.priority = priority;
        sprite.rotation = rotation;
    }

    void CreateStory()
    {
        // Get logo texture
        Texture2D@ notesTexture = cache.GetResource("Texture2D", "Textures/paper.png");
        if (notesTexture is null) {
            return;
        }

        // Create logo sprite and add to the UI layout
        storySprite = ui.root.CreateChild("Sprite");

        // Set logo sprite texture
        storySprite.texture = notesTexture;

        float w = graphics.width;
        int textureWidth = Helpers::getWidthByPercentage(0.5);
        int textureHeight = notesTexture.height * Helpers::getRatio(notesTexture.width, textureWidth);

        // Set logo sprite scale
        //notesSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        storySprite.SetSize(textureWidth, textureHeight);
        storySprite.position = Vector2(-Helpers::getWidthByPercentage(0.02), -Helpers::getWidthByPercentage(0.02));

        // Set logo sprite hot spot
        storySprite.SetHotSpot(textureWidth/2, textureHeight/2);

        // Set logo sprite alignment
        storySprite.SetAlignment(HA_CENTER, VA_CENTER);

        // Make logo not fully opaque to show the scene underneath
        storySprite.opacity = MAX_OPACITY;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        storySprite.priority = 100;

        storyText = storySprite.CreateChild("Text");
        storyText.position = IntVector2(10, 10);
        storyText.text = "\n    Adventure seeker pilot decides to cross Pacific ocean with his private";
        storyText.text += "\njet. While flying over the ocean he comes across a hurricane which was not";
        storyText.text += "\nmentioned in the weather forecast. Hurricane becomes more powerful each";
        storyText.text += "\nsecond and the plane get's sucked in. Pilot is struggling to control";
        storyText.text += "\nhis plane and after some time losses consciousness when he hits his";
        storyText.text += "\nhead against one of the panels inside plane... He falls with his";
        storyText.text += "\nplane for a while when finally he's thrown back to the ground...";
        storyText.text += "\n\n    He wakes up the next day on a mysterious island. He's unable";
        storyText.text += "\nto locate the island on the map, and everything about the island seems";
        storyText.text += "\na bit strange...  Will he survive the wilderness and reveal the secrets";
        storyText.text += "\nof the island? Will he be able to get back to civilization?";
        storyText.opacity = MAX_OPACITY;
        storyText.color = Color(0, 0, 0);
        storyText.SetFont(cache.GetResource("Font", GUI_FONT), GUI_FONT_SIZE_STORY);
        //storyText.SetAlignment(HA_CENTER, VA_CENTER);
        //storyText.textAlignment = HA_LEFT; // Center rows in relation to each other

        storySprite.visible = false;
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

    void FillTable()
    {
        AddSpriteToTable(Vector2(-500, 250), 22.0f, "Textures/notes.png", -60);
        AddSpriteToTable(Vector2(350, -150), -5.0f, "Textures/pencil.png", -60);
        AddSpriteToTable(Vector2(400, -300), -15.0f, "Textures/coffe.png", -60);
    }

    void CreateBoard()
    {
        boardSprite = ui.root.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/board.png");
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        boardSprite.texture = logoTexture;

        int textureWidth = Helpers::getWidthByPercentage(1.5);
        int textureHeight = logoTexture.height * Helpers::getRatio(logoTexture.width, textureWidth);

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
        boardSprite.opacity = MAX_OPACITY;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        boardSprite.priority = -110;

        boardInitialPosition = boardSprite.position;
        boardDirection = Vector2(-0.4, -0.7);

        FillTable();
    }

    void CreateScreen()
    {
        input.mouseVisible = true;

        CreateBoard();

        mapSprite = boardSprite.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/world_map.png");
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
        mapSprite.opacity = MAX_OPACITY;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        mapSprite.priority = -100;

        SubscribeToEvent("Update", "MenuScreen::HandleUpdate");

        CreateFromSprite();
        CreateToSprite();
        CreatePath();

        CreateStory();

        CreateButtons();

        Options::Create();
    }

    void CreateButtons()
    {
        Font@ font = cache.GetResource("Font", GUIHandler::GUI_FONT);

        XMLFile@ uiStyle = cache.GetResource("XMLFile", "UI/Menu.xml");

        CreateButton("Exit", "MenuScreen::HandleExitGame", IntVector2(-20, -20));
        CreateButton("Settings", "MenuScreen::HandleSettingsButton", IntVector2(-20, -80));
        CreateButton("Start", "MenuScreen::HandleNewGame", IntVector2(-20, -140));
        CreateButton("Story", "MenuScreen::HandleStory", IntVector2(20, -20), false);

        // Create the button and center the text onto it
        storyCloseButton = storySprite.CreateChild("Button");
        storyCloseButton.SetStyleAuto(uiStyle);
        storyCloseButton.SetPosition(0, 0);
        storyCloseButton.SetSize(100, 40);
        storyCloseButton.SetAlignment(HA_RIGHT, VA_BOTTOM);

        Text@ storyCloseButtonText = storyCloseButton.CreateChild("Text");
        storyCloseButtonText.SetAlignment(HA_CENTER, VA_TOP);
        storyCloseButtonText.SetFont(font, 30);
        storyCloseButtonText.textAlignment = HA_CENTER;
        storyCloseButtonText.text = "Close";
        storyCloseButtonText.position = IntVector2(0, -10);
        SubscribeToEvent(storyCloseButton, "Released", "MenuScreen::HandleStoryClose");
    }

    void CreateButton(String name, String handler, IntVector2 position, bool right = true)
    {
        Font@ font = cache.GetResource("Font", GUIHandler::GUI_FONT);

        XMLFile@ uiStyle = cache.GetResource("XMLFile", "UI/Menu.xml");

        Button@ button = ui.root.CreateChild("Button");
        button.SetStyleAuto(uiStyle);
        button.SetPosition(position.x, position.y);
        button.SetSize(100, 40);
        if (right) {
            button.SetAlignment(HA_RIGHT, VA_BOTTOM);
        } else {
            button.SetAlignment(HA_LEFT, VA_BOTTOM);
        }

        Text@ buttonText = button.CreateChild("Text");
        buttonText.SetAlignment(HA_CENTER, VA_TOP);
        buttonText.SetFont(font, 30);
        buttonText.textAlignment = HA_CENTER;
        buttonText.text = name;
        buttonText.position = IntVector2(0, -10);
        SubscribeToEvent(button, "Released", handler);
        buttons.Push(button);
    }

    void HandleSettingsButton(StringHash eventType, VariantMap& eventData)
    {
        Options::Show();
    }

    void HandleNewGame(StringHash eventType, VariantMap& eventData)
    {
        Destroy();
        CreateInstructions();
        SetLoadingText();
        DelayedExecute(INSTRUCTION_TIME, false, "void MenuScreen::StartGame()");
    }

    void HandleStory(StringHash eventType, VariantMap& eventData)
    {
        storySprite.visible = true;
    }

    void HandleStoryClose(StringHash eventType, VariantMap& eventData)
    {
        storySprite.visible = false;
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
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/map_destination.png");
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        fromSprite.texture = logoTexture;

        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;

        // Set logo sprite scale
        //logoSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        fromSprite.SetSize(textureWidth/4, textureHeight/4);

        fromSprite.position = fromLocation;

        // Set logo sprite hot spot
        fromSprite.SetHotSpot(fromSprite.size.x/4, fromSprite.size.y);

        // Set logo sprite alignment
        fromSprite.SetAlignment(HA_LEFT, VA_TOP);
        //fromSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        fromSprite.opacity = MAX_OPACITY;

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
        toSprite.SetSize(textureWidth/4, textureHeight/4);

        toSprite.position = toLocation;

        // Set logo sprite hot spot
        toSprite.SetHotSpot(toSprite.size.x/4, toSprite.size.y);

        // Set logo sprite alignment
        toSprite.SetAlignment(HA_LEFT, VA_TOP);
        //toSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        toSprite.opacity = MAX_OPACITY;

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
            direction += diff / 400;
            if (direction.length > 0) {
                direction.Normalize();
            }
            position += direction * DOT_MARGIN;

            if (position.length > toLocation.length - 10) {
                if (toLocation == fromLocation) {
                    if (Vector2(toLocation - position).length < 10) {
                        reached = true;
                    }
                }
                reached = true;
                toLocation = fromLocation;
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
        if (loadingText !is null) {
            loadingText.Remove();
        }
        if (boardSprite !is null) {
            boardSprite.Remove();
        }
        if (storySprite !is null) {
            storySprite.Remove();
        }

        if (instructionsScreen !is null) {
            instructionsScreen.Remove();
        }
        for (uint i = 0; i < buttons.length; i++) {
            buttons[i].Remove();
        }
        buttons.Clear();

        Options::Destroy();
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        if (zoomIn) {
            scale += timeStep / 50.0f;
            if (scale > 1.5f) {
                zoomIn = false;
            }
        } else {
            scale -= timeStep / 50.0f;
            if (scale < 0.9f) {
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
                if (path[i].opacity > MAX_OPACITY) {
                    path[i].opacity = MAX_OPACITY;
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
