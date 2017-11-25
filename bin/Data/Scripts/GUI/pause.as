namespace PauseMenuGUI {
	const float MAX_OPACITY = 0.99;
	const String GUI_FONT = "Fonts/PainttheSky-Regular.otf";
    const int GUI_FONT_SIZE = Helpers::getHeightByPercentage(0.04);

    UIElement@ baseElement;
	Button@ resumeButton;
    Button@ menuButton;
    Button@ exitButton;

	void Init()
	{
        baseElement = ui.root.CreateChild("UIElement");
        baseElement.SetAlignment(HA_CENTER, VA_CENTER);

		CreateResumeButton();
        //CreateMenuButton();
        CreatExitButton(); 
		Subscribe();

        baseElement.visible = false;
        log.Warning("Hiding pause menu");
	}

	void CreateResumeButton()
    {
        Font@ font = cache.GetResource("Font", GUIHandler::GUI_FONT);

        XMLFile@ uiStyle = cache.GetResource("XMLFile", "UI/Menu.xml");

        // Create the button and center the text onto it
        resumeButton = baseElement.CreateChild("Button");
        resumeButton.SetStyleAuto(uiStyle);
        resumeButton.SetPosition(0, -60);
        resumeButton.SetSize(100, 40);
        resumeButton.SetAlignment(HA_CENTER, VA_CENTER);

        Text@ resumeButtonText = resumeButton.CreateChild("Text");
        resumeButtonText.SetAlignment(HA_CENTER, VA_TOP);
        resumeButtonText.SetFont(font, 30);
        resumeButtonText.textAlignment = HA_CENTER;
        resumeButtonText.text = "Resume";
        resumeButtonText.position = IntVector2(0, -10);
        SubscribeToEvent(resumeButton, "Released", "PauseMenuGUI::HandleResumeButton");
    }

    void CreateMenuButton()
    {
        Font@ font = cache.GetResource("Font", GUIHandler::GUI_FONT);

        XMLFile@ uiStyle = cache.GetResource("XMLFile", "UI/Menu.xml");

        // Create the button and center the text onto it
        menuButton = baseElement.CreateChild("Button");
        menuButton.SetStyleAuto(uiStyle);
        menuButton.SetPosition(0, 0);
        menuButton.SetSize(100, 40);
        menuButton.SetAlignment(HA_CENTER, VA_CENTER);

        Text@ menuButtonText = menuButton.CreateChild("Text");
        menuButtonText.SetAlignment(HA_CENTER, VA_TOP);
        menuButtonText.SetFont(font, 30);
        menuButtonText.textAlignment = HA_CENTER;
        menuButtonText.text = "Menu";
        menuButtonText.position = IntVector2(0, -10);
        SubscribeToEvent(menuButton, "Released", "PauseMenuGUI::HandleMenuButton");
    }

    void CreatExitButton()
    {
        Font@ font = cache.GetResource("Font", GUIHandler::GUI_FONT);

        XMLFile@ uiStyle = cache.GetResource("XMLFile", "UI/Menu.xml");

        // Create the button and center the text onto it
        exitButton = baseElement.CreateChild("Button");
        exitButton.SetStyleAuto(uiStyle);
        exitButton.SetPosition(0, 0);
        exitButton.SetSize(100, 40);
        exitButton.SetAlignment(HA_CENTER, VA_CENTER);

        Text@ exitButtonText = exitButton.CreateChild("Text");
        exitButtonText.SetAlignment(HA_CENTER, VA_TOP);
        exitButtonText.SetFont(font, 30);
        exitButtonText.textAlignment = HA_CENTER;
        exitButtonText.text = "Exit";
        exitButtonText.position = IntVector2(0, -10);
        SubscribeToEvent(exitButton, "Released", "PauseMenuGUI::HandleExitButton");
    }

    void Destroy()
    {
    	if (baseElement !is null) {
    		baseElement.Remove();
    	}
    }

    void Subscribe()
    {
        SubscribeToEvent("TogglePause", "PauseMenuGUI::HandleTogglePause");
    }

    void HandleTogglePause(StringHash eventType, VariantMap& eventData)
    {
        if (baseElement.visible) {
            baseElement.visible = false;
            input.mouseVisible = false;
        } else {
            baseElement.visible = true;
            input.mouseVisible = true;
        }
    }

    void HandleResumeButton(StringHash eventType, VariantMap& eventData)
    {
        SendEvent("ResumeGame");
        baseElement.visible = false;
        input.mouseVisible = false;
    }

    void HandleMenuButton(StringHash eventType, VariantMap& eventData)
    {
        log.Warning("Handle menu button");
    }

    void HandleExitButton(StringHash eventType, VariantMap& eventData)
    {
        engine.Exit();
    }
}