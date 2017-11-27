namespace ConsoleHandler {

    Console@ console;
    class ConsoleCommand {
        String command;
        String eventToCall;
    };
    Array<ConsoleCommand> consoleCommands;

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
        console = engine.CreateConsole();
        console.defaultStyle = xmlFile;
        console.background.opacity = 0.8f;
        console.visible = false;
        console.numRows = graphics.height / 30;
        console.numBufferedRows = 10 * console.numRows;
        console.closeButton.visible = false;
        console.AddAutoComplete("start");
        console.AddAutoComplete("connect");
        console.AddAutoComplete("disconnect");
        console.autoVisibleOnError = false;
        console.UpdateElements();
        console.commandInterpreter = "ScriptEventInvoker";
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
        SubscribeToEvent("ConsoleCommandAdd", "ConsoleHandler::HandleConsoleCommandAdd");
        SubscribeToEvent("ConsoleHelp", "ConsoleHandler::HandleConsoleHelp");
        SubscribeToEvent("ChangeFOV", "ConsoleHandler::HandleFOV");

        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "help";
        data["CONSOLE_COMMAND_EVENT"] = "ConsoleHelp";
        SendEvent("ConsoleCommandAdd", data);

        data["CONSOLE_COMMAND_NAME"] = "fov";
        data["CONSOLE_COMMAND_EVENT"] = "ChangeFOV";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandleConsoleHelp(StringHash eventType, VariantMap& eventData)
    {
        log.Info("");
        log.Info("###### COMMAND LIST ######");
        log.Info("# COMMAND => EVENT_NAME");
        log.Info("#");
        for (uint i = 0; i < consoleCommands.length; i++) {
            log.Info("# '" + consoleCommands[i].command + "' => '" + consoleCommands[i].eventToCall + "'");
        }
        log.Info("#########################");
        log.Info("");
    }

    void HandleConsoleCommandAdd(StringHash eventType, VariantMap& eventData)
    {
        String command = eventData["CONSOLE_COMMAND_NAME"].GetString();
        String eventToCall = eventData["CONSOLE_COMMAND_EVENT"].GetString();
        for (uint i = 0; i < consoleCommands.length; i++) {
            if (consoleCommands[i].command == command) {
                log.Error("Console command '" + command + "' already registered!");
                log.Error(command + " calls event '" + eventToCall + "'");
                return;
            }
        }
        ConsoleCommand consoleCommand;
        consoleCommand.command = command;
        consoleCommand.eventToCall = eventToCall;
        consoleCommands.Push(consoleCommand);
        console.AddAutoComplete(command);
    }

    void HandleConsoleCommand(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Id"].GetString() == "ScriptEventInvoker") {
            String inputValue = eventData["Command"].GetString();
            ConsoleHandler::ParseCommand(inputValue);
        }
    }

    void HandleFOV(StringHash eventType, VariantMap& eventData)
    {
        Array<String> commands = eventData["PARAMETERS"].GetStringVector();
        if (commands.length < 2) {
            log.Error("'fov' command expects second argument!");
            return;
        }
        
        float fov = commands[1].ToFloat();
        camera.fov = fov;
    }

    void ParseCommand(String line)
    {
        Array<String> commands = line.Split(' ', true);
        String command = commands[0];
        for (uint i = 0; i < consoleCommands.length; i++) {
            if (consoleCommands[i].command == command) {
                VariantMap map;
                map["PARAMETERS"] = commands;
                SendEvent(consoleCommands[i].eventToCall, map);
            }
        }
    }
}