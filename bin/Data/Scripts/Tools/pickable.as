class PickableObject : ScriptObject
{
    void Start()
    {
        // Subscribe physics collisions that concern this scene node
        SubscribeToEvent(node, "NodeCollision", "Pickable::HandleNodeCollision");
    }

    void HandleNodeCollision(StringHash eventType, VariantMap& eventData)
    {
        Node@ otherNode = eventData["OtherNode"].GetPtr();
        if (otherNode.HasTag("Player")) {
            log.Info("Player " + otherNode.id + " touched axe");
            if (node.name == "Axe") {
            	SendEvent("GetAxe");
            } else if(node.name == "Trap") {
            	SendEvent("GetTrap");
            }
            node.Remove();
        }
    }
}