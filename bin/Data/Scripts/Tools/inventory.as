namespace Inventory {
	class Item {
		String name;
		int count;
	};

	Array<Item> items;

	void Subscribe()
    {
        SubscribeToEvent("InventoryAddAxe", "Inventory::HandleInventoryAddAxe");
        SubscribeToEvent("InventoryAddTrap", "Inventory::HandleInventoryAddTrap");
        SubscribeToEvent("InventoryAddBranch", "Inventory::HandleInventoryAddBranch");
    }

    void RegisterConsoleCommands()
    {
        /*VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "get_axe";
        data["CONSOLE_COMMAND_EVENT"] = "GetAxe";
        SendEvent("ConsoleCommandAdd", data);*/
    }

    void AddItem(String name)
    {
    	bool alreadyExists = false;
    	for (uint i = 0; i < items.length; i++) {
    		Item@ item = items[i];
    		if (item.name == name) {
    			item.count++;
    			alreadyExists = true;
    		}
    	}
    	if (alreadyExists == false) {
    		Item item;
    		item.name = name;
    		item.count = 1;
    		items.Push(item);
    	}
    	log.Info("Adding item[" + name + "] to inventory");
    	SendEvent("UpdateInventoryGUI");
    }

    void HandleInventoryAddAxe(StringHash eventType, VariantMap& eventData)
    {
        AddItem("Axe");
    }

    void HandleInventoryAddBranch(StringHash eventType, VariantMap& eventData)
    {
        AddItem("Branch");
    }

    void HandleInventoryAddTrap(StringHash eventType, VariantMap& eventData)
    {
        AddItem("Trap");
    }
}