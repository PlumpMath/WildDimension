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
        console.numBufferedRows = 10 * console.numRows;
        console.closeButton.visible = false;
        console.AddAutoComplete("start");
        console.AddAutoComplete("connect");
        console.AddAutoComplete("disconnect");
        console.autoVisibleOnError = false;
        console.UpdateElements();
        DelayedExecute(1.0, false, "void ConsoleHandler::ShowInfo()");
        log.timeStamp = false;
        log.level = 1;
    }

    void Destroy()
    {
        
    }

    void HandleKeys(int key)
    {
        if (key == KEY_F1) {
            console.Toggle();
        }
    }

    void ShowInfo()
    {
        log.Info("######################################");
        log.Info("# Hostname      : " + GetHostName());
        log.Info("# Login         : " + GetLoginName());
        log.Info("# OS Version    : " + GetOSVersion());
        log.Info("# Platform      : " + GetPlatform());
        log.Info("# Memory        : " + GetTotalMemory()/1024/1024 + "MB");
        log.Info("# Logical CPU   : " + GetNumLogicalCPUs());
        log.Info("# Physical CPU  : " + GetNumPhysicalCPUs());
        log.Info("######################################");
    }

    void Subscribe()
    {
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
        } else if (command == "reload") {
            SendEvent("ReloadAll");
        } else if (command == "clientlist") {
            SendEvent("ClientsList");
        } else if (command == "get axe") {
            SendEvent("PickupAxe");
        }
    }
}