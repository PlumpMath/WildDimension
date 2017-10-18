#include "Urho3D/Urho3DAll.h"
#include "Console/Handlers/DriveableActions.h"
#include "Events.h"

DriveableActions::DriveableActions(Context* context):
ConsoleCommandHandler(context)
{
	registerCommand("add_sled");
    registerCommand("add_vehicle");
    registerCommand("clear_driveables");
    registerCommand("sled_speed");
    registerCommand("vehicle_speed");
}


DriveableActions::~DriveableActions()
{
}


void DriveableActions::runCommand()
{
	if (*_params.begin() == "add_sled") {
		if (_params.size() > 2) {
			URHO3D_LOGERROR("Too much parameters!");
			showHelp();
			return;
		}

        VariantMap map;
        map[P_READY] = true;
        if (_params.size() == 1) {
            SendEvent(E_ADD_SLED, map);
        }
        else {
            int val = std::atoi(_params.at(1).CString());
            map[P_COUNT] = val;
            SendEvent(E_ADD_SLED, map);
        }
    }
    else if (*_params.begin() == "add_vehicle") {
        if (_params.size() > 2) {
            URHO3D_LOGERROR("Too much parameters!");
            showHelp();
            return;
        }

        VariantMap map;
        map[P_READY] = true;

        if (_params.size() == 1) {
            SendEvent(E_ADD_VEHICLE, map);
        }
        else {
            int val = std::atoi(_params.at(1).CString());
            map[P_COUNT] = val;
            SendEvent(E_ADD_VEHICLE, map);
        }
    }
    else if (*_params.begin() == "clear_driveables") {
        if (_params.size() > 1) {
            URHO3D_LOGERROR("Too much parameters!");
            showHelp();
            return;
        }
        //SendEvent(E_EXIT_DRIVEABLES);
        SendEvent(E_REMOVE_DRIVEABLES);
        GetSubsystem<Network>()->BroadcastRemoteEvent(E_REMOVE_DRIVEABLES, true);
        URHO3D_LOGRAW("All vehicles and sleds cleared from the map");
    }
    else if (*_params.begin() == "sled_speed") {
        if (_params.size() == 1) {
            URHO3D_LOGERROR("You must specify a value!");
            showHelp();
            return;
        } else if (_params.size() > 2) {
            URHO3D_LOGERROR("Too much parameters!");
            showHelp();
            return;
        }

        VariantMap map;
        int val = std::atoi(_params.at(1).CString());
        map[P_VALUE] = val;
        SendEvent(E_SLED_SPEED, map);
    }
    else if (*_params.begin() == "vehicle_speed") {
        if (_params.size() == 1) {
            URHO3D_LOGERROR("You must specify a value!");
            showHelp();
            return;
        }
        else if (_params.size() > 2) {
            URHO3D_LOGERROR("Too much parameters!");
            showHelp();
            return;
        }

        VariantMap map;
        int val = std::atoi(_params.at(1).CString());
        map[P_VALUE] = val;
        SendEvent(E_VEHICLE_SPEED, map);
    }
}

void DriveableActions::showHelp()
{
	URHO3D_LOGRAW("To add a vehicle to game input 'add_vehicle' command. If you wan't to add multiple vehicles, add a number after the command. Example 'add_vehicle 10'. Same thing with the add_sled command.");
    URHO3D_LOGRAW("Input 'clear_driveables' to remove all sleds and vehicles from the game. If players are inside the vehicles, they will exit from them first");
    URHO3D_LOGRAW("'sled_speed N' and 'vehicle_speed N' will change the maximum speed of the driveables where 'N' is the numeric value");
}
