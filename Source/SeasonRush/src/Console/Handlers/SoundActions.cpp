#include "Urho3D/Urho3DAll.h"
#include "Console/Handlers/SoundActions.h"
#include "Events.h"

SoundActions::SoundActions(Context* context):
ConsoleCommandHandler(context)
{
	registerCommand("audio_volume");
}


SoundActions::~SoundActions()
{
}


void SoundActions::runCommand()
{
	if (*_params.begin() == "audio_volume") {
		if (_params.size() > 2) {
			URHO3D_LOGERROR("Too much parameters!");
			showHelp();
			return;
		}

		int val = std::atoi(_params.at(1).CString());
		if (val >= 0 && val <= 100) {
			GetSubsystem<Audio>()->SetMasterGain(SOUND_MASTER, (float) val / 100.0);
		}
		else {
			URHO3D_LOGERROR("Invalid value provided! Values should be in range 0-100");
		}
	}
}

void SoundActions::showHelp()
{
	URHO3D_LOGRAW("Input 'sound_volume [0-100]' to set the volume in the game");
}
