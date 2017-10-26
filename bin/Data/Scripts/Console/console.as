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
        DelayedExecute(1.0, false, "void ConsoleHandler::ShowInfo()");
        log.timeStamp = false;
        log.level = 0;
    }

    void HandleKeys(int key)
    {
        if (key == KEY_F1) {
            console.Toggle();
        }
    }

    void ShowInfo()
    {
        log.Error("Ups");
        log.Warning("Warnings s");
        log.Debug("Ha");
        log.Info("######################################");
        log.Info("# Hostname   : " + GetHostName());
        log.Info("# Login      : " + GetLoginName());
        log.Info("# OS Version : " + GetOSVersion());
        log.Info("# Platform   : " + GetPlatform());
        log.Info("# Memory     : " + GetTotalMemory()/1024/1024 + "MB");
        log.Info("######################################");
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
            ConsoleHandler::ParseCommand(inputValue);
        }
    }

    void ParseCommand(String command)
    {
        if (command == "start") {
            NetworkHandler::StartServer();
        } else if (command == "connect") {
            NetworkHandler::Connect();
        } else if (command == "disconnect") {
            NetworkHandler::StopServer();
        } else if (command == "logo") {
            SendEvent("ToggleLogo");
        } else if (command == "exit") {
            engine.Exit();
        }
    }
}