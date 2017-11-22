namespace Notifications {

    const uint NOTIFICATION_TYPE_GOOD = 0;
    const uint NOTIFICATION_TYPE_BAD = 1;

    const String NOTIFICATION_GUI_FONT = "Fonts/PainttheSky-Regular.otf";
    const int NOTIFICATION_GUI_FONT_SIZE = 30;
    const float NOTIFICATION_SPEED = 50.0f;

    UIElement@ baseElement;
    class Notification {
        Text@ element;
        float lifetime;
    };
    Array<Notification> notifications;

    void Init()
    {
        baseElement = ui.root.CreateChild("UIElement");

        // Position the text relative to the screen center
        baseElement.horizontalAlignment = HA_CENTER;
        baseElement.verticalAlignment = VA_BOTTOM;
        baseElement.SetPosition(0, -20);
        Subscribe();
        RegisterConsoleCommands();
    }

    void CreateNotification(String message, uint type)
    {
        Notification notification;
        notification.element = baseElement.CreateChild("Text");
        notification.element.text = message;
        notification.element.SetFont(cache.GetResource("Font", NOTIFICATION_GUI_FONT), NOTIFICATION_GUI_FONT_SIZE);
        notification.element.textAlignment = HA_CENTER; // Center rows in relation to each other
        notification.element.horizontalAlignment = HA_CENTER;
        notification.element.verticalAlignment = VA_BOTTOM;
        notification.element.SetPosition(0, 0);
        notification.element.opacity = 0.0f;
        if (type == NOTIFICATION_TYPE_GOOD) {
            notification.element.color = Color(0.2, 0.8, 0.2);
        } else if (type == NOTIFICATION_TYPE_BAD) {
            notification.element.color = Color(8.2, 0.2, 0.2);
        }
        notifications.Push(notification);
    }

    void Subscribe()
    {
        SubscribeToEvent("AddNotification", "Notifications::HandleAddNotification");
    }

    void RegisterConsoleCommands()
    {
        /*VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "logo";
        data["CONSOLE_COMMAND_EVENT"] = "ToggleLogo";
        SendEvent("ConsoleCommandAdd", data);*/
    }

    void Destroy()
    {
        if (baseElement !is null) {
            baseElement.Remove();
        }
        for (uint i = 0; i < notifications.length; i++) {
            notifications[i].element.Remove();
        }
        notifications.Clear();
    }

    void HandleAddNotification(StringHash eventType, VariantMap& eventData)
    {
        if (eventData.Contains("Message") && eventData["Message"].type == VAR_STRING && eventData.Contains("Type") && eventData["Type"].type == VAR_INT) {
            String message = eventData["Message"].GetString();
            uint type = eventData["Type"].GetUInt();
            CreateNotification(message, type);
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        for (uint i = 0; i < notifications.length; i++) {
            notifications[i].lifetime += timeStep;
            if (notifications[i].lifetime > 2.0f) {
                float opacity = notifications[i].element.opacity;
                opacity -= timeStep;
                if (opacity < 0) {
                    opacity = 0.0f;
                    notifications[i].element.Remove();
                    notifications.Erase(i);
                    return;
                }
                notifications[i].element.opacity = opacity;
            } else if (notifications[i].lifetime < 2.0f) {
                float opacity = notifications[i].element.opacity;
                opacity += timeStep;
                if (opacity > 1) {
                    opacity = 1;
                }
                notifications[i].element.opacity = opacity;
            }
            IntVector2 position = notifications[i].element.position;
            position.y = -(notifications[i].lifetime * NOTIFICATION_SPEED);
            notifications[i].element.position = position;
        }
    }
}