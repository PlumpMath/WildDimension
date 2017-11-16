class PickableObject : ScriptObject
{
    void Start()
    {
        // Subscribe physics collisions that concern this scene node
        SubscribeToEvent(node, "NodeCollision", "HandleNodeCollision");
    }

    void HandleNodeCollision(StringHash eventType, VariantMap& eventData)
    {
        Node@ otherNode = eventData["OtherNode"].GetPtr();
        if (otherNode.HasTag("Player")) {
            log.Info("Player " + otherNode.id + " picked up " + node.name);
            VariantMap data;
            data["Name"] = node.name;
            SendEvent("InventoryAdd", data);

            data["Name"] = "Get" + node.name;
            SendEvent("UnlockAchievement", data);

            GameSounds::Play(GameSounds::PICKUP_TOOL);
            node.Remove();
        }
    }
}