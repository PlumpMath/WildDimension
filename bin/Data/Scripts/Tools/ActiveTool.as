namespace ActiveTool {
    Node@ node;
    Node@ toolNode;
    Array<Node@> tools;
    uint activeToolIndex = 0;
    bool use = false;
    bool back = false;
    float sleepTime = 0.0f;

    void Create()
    {
        node = cameraNode.CreateChild("ActiveTool");
        //position.y = NetworkHandler::terrain.GetHeight(position) + 1.0f;
        //node.position = position;

        toolNode = node.CreateChild("AdjNode");
        toolNode.rotation = Quaternion(-100.0f, Vector3::UP);

        Vector3 position = cameraNode.position;
        position += cameraNode.direction * 0.6f;
        position += node.rotation * Vector3::RIGHT * 0.3f;
        position += node.rotation * Vector3::UP * -0.1f;
        node.position = position;
    }

    void Subscribe()
    {
        SubscribeToEvent("NextTool", "ActiveTool::HandleNextTool");
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        sleepTime -= timeStep;
        if (input.mouseButtonDown[MOUSEB_LEFT] && use == false && sleepTime <= 0) {
            use = true;
            toolNode.Roll(-60.0f);
            back = true;
            sleepTime = 0.2f;
        }
        if (back == true && sleepTime <= 0) {
            toolNode.Roll(60.0f);
            back = false;
            use = false;
            sleepTime = 0.2f;   
        }
        if (input.keyPress[KEY_Q]) {
            SendEvent("NextTool");
        }
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "next_tool";
        data["CONSOLE_COMMAND_EVENT"] = "NextTool";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandleNextTool(StringHash eventType, VariantMap& eventData)
    {
        if (tools.length == 0) {
            return;
        }
        if (tools.length == 1) {
            tools[0].SetDeepEnabled(true);
        } else {
            activeToolIndex++;
            if (activeToolIndex >= tools.length) {
                activeToolIndex = 0;
            }
            for (uint i = 0; i < tools.length; i++) {
                Node@ node = tools[i];
                node.SetDeepEnabled(false);
            }
            tools[activeToolIndex].SetDeepEnabled(true);
        }
    }

    void SetActiveTool(Node@ newTool)
    {
        for (uint i = 0; i < tools.length; i++) {
            Node@ node = tools[i];
            if (newTool.id == node.id) {
                node.SetDeepEnabled(true);
                activeToolIndex = i;
            } else {
                node.SetDeepEnabled(false);
            }
        }
    }
}
