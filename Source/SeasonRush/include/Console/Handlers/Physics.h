#pragma once
#include "Console/ConsoleCommandHandler.h"

class Physics: public ConsoleCommandHandler
{
private:
public:
	Physics(Context* context);
	~Physics();

	virtual void runCommand();

	/**
	 * Show the help
	 */
	virtual void showHelp();
};

