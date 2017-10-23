#pragma once
#include <Urho3D/Urho3DAll.h>

using namespace Urho3D;

class DebugDraw : public Component
{
private:
	SharedPtr<Text> _currentVersion;
	SharedPtr<Text> _latestVersion;

public:
	DebugDraw(Context* context);
	~DebugDraw();

	/// Register object factory and attributes.
	static void RegisterObject(Context* context);

	/**
	 * Draws version number on the screen
	 */
	void showVersion();

	/**
	 * Toggle visibility of the debug view
	 */
	void setVisibility(bool val);

	/**
	 * Show the latest available version from server
	 */
	void showLatestVersionAvailable(String ver);

	URHO3D_OBJECT(DebugDraw, Urho3D::Component);
};

