namespace ConsoleHandler {
    void CreateConsole()
    {
        if (engine.headless) {
            return;
        }
        script.executeConsoleCommands = false;
        fileSystem.executeConsoleCommands = false;

        // Get default style
        XMLFile@ xmlFile = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
        if (xmlFile is null)
            return;

        // Create console
        Console@ console = engine.CreateConsole();
        console.defaultStyle = xmlFile;
        console.background.opacity = 0.8f;
        console.visible = false;
        console.numRows = graphics.height / 20;
        console.numBufferedRows = 2 * console.numRows;
        console.closeButton.visible = false;
        console.AddAutoComplete("start");
        console.AddAutoComplete("connect");
        console.AddAutoComplete("disconnect");
        console.autoVisibleOnError = true;
        console.UpdateElements();
        //DelayedExecute(1.0, false, "void ConsoleHandler::ShowError()");
    }

    void HandleKeys(int key)
    {
        if (key == KEY_F1) {
            console.Toggle();
        }
    }

    void ShowError()
    {
        log.Error("Error!!!");
    }

    void Subscribe()
    {
        log.Info("Subscribing console commands...");
        SubscribeToEvent("ConsoleCommand", "ConsoleHandler::HandleConsoleCommand");
    }

    void HandleConsoleCommand(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Id"].GetString() == "ScriptEventInvoker") {
            String inputValue = eventData["Command"].GetString();
            log.Info("Console input: " + inputValue);
            ConsoleHandler::ParseCommand(inputValue);
        }
    }

    void ParseCommand(String command)
    {
        log.Info("Command parser: " + command);
        if (command == "start") {
            NetworkHandler::StartServer();
        } else if (command == "connect") {
            NetworkHandler::Connect();
        } else if (command == "disconnect") {
            NetworkHandler::StopServer();
        } else if (command == "logo") {
            SendEvent("ToggleLogo");
        }
    }
}