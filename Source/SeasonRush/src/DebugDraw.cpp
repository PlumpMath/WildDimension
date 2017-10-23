#include <Urho3D/Urho3DAll.h>
#include "DebugDraw.h"
#include "version.h"
#include "Fonts.h"

DebugDraw::DebugDraw(Context* context):
Component(context)
{
}


DebugDraw::~DebugDraw()
{
	if (_currentVersion) {
		_currentVersion->Remove();
		_currentVersion = nullptr;
	}

	if (_latestVersion) {
		_latestVersion->Remove();
		_latestVersion = nullptr;
	}
}

void DebugDraw::RegisterObject(Context* context)
{
	context->RegisterFactory<DebugDraw>();
}

void DebugDraw::showVersion()
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();

	// Construct new Text object
	_currentVersion = (new Text(context_));

	// Set String to display
	_currentVersion->SetText(String("Version ") + VERSION);

	// Set font and text color
	_currentVersion->SetFont(cache->GetResource<Font>(FONT_DEBUG), 10);
	_currentVersion->SetColor(Color::GREEN);
    _currentVersion->SetEffectRoundStroke(true);
    _currentVersion->SetEffectStrokeThickness(2);
    _currentVersion->SetTextEffect(TextEffect::TE_STROKE);

	// Align Text center-screen
	_currentVersion->SetHorizontalAlignment(HA_LEFT);
	_currentVersion->SetVerticalAlignment(VA_TOP);
    _currentVersion->SetPosition(IntVector2(5, 0));

	// Add Text instance to the UI root element
	GetSubsystem<UI>()->GetRoot()->AddChild(_currentVersion);
}

void DebugDraw::showLatestVersionAvailable(String ver)
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();
    
    if (!_currentVersion) {
        showVersion();
    }

    if (_currentVersion && ver.Compare(VERSION) != 0) {
        _currentVersion->SetText(String("Version ") + VERSION + " (Available: " + ver + ")");
        _currentVersion->SetColor(Color::RED);
    }
}

void DebugDraw::setVisibility(bool val)
{
	if (_latestVersion) {
		_latestVersion->SetVisible(val);
	}
	if (_currentVersion) {
		_currentVersion->SetVisible(val);
	}
}