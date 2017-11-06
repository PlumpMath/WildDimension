namespace ActiveTool {
    Node@ node;
    Node@ toolNode;
    bool enabled = false;
    Array<Node@> tools;
    uint activeToolIndex = 0;

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

        node.SetDeepEnabled(enabled);
    }

    void Subscribe()
    {
        SubscribeToEvent("NextTool", "ActiveTool::HandleNextTool");
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
