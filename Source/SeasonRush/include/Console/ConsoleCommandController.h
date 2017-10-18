#pragma once
#include "Urho3D/Urho3DAll.h"
#include <list>
#include <vector>
#include "ConsoleCommandHandler.h"

using namespace Urho3D;

class ConsoleCommandController: public Component
{
private:
	std::list<SharedPtr<ConsoleCommandHandler>> _handlers;

public:
	ConsoleCommandController(Context* context);
	~ConsoleCommandController();

	/// Register object factory and attributes.
	static void RegisterObject(Context* context);

    void loadAutocompleteData();

	/**
	 * Parse player input
	 */
	void parse(const String& input);

	URHO3D_OBJECT(ConsoleCommandController, Urho3D::Component);
};

