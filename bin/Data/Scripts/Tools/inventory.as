namespace Inventory {
	class Item {
		String name;
		int count;
	};

    VariantMap registeredItemList;

	Array<Item> items;

    void Init()
    {
        Subscribe();
        RegisterConsoleCommands();

        registeredItemList["Axe"] = true;
        registeredItemList["Trap"] = true;
        registeredItemList["Wood"] = true;
        registeredItemList["Flag"] = true;
    }

	void Subscribe()
    {
        SubscribeToEvent("InventoryAdd", "Inventory::HandleInventoryAdd");
    }

    int GetItemCount(String name)
    {
        for (uint i = 0; i < items.length; i++) {
            Item@ item = items[i];
            if (item.name == name) {
                return item.count;
            }
        }

        return 0;
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
        if (!registeredItemList[name].GetBool()) {
            return;
        }
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

    void RemoveItem(String name)
    {
        for (uint i = 0; i < items.length; i++) {
            Item@ item = items[i];
            if (item.name == name) {
                item.count--;
                if (item.count <= 0) {
                    items.Erase(i);
                    return;
                }
            }
        }
    }

    void HandleInventoryAdd(StringHash eventType, VariantMap& eventData)
    {
        String name = eventData["Name"].GetString();
        AddItem(name);
        ActiveTool::SetActiveToolByName(name);
    }
}