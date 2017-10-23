#pragma once
#include "Console/ConsoleCommandHandler.h"

class SoundActions: public ConsoleCommandHandler
{
public:
	SoundActions(Context* context);
	~SoundActions();

	virtual void runCommand();

	/**
	 * Show the help
	 */
	virtual void showHelp();
};

