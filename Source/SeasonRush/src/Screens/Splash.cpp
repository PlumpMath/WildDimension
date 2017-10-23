#include "Urho3D/Urho3DAll.h"
#include "Screens/Splash.h"
#include "Events.h"

using namespace Urho3D;

Splash::Splash(Context* context) :
Urho3D::LogicComponent(context),
_time(0),
_logoIndex(0)
{
	SetUpdateEventMask(USE_POSTUPDATE);
}


Splash::~Splash()
{
}


void Splash::RegisterObject(Context* context)
{
	context->RegisterFactory<Splash>();
}

void Splash::show()
{
	_fader = new Fader(context_);
	_fader->BlackScreen();
	_fader->FadeIn(0.5f);
	ResourceCache* cache = GetSubsystem<ResourceCache>();
	UI* ui = GetSubsystem<UI>();
	_logo = new BorderImage(context_);
	_logo->SetName("Splash");
	Texture2D* texture = cache->GetResource<Texture2D>("Textures/christmas/logo.png");
	_logo->SetTexture(texture); // Set texture
	_logo->SetBlendMode(BlendMode::BLEND_ALPHA);
    int vpWidth = GetSubsystem<Graphics>()->GetWidth();
    int vpHEight = GetSubsystem<Graphics>()->GetHeight();
    int w = texture->GetWidth() * (float)vpWidth / 1920.0f;
    int h = texture->GetHeight() * (float) ((float)w / (float)texture->GetWidth());
    _logo->SetSize(w, h);
	_logo->SetAlignment(HA_CENTER, VA_CENTER);
	_logo->SetFullImageRect();
	ui->GetRoot()->AddChild(_logo);
	GetSubsystem<Engine>()->RunFrame(); // Render Splash immediately
}

void Splash::PostUpdate(float timeStep)
{
	_time += timeStep;
	if (_time > 2 && _logoIndex == 0) {
		_logoIndex = 1;
		_fader->FadeOut(1.0f); // 1.0f - fade time in seconds
	}

	if (_time > 3 && _logo && _logoIndex == 1) {
		_logoIndex = 2;
		_fader->FadeIn(0.5f);
		_logo->Remove();
		_logo = nullptr;
		ResourceCache* cache = GetSubsystem<ResourceCache>();
		UI* ui = GetSubsystem<UI>();
		_gameLogo = new BorderImage(context_);
		_gameLogo->SetName("Splash");
		Texture2D* texture = cache->GetResource<Texture2D>("Textures/christmas/game_logo.png");
		_gameLogo->SetTexture(texture); // Set texture
		_gameLogo->SetBlendMode(BlendMode::BLEND_ALPHA);
        int vpWidth = GetSubsystem<Graphics>()->GetWidth();
        int vpHEight = GetSubsystem<Graphics>()->GetHeight();
        int w = texture->GetWidth() * (float)vpWidth / 1920.0f;
        int h = texture->GetHeight() * (float)((float)w / (float)texture->GetWidth());
        _gameLogo->SetSize(w, h);
		_gameLogo->SetAlignment(HA_CENTER, VA_CENTER);
		_gameLogo->SetFullImageRect();
		ui->GetRoot()->AddChild(_gameLogo);
		GetSubsystem<Engine>()->RunFrame(); // Render Splash immediately

	}

	if (_time > 5 && _logoIndex == 2) {
		_logoIndex = 3;
		_fader->FadeOut(0.5f);
	}
	if (_time > 5.5 && _logoIndex == 3) {
		_gameLogo->SetVisible(false);
	}
	if (_time > 6 && _logoIndex == 3) {
		_logoIndex = 4;
		destroy();
		SendEvent(E_SPLASHSCREEN_END);
	}
}

void Splash::destroy()
{
	UI* ui = GetSubsystem<UI>();
	ui->GetRoot()->RemoveAllChildren();
	//delete _fader;
}