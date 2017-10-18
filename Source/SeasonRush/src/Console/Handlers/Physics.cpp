#include "Urho3D/Urho3DAll.h"
#include "Console/Handlers/Physics.h"
#include "Events.h"

Physics::Physics(Context* context):
ConsoleCommandHandler(context)
{
	registerCommand("ph_steps");
	registerCommand("ph_substeps");
	registerCommand("ph_draw");
	registerCommand("ph_gravity");
}


Physics::~Physics()
{
}


void Physics::runCommand()
{
	if (_params.size() > 2) {
		URHO3D_LOGERROR("Too much parameters!");
		showHelp();
		return;
	}
	else if (_params.size() < 2) {
		URHO3D_LOGERROR("Missing additional parameter!");
		showHelp();
		return;
	}

	VariantMap map;
		
	int count = std::atoi(_params.at(1).CString());
	map[P_VALUE] = count;

	if (_params.at(0) == "ph_steps") {
		SendEvent(E_PHYSICS_STEP_CHANGED, map);
	}
	else if (_params.at(0) == "ph_substeps"){
		SendEvent(E_PHYSICS_SUBSTEP_CHANGED, map);
	}
	else if (_params.at(0) == "ph_draw") {
		SendEvent(E_DRAW_PHYSICS, map);
	}
	else if (_params.at(0) == "ph_gravity") {
		map[P_VALUE] = Vector3(0, (float) count, 0);
		SendEvent(E_PHYSICS_GRAVITY, map);
	}

}

void Physics::showHelp()
{
    URHO3D_LOGRAW("Input 'physics_steps N' to define physics step count in 1s");
    URHO3D_LOGRAW("Input 'physics_substeps N' to define physics sub step count");
}
