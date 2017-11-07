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
            if (node.name == "Axe") {
                SendEvent("GetAxe");
            } else if(node.name == "Trap") {
                SendEvent("GetTrap");
            } else if (node.name == "Branch") {
                SendEvent("InventoryAddBranch");

                VariantMap data;
                data["Name"] = "GetAxe";
                SendEvent("UnlockAchievement", data);

                data["Message"] = "Branch retrieved";
                SendEvent("UpdateEventLogGUI", data);
            }
            node.Remove();
        }
    }
}

class Usable : ScriptObject
{
    void Start()
    {
        log.Info("Usable registered");
        // Subscribe physics collisions that concern this scene node
        SubscribeToEvent(node, "NodeCollision", "HandleNodeCollision");
    }

    void HandleNodeCollision(StringHash eventType, VariantMap& eventData)
    {
        Node@ otherNode = eventData["OtherNode"].GetPtr();
        log.Info("You hit a " + node.name);
        //if (otherNode.HasTag("Player")) {
            //log.Info("Player " + otherNode.id + " picked up " + node.name);
            //if (node.name == "Tree") {
                //log.Info("You hit a " + node.name);
            //}
        //}
    }
}