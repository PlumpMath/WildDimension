#include "Urho3D/Urho3DAll.h"
#include "Console/Handlers/Requests.h"
#include "Events.h"

Requests::Requests(Context* context):
ConsoleCommandHandler(context)
{
	registerCommand("http");
}


Requests::~Requests()
{
}


void Requests::runCommand()
{
	if (*_params.begin() == "http") {
		if (_params.size() < 2) {
			URHO3D_LOGERROR("Missing second parameter!");
			showHelp();
			return;
		}
		else if (_params.size() > 2) {
			URHO3D_LOGERROR("Too much parameters!");
			showHelp();
			return;
		}
		auto respnonse = GetSubsystem<Network>()->MakeHttpRequest(_params.at(1));
		bool done = false;
		while (!done) {
			if (respnonse->GetAvailableSize() > 0) {
				String dest;
				//Prepare string for writing
				dest.Resize(respnonse->GetAvailableSize());
				//Read the buffer data into the string
				respnonse->Read((void*)dest.CString(), respnonse->GetAvailableSize());
				URHO3D_LOGINFO(dest);
				done = true;
			}
		}
	}
}

void Requests::showHelp()
{
    URHO3D_LOGRAW("Input 'connect http://some_url' to make a HTTP request");
}
