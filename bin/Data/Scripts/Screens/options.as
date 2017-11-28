namespace Options {
    const float MAX_OPACITY = 0.99f;
    Sprite@ optionsSprite;
    Array<Button@> buttons;
    Array<UIElement@> dropdowns;
    Array<UIElement@> checkboxes;

    class SettingsValues {
        int width;
        int height;
        bool fullscreen;
        bool vsync;
        bool tripleBuffer;
        bool drawShadows;
        bool hdrRendering;
        bool reuseShadowMaps;
    };

    SettingsValues settingsValues;

    void Create()
    {
        settingsValues.width = graphics.width;
        settingsValues.height = graphics.height;
        settingsValues.fullscreen = graphics.fullscreen;
        settingsValues.vsync = graphics.vsync;
        settingsValues.tripleBuffer  = graphics.tripleBuffer;
        settingsValues.drawShadows = renderer.drawShadows;
        settingsValues.hdrRendering = renderer.hdrRendering;
        settingsValues.reuseShadowMaps = renderer.reuseShadowMaps;

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

        Array<String> items;
        items.Push("1280 x 720");
        items.Push("1920 x 1080");
        items.Push("1024 x 768");
        items.Push("1600 x 1200");
        CreateResolutionMenu("Resolution", items, "Options::HandleResolutionItemSelected", IntVector2(20, 20));

        CreateButton("Close", "Options::HandleCloseSettings", IntVector2(-20, -20));
        CreateButton("Apply", "Options::HandleApplySettings", IntVector2(-140, -20));

        CreateCheckbox("Fullscreen", "Options::HandleToggleFullscreen", IntVector2(20, 60), settingsValues.fullscreen);
        CreateCheckbox("VSync", "Options::HandleToggleVSync", IntVector2(20, 100), settingsValues.vsync);
        CreateCheckbox("Tripple buffer", "Options::HandleTrippleBuffer", IntVector2(20, 140), settingsValues.tripleBuffer);
        CreateCheckbox("Draw shadows", "Options::HandleDrawShadows", IntVector2(20, 180), settingsValues.drawShadows);
        CreateCheckbox("HDR rendering", "Options::HandleHDRRendering", IntVector2(20, 220), settingsValues.hdrRendering);
        CreateCheckbox("Reuse shadow maps", "Options::HandleToggleReuseShadowMaps", IntVector2(20, 260), settingsValues.reuseShadowMaps);
    }

    void CreateResolutionMenu(String label, Array<String> items, String handler, IntVector2 position)
    {
        XMLFile@ uiStyle = cache.GetResource("XMLFile", "UI/Menu.xml");

        UIElement@ container = UIElement();
        container.SetAlignment(HA_LEFT, VA_TOP);
        container.SetLayout(LM_HORIZONTAL, 100);
        container.SetPosition(position.x, position.y);
        optionsSprite.AddChild(container);

        Font@ font = cache.GetResource("Font", GUIHandler::GUI_FONT);

        Text@ text = Text();
        container.AddChild(text);
        text.text = label;
        text.SetStyleAuto();
        text.color = Color(0, 0, 0);
        text.SetFont(font, 20);
        text.SetFixedWidth(Helpers::getWidthByPercentage(0.1));

        DropDownList@ list = DropDownList();
        container.AddChild(list);
        list.SetStyleAuto();
        
        for (int i = 0; i < items.length; ++i)
        {
            Text@ t = Text();
            t.text = items[i];
            t.color = Color(0.9, 0.9, 0.9);
            //t.SetStyleAuto();
            t.SetFont(font, 20);
            t.minWidth = t.rowWidths[0] + 10;
            list.AddItem(t);
        }
        
        text.maxWidth = text.rowWidths[0];
        list.SetFixedSize(Helpers::getWidthByPercentage(0.2), 40);

        dropdowns.Push(container);
        
        SubscribeToEvent(list, "ItemSelected", handler);
    }

    void CreateCheckbox(String label, String handler, IntVector2 position, bool checked)
    {
        Font@ font = cache.GetResource("Font", GUIHandler::GUI_FONT);

        UIElement@ container = UIElement();
        container.SetAlignment(HA_LEFT, VA_TOP);
        container.SetLayout(LM_HORIZONTAL, 100);
        container.SetPosition(position.x, position.y);
        optionsSprite.AddChild(container);

        Text@ text = Text();
        text.text = label;
        //text.SetStyleAuto();
        text.color = Color(0, 0, 0);
        text.SetFont(font, 20);
        text.SetFixedWidth(Helpers::getWidthByPercentage(0.1));
        container.AddChild(text);

        CheckBox@ checkbox = CheckBox();
        checkbox.SetStyleAuto();
        checkbox.SetAlignment(HA_LEFT, VA_BOTTOM);
        checkbox.checked = checked;
        checkbox.SetPosition(100, 0);

        container.AddChild(checkbox);

        SubscribeToEvent(checkbox, "Toggled", handler);

        checkboxes.Push(container);
    }

    void Destroy()
    {
        if (optionsSprite !is null) {
            optionsSprite.Remove();
        }
        for (uint i = 0; i < buttons.length; i++) {
            buttons[i].Remove();
        }
        buttons.Clear();
        for (uint i = 0; i < dropdowns.length; i++) {
            dropdowns[i].Remove();
        }
        dropdowns.Clear();
        for (uint i = 0; i < checkboxes.length; i++) {
            checkboxes[i].Remove();
        }
        checkboxes.Clear();
    }

    void HandleResolutionItemSelected(StringHash eventType, VariantMap& eventData)
    {
        DropDownList@ list = eventData["Element"].GetPtr();
        int i = list.selection;
        Text@ text =  cast<Text>(list.selectedItem);
        settingsValues.width = text.text.Split('x')[0].ToInt();
        settingsValues.height = text.text.Split('x')[1].ToInt();
    }

    void HandleToggleFullscreen(StringHash eventType, VariantMap& eventData)
    {
        CheckBox@ checkbox = eventData["Element"].GetPtr();
        settingsValues.fullscreen = checkbox.checked;
    }

    void HandleToggleVSync(StringHash eventType, VariantMap& eventData)
    {
        CheckBox@ checkbox = eventData["Element"].GetPtr();
        settingsValues.vsync = checkbox.checked;
    }

    void HandleTrippleBuffer(StringHash eventType, VariantMap& eventData)
    {
        CheckBox@ checkbox = eventData["Element"].GetPtr();
        settingsValues.tripleBuffer = checkbox.checked;
    }

    void HandleDrawShadows(StringHash eventType, VariantMap& eventData)
    {
        CheckBox@ checkbox = eventData["Element"].GetPtr();
        settingsValues.drawShadows = checkbox.checked;
    }

    void HandleHDRRendering(StringHash eventType, VariantMap& eventData)
    {
        CheckBox@ checkbox = eventData["Element"].GetPtr();
        settingsValues.hdrRendering = checkbox.checked;
    }

    void HandleToggleReuseShadowMaps(StringHash eventType, VariantMap& eventData)
    {
        CheckBox@ checkbox = eventData["Element"].GetPtr();
        settingsValues.reuseShadowMaps = checkbox.checked;
    }

    void HandleApplySettings(StringHash eventType, VariantMap& eventData)
    {
        //SetMode(width_, height_, !fullscreen_, borderless_, resizable_, highDPI_, vsync_, tripleBuffer_, multiSample_, monitor_, refreshRate_);
        graphics.SetMode(settingsValues.width, settingsValues.height, settingsValues.fullscreen, graphics.borderless , graphics.resizable , false, settingsValues.vsync, settingsValues.tripleBuffer , graphics.multiSample, 0, 60);
        renderer.drawShadows = settingsValues.drawShadows;
        renderer.hdrRendering = settingsValues.hdrRendering;
        renderer.reuseShadowMaps = settingsValues.reuseShadowMaps;
        Hide();
    }

    void HandleCloseSettings(StringHash eventType, VariantMap& eventData)
    {
        Hide();
    }

    void CreateButton(String name, String handler, IntVector2 position, bool right = true)
    {
        Font@ font = cache.GetResource("Font", GUIHandler::GUI_FONT);

        XMLFile@ uiStyle = cache.GetResource("XMLFile", "UI/Menu.xml");

        Button@ button = optionsSprite.CreateChild("Button");
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

    void Show()
    {
        optionsSprite.visible = true;
    }

    void Hide()
    {
        optionsSprite.visible = false;
    }
}