#include "Urho3D/Urho3DAll.h"
#include "Console/Handlers/AIActions.h"
#include "Events.h"

AIActions::AIActions(Context* context):
ConsoleCommandHandler(context)
{
	registerCommand("ai_restart");
    registerCommand("ai_arrive_radius");
    registerCommand("ai_tree_collisions");
    registerCommand("ai_steer_angle");
    registerCommand("ai_drift_angle_min");
    registerCommand("ai_drift_angle_max");
    registerCommand("ai_drift_speed_min");
    registerCommand("ai_reset_time");
}


AIActions::~AIActions()
{
}


void AIActions::runCommand()
{
	if (*_params.begin() == "ai_restart") {
		if (_params.size() > 1) {
			URHO3D_LOGERROR("Too much parameters!");
			showHelp();
			return;
		}

        SendEvent(E_AI_START_FROM_FIRST_CHECKPOINT);
        URHO3D_LOGRAW("All AI driven objects will start off from the first checkpoint");
    }
    else if (*_params.begin() == "ai_arrive_radius") {
        if (_params.size() == 1) {
            URHO3D_LOGERROR("You must specify a value!");
            showHelp();
            return;
        } else if (_params.size() > 2) {
            URHO3D_LOGERROR("Too much parameters!");
            showHelp();
            return;
        }
        int val = std::atoi(_params.at(1).CString());
        val = Abs(val);
        VariantMap map;
        map[P_VALUE] = val;
        SendEvent(E_AI_ARRIVE_RADIUS, map);
        URHO3D_LOGRAWF("AI arrive radius changed to %d", val);
    } 
    else if (*_params.begin() == "ai_tree_collisions") {
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

        int val = std::atoi(_params.at(1).CString());

        VariantMap map;
        map[P_VALUE] = (val > 0) ? true : false;
        SendEvent(E_AI_TOGGLE_TREE_COLLISION, map);

        URHO3D_LOGRAWF("Setting tree colisions to %d", val);
    }
    else if (*_params.begin() == "ai_steer_angle") {
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
        int val = std::atoi(_params.at(1).CString());
        val = Abs(val);
        VariantMap map;
        map[P_VALUE] = val;
        SendEvent(E_AI_STEER_ANGLE, map);
        URHO3D_LOGRAWF("AI steer angle changed to %d", val);
    }
    else if (*_params.begin() == "ai_drift_angle_min") {
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
        int val = std::atoi(_params.at(1).CString());
        val = Abs(val);
        VariantMap map;
        map[P_VALUE] = val;
        SendEvent(E_AI_DRIFT_MIN_ANGLE, map);
        URHO3D_LOGRAWF("AI drift min angle changed to %d", val);
    }
    else if (*_params.begin() == "ai_drift_angle_max") {
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
        int val = std::atoi(_params.at(1).CString());
        val = Abs(val);
        VariantMap map;
        map[P_VALUE] = val;
        SendEvent(E_AI_DRIFT_MAX_ANGLE, map);
        URHO3D_LOGRAWF("AI drift max angle changed to %d", val);
    }
    else if (*_params.begin() == "ai_drift_speed_min") {
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
        int val = std::atoi(_params.at(1).CString());
        val = Abs(val);
        VariantMap map;
        map[P_VALUE] = val;
        SendEvent(E_AI_DRIFT_MIN_SPEED, map);
        URHO3D_LOGRAWF("AI drift min speed changed to %d", val);
    }
    else if (*_params.begin() == "ai_reset_time") {
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
        int val = std::atoi(_params.at(1).CString());
        val = Abs(val);
        VariantMap map;
        map[P_VALUE] = val;
        SendEvent(E_AI_RESET_TIME, map);
        URHO3D_LOGRAWF("AI reset time changed to %ds", val);
    }
}

void AIActions::showHelp()
{
    URHO3D_LOGRAW("AI command affects all the objects that utilizes AI functionality!");
    URHO3D_LOGRAW("ai_reset will make the AI driven objects start the track from the start, ignoring current progress.");
    URHO3D_LOGRAW("ai_arrive_radius defines the radius in which the AI driven object decides that the specific path node is reached. By default it's set to 4.");
    URHO3D_LOGRAW("ai_tree_collisions will enable/disable tree colissions");
}
