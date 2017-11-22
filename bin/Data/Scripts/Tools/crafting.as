namespace Craft {
	class Recipe {
		String name;
		Array<Inventory::Item> items;
	};

	Array<Recipe> recipes;

	void CraftItem(String name)
	{
		for (uint i = 0; i < recipes.length; i++) {
			if (recipes[i].name == name) {
				bool haveAllNeededItems = true;
				for (uint j = 0; j < recipes[i].items.length; j++) {
					Inventory::Item item = recipes[i].items[j];
					if (item.count > Inventory::GetItemCount(item.name)) {
						haveAllNeededItems = false;
						log.Warning("You don't have all the neccessary items to craft this!");
						return;
					}
				}

				if (haveAllNeededItems) {
					for (uint j = 0; j < recipes[i].items.length; j++) {
						Inventory::Item item = recipes[i].items[j];
						Inventory::RemoveItem(item.name, item.count);
					}
					VariantMap data;
	                data["Name"] = recipes[i].name;
	                SendEvent("InventoryAdd", data);

	                data["Name"] = "Get" + recipes[i].name;
	                SendEvent("UnlockAchievement", data);
				}
				return;
			}
		}
	}

	void Init()
	{
		Subscribe();
		RegisterConsoleCommands();

        {
    		Recipe recipe;
    		recipe.name = "Flag";
    		Inventory::Item item;
    		item.name = "Wood";
    		item.count = 1;
    		recipe.items.Push(item);
            item.name = "Skin";
            item.count = 1;
            recipe.items.Push(item);
    		recipes.Push(recipe);
        }

        {
            Recipe recipe;
            recipe.name = "Trap";
            Inventory::Item item;
            item.name = "Wood";
            item.count = 10;
            recipe.items.Push(item);
            recipes.Push(recipe);
        }

        {
            Recipe recipe;
            recipe.name = "Axe";
            Inventory::Item item;
            item.name = "Wood";
            item.count = 1;
            recipe.items.Push(item);
            item.name = "Rock";
            item.count = 1;
            recipe.items.Push(item);
            recipes.Push(recipe);
        }
	}

	void Subscribe()
    {
       SubscribeToEvent("Craft", "Craft::HandleCraft");
    }

    void RegisterConsoleCommands()
    {
        
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "craft";
        data["CONSOLE_COMMAND_EVENT"] = "Craft";
        SendEvent("ConsoleCommandAdd", data);
        
    }

    void HandleCraft(StringHash eventType, VariantMap& eventData)
    {
    	Array<String> commands = eventData["PARAMETERS"].GetStringVector();
        if (commands.length < 2) {
            log.Error("'craft' command expects second argument!");
            return;
        }

        CraftItem(commands[1]);
    }
}