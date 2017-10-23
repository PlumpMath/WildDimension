#include "Urho3D/Urho3DAll.h"
#include "MainMenu.h"
#include "JSONParse.h"
#include "LanBroadcast.h"
#include "Events.h"
#include "Config/Config.h"
#include <Urho3D/Urho3DAll.h>
#include "Fonts.h"

using namespace Urho3D;

void broadcastListenThreadFunction()
{
	LanBroadcast::instance().startListening();
}

MainMenu::MainMenu(Context* context) :
Urho3D::Component(context),
_newsPosts(0),
resolutionChoice("")
{
}


MainMenu::~MainMenu()
{
}


void MainMenu::RegisterObject(Context* context)
{
	context->RegisterFactory<MainMenu>();
}

void MainMenu::draw()
{
    if (!GetSubsystem<Graphics>()) {
        return;
    }

	GetSubsystem<Input>()->SetMouseVisible(true);
	GetSubsystem<Input>()->SetMouseGrabbed(false);

	ResourceCache* cache = GetSubsystem<ResourceCache>();
	UI* ui = GetSubsystem<UI>();

	_settingsButton = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/settings_button.xml"));
	_exitButton = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/exit_button.xml"));
	//_newButton = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/new_button.xml"));
	ui->GetRoot()->AddChild(_settingsButton);
	ui->GetRoot()->AddChild(_exitButton);

    createNicknameBox();

    _achievmentsButton = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/achievments_button.xml"));
    ui->GetRoot()->AddChild(_achievmentsButton);

    _leaderboardButton = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/leaderboard_button.xml"));
    ui->GetRoot()->AddChild(_leaderboardButton);
    Button* leaderboardButton = static_cast<Button*>(_leaderboardButton->GetChild("leaderboardButton", true));
    if (leaderboardButton) {
        SubscribeToEvent(leaderboardButton, E_RELEASED, URHO3D_HANDLER(MainMenu, HandleCreateLeaderboard));
    }

	Button* settingsButton = static_cast<Button*>(_settingsButton->GetChild("settingsButton", true));
	if (settingsButton) {
		SubscribeToEvent(settingsButton, E_RELEASED, URHO3D_HANDLER(MainMenu, showSettings));
	}

	Button* exitButton = static_cast<Button*>(_exitButton->GetChild("exitButton", true));
	if (exitButton) {
		SubscribeToEvent(exitButton, E_RELEASED, URHO3D_HANDLER(MainMenu, exitGame));
	}

	/*Button* newButton = static_cast<Button*>(_newButton->GetChild("newButton", true));
	if (newButton) {
		//SubscribeToEvent(newButton, E_RELEASED, URHO3D_HANDLER(MainMenu, startGame));
        SubscribeToEvent(newButton, E_RELEASED, URHO3D_HANDLER(MainMenu, showNewGameOptions));
	}*/

    createNewGameWindow();
}

void MainMenu::createNewGameWindow()
{
    closeLeaderboard();
    if (!_gameSettings) {
        ResourceCache* cache = GetSubsystem<ResourceCache>();
        UI* ui = GetSubsystem<UI>();
        _gameSettings = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/new_game_options.xml"));
        ui->GetRoot()->AddChild(_gameSettings);
        Button* startGame = static_cast<Button*>(_gameSettings->GetChild("startGame", true));
        if (startGame) {
            //SubscribeToEvent(newButton, E_RELEASED, URHO3D_HANDLER(MainMenu, startGame));
            SubscribeToEvent(startGame, E_RELEASED, URHO3D_HANDLER(MainMenu, startGame));
        }

        Slider* carSlider = static_cast<Slider*>(_gameSettings->GetChild("carCountSlider", true));
        if (carSlider) {
            carSlider->SetValue(0.1f);
            SubscribeToEvent(carSlider, E_SLIDERCHANGED, URHO3D_HANDLER(MainMenu, changeCarCount));
            Text* carCount = static_cast<Text*>(_gameSettings->GetChild("carCountValue", true));
            if (carCount) {
                int count = carSlider->GetValue() * 100;
                carCount->SetText(String(count));
                _startGameOptions.cars = count;
            }
        }

        Slider* sledSlider = static_cast<Slider*>(_gameSettings->GetChild("sledCountSlider", true));
        if (sledSlider) {
            sledSlider->SetValue(0.1f);
            SubscribeToEvent(sledSlider, E_SLIDERCHANGED, URHO3D_HANDLER(MainMenu, changeSledCount));
            Text* sledCount = static_cast<Text*>(_gameSettings->GetChild("sledCountValue", true));
            if (sledCount) {
                int count = sledSlider->GetValue() * 100;
                sledCount->SetText(String(count));
                _startGameOptions.sleds = count;
            }
        }

        CheckBox* aiFollowCheckbox = static_cast<CheckBox*>(_gameSettings->GetChild("aiChasing", true));
        aiFollowCheckbox->SetChecked(_startGameOptions.aiChasing);
        if (aiFollowCheckbox) {
            //SubscribeToEvent(newButton, E_RELEASED, URHO3D_HANDLER(MainMenu, startGame));
            SubscribeToEvent(aiFollowCheckbox, E_TOGGLED, URHO3D_HANDLER(MainMenu, setAIFollow));
        }

        Button* closeButton = static_cast<Button*>(_gameSettings->GetChild("closeButton", true));
        if (closeButton) {
            closeButton->SetVisible(false);
        }

        DropDownList* startVehicleDropdown = static_cast<DropDownList*>(_gameSettings->GetChild("startingVehicleDropdown", true));
        startVehicleDropdown->SetResizePopup(true);

        if (startVehicleDropdown) {
            Vector<String> options;
            options.Push("Sled");
            options.Push("Car");

            for (auto it = options.Begin(); it != options.End(); ++it) {
                Text* text = new Text(context_);
                text->SetStyle("ConsoleText");
                text->SetText((*it));
                text->SetWidth(startVehicleDropdown->GetWidth());
                startVehicleDropdown->AddItem(text);
            }

            SubscribeToEvent(startVehicleDropdown, E_ITEMSELECTED, URHO3D_HANDLER(MainMenu, setStartVehicle));
        }
    }
}

void MainMenu::closeNewGameWindow()
{
    if (_gameSettings) {
        _gameSettings->Remove();
        _gameSettings = nullptr;
    }
}

void MainMenu::createLeaderboard()
{
    if (!_leaderboard) {
        VariantMap map;
        StringHash hash;
        closeSettings(hash, map);
        closeNewGameWindow();
        ResourceCache* cache = GetSubsystem<ResourceCache>();
        UI* ui = GetSubsystem<UI>();
        _leaderboard = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/leaderboard.xml"));
        ui->GetRoot()->AddChild(_leaderboard);

        Button* closeButton = static_cast<Button*>(_leaderboard->GetChild("closeButton", true));
        if (closeButton) {
            SubscribeToEvent(closeButton, E_RELEASED, URHO3D_HANDLER(MainMenu, HandleCloseLeaderboard));
        }

        UIElement* scoreView = static_cast<UIElement*>(_leaderboard->GetChild("scoreView", true));
        if (scoreView) {
            int elementHeight = 12;
            int border = elementHeight + 10;
            int posY = 0;
            for (int i = 0; i < 16; i++) {
                Text* nicknameElement = new Text(context_);
                nicknameElement->SetAlignment(HorizontalAlignment::HA_LEFT, VerticalAlignment::VA_TOP);
                nicknameElement->SetPosition(IntVector2(0, 0));
                nicknameElement->SetHeight(elementHeight);
                nicknameElement->SetFont(cache->GetResource<Font>(FONT_PLAYER_LIST), elementHeight);
                nicknameElement->SetTextEffect(TextEffect::TE_STROKE);
                nicknameElement->SetEffectRoundStroke(true);
                nicknameElement->SetEffectStrokeThickness(1);
                nicknameElement->SetPosition(IntVector2(0, posY));

                scoreView->AddChild(nicknameElement);

                Text* checkpointsElement = new Text(context_);
                checkpointsElement->SetAlignment(HorizontalAlignment::HA_CENTER, VerticalAlignment::VA_TOP);
                checkpointsElement->SetPosition(IntVector2(0, 0));
                checkpointsElement->SetHeight(elementHeight);
                checkpointsElement->SetFont(cache->GetResource<Font>(FONT_PLAYER_LIST), elementHeight);
                checkpointsElement->SetTextEffect(TextEffect::TE_STROKE);
                checkpointsElement->SetEffectRoundStroke(true);
                checkpointsElement->SetEffectStrokeThickness(1);
                checkpointsElement->SetPosition(IntVector2(0, posY));
                scoreView->AddChild(checkpointsElement);

                Text* racetimeElement = new Text(context_);
                racetimeElement->SetAlignment(HorizontalAlignment::HA_RIGHT, VerticalAlignment::VA_TOP);
                racetimeElement->SetPosition(IntVector2(0, 0));
                racetimeElement->SetHeight(elementHeight);
                racetimeElement->SetFont(cache->GetResource<Font>(FONT_PLAYER_LIST), elementHeight);
                racetimeElement->SetTextEffect(TextEffect::TE_STROKE);
                racetimeElement->SetEffectRoundStroke(true);
                racetimeElement->SetEffectStrokeThickness(1);
                racetimeElement->SetPosition(IntVector2(0, posY));
                scoreView->AddChild(racetimeElement);

                if (i == 0) {
                    nicknameElement->SetFontSize(elementHeight + 2);
                    checkpointsElement->SetFontSize(elementHeight + 2);
                    racetimeElement->SetFontSize(elementHeight + 2);
                    posY += elementHeight;

                    nicknameElement->SetText("Nickname");
                    checkpointsElement->SetText("Checkpoints");
                    racetimeElement->SetText("Time");

                    nicknameElement->SetColor(Color(255 / 255.0f, 156 / 255.0f, 17 / 255.0f));
                    checkpointsElement->SetColor(Color(255 / 255.0f, 156 / 255.0f, 17 / 255.0f));
                    racetimeElement->SetColor(Color(255 / 255.0f, 156 / 255.0f, 17 / 255.0f));
                }
                else {
                    nicknameElement->SetColor(Color(0.54, 0.54, 0.54));
                    checkpointsElement->SetColor(Color(0.54, 0.54, 0.54));
                    racetimeElement->SetColor(Color(0.54, 0.54, 0.54));
                }

                posY += border;
                LeaderboardItem listItem;
                listItem.nickname = nicknameElement;
                listItem.checkpoints = checkpointsElement;
                listItem.racetime = racetimeElement;
                _leaderboardList.Push(listItem);
            }
        }
        SubscribeToEvent(E_ADD_LEADERBOARD_ITEM, URHO3D_HANDLER(MainMenu, HandleAddLeaderboardItem));

        SendEvent(E_LOAD_LEADERBOARD);
    }
}

String MainMenu::getTimeFormat(int t)
{
    t /= 1000;
    unsigned int minutes = (t - ((int)t % 60)) / 60;
    t -= minutes * 60;
    unsigned int seconds = (int)t;
    String minutesString;
    String secondsString;
    if (minutes < 10) {
        minutesString = "0" + String(minutes);
    }
    else {
        minutesString = String(minutes);
    }
    if (seconds < 10) {
        secondsString = "0" + String(seconds);
    }
    else {
        secondsString = String(seconds);
    }
    String timeFormat(minutesString + ":" + secondsString);
    return timeFormat;
}

void MainMenu::HandleAddLeaderboardItem(StringHash eventType, VariantMap& eventData)
{
    if (_leaderboard) {
        String nickname = eventData[P_PLAYER_NAME].GetString();
        unsigned int checkpoints = eventData[P_CHECKPOINT_COUNT].GetUInt();
        int racetime = eventData[P_RACE_TIME].GetInt();
        int index = eventData[P_INDEX].GetInt();
        //First item is reserved for table headers
        index++;

        if (index < _leaderboardList.Size()) {
            _leaderboardList.At(index).nickname->SetText(nickname);
            _leaderboardList.At(index).checkpoints->SetText(String(checkpoints));
            _leaderboardList.At(index).racetime->SetText(getTimeFormat(racetime));
        }
    }
}

void MainMenu::HandleCreateLeaderboard(StringHash eventType, VariantMap& eventData)
{
    createLeaderboard();
}

void MainMenu::HandleCloseLeaderboard(StringHash eventType, VariantMap& eventData)
{
    closeLeaderboard();
    createNewGameWindow();
}

void MainMenu::closeLeaderboard()
{
    if (_leaderboard) {
        _leaderboardList.Clear();
        _leaderboard->Remove();
        _leaderboard = nullptr;
        UnsubscribeFromEvent(E_ADD_LEADERBOARD_ITEM);
    }
}

void MainMenu::changeCarCount(StringHash eventType, VariantMap& eventData)
{
    float val = eventData[P_VALUE].GetFloat();
    int count = val * 100;
    URHO3D_LOGINFOF("Car slider value changed to %d", count);
    Text* carCount = static_cast<Text*>(_gameSettings->GetChild("carCountValue", true));
    if (carCount) {
        carCount->SetText(String(count));
        _startGameOptions.cars = count;
    }
}

void MainMenu::changeSledCount(StringHash eventType, VariantMap& eventData)
{
    float val = eventData[P_VALUE].GetFloat();
    int count = val * 100;
    URHO3D_LOGINFOF("Sled slider value changed to %d", count);
    Text* sledCount = static_cast<Text*>(_gameSettings->GetChild("sledCountValue", true));
    if (sledCount) {
        sledCount->SetText(String(count));
        _startGameOptions.sleds = count;
    }
}

void MainMenu::setStartVehicle(StringHash eventType, VariantMap& eventData)
{
    using namespace ItemSelected;
    DropDownList* dropdown = static_cast<DropDownList*>(eventData[P_ELEMENT].GetPtr());
    String choice = static_cast<Text*>(dropdown->GetSelectedItem())->GetText();
    if (choice == "Sled") {
        _startGameOptions.startVehicle = 0;
    }
    else {
        _startGameOptions.startVehicle = 1;
    }
}

void MainMenu::setAIFollow(StringHash eventType, VariantMap& eventData)
{
    using namespace Toggled;
    _startGameOptions.aiChasing = eventData[P_STATE].GetBool();
    URHO3D_LOGINFOF("AI follow changed to %d", _startGameOptions.aiChasing);
}

void MainMenu::showSettings(StringHash eventType, VariantMap& eventData)
{
    if (_gameSettings) {
        _gameSettings->Remove();
        _gameSettings = nullptr;
    }
    closeLeaderboard();
	if (!_settingsView) {
		ResourceCache* cache = GetSubsystem<ResourceCache>();
		UI* ui = GetSubsystem<UI>();
		_settingsView = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/settings.xml"));
		ui->GetRoot()->AddChild(_settingsView);

		Button* saveButton = static_cast<Button*>(_settingsView->GetChild("saveButton", true));
		if (saveButton) {
			SubscribeToEvent(saveButton, E_RELEASED, URHO3D_HANDLER(MainMenu, saveSettings));
		}

		Button* closeButton = static_cast<Button*>(_settingsView->GetChild("closeButton", true));
		if (closeButton) {
			SubscribeToEvent(closeButton, E_RELEASED, URHO3D_HANDLER(MainMenu, closeSettings));
		}

		_fullscreenCheckbox = static_cast<CheckBox*>(_settingsView->GetChild("fullscreenOption", true));
		_fullscreenCheckbox->SetChecked(Config::instance().getConfig().fullscreen);

		if (_fullscreenCheckbox) {
			SubscribeToEvent(_fullscreenCheckbox, E_TOGGLED, URHO3D_HANDLER(MainMenu, HandleFullscreenChange));
		}

		_resolutionDropdown = static_cast<DropDownList*>(_settingsView->GetChild("resolutionDropdown", true));
        _resolutionDropdown->SetResizePopup(true);

		if (_resolutionDropdown) {
			Vector<String> resolutions;
			resolutions.Push("1920 x 1080");
            resolutions.Push("1600 x 1900");
            resolutions.Push("1366 x 768");
			resolutions.Push("1280 x 720");
            resolutions.Push("1024 x 768");
            resolutions.Push("800 x 600");
            resolutions.Push("640 x 480");

			for (auto it = resolutions.Begin(); it != resolutions.End(); ++it) {
				Text* text = new Text(context_);
				text->SetStyle("ConsoleText");
				text->SetText((*it));
				text->SetWidth(_resolutionDropdown->GetWidth());
				_resolutionDropdown->AddItem(text);

                if ((*it).Compare(String(Config::instance().getConfig().width) + " x " + String(Config::instance().getConfig().height)) == 0) {
                    _resolutionDropdown->SetSelection(_resolutionDropdown->GetNumItems() - 1);
                }
			}

			SubscribeToEvent(_resolutionDropdown, E_ITEMSELECTED, URHO3D_HANDLER(MainMenu, HandleResolutionChange));
		}
	}
	_settingsView->SetVisible(true);
}

void MainMenu::HandleResolutionChange(StringHash eventType, VariantMap& eventData)
{
	String choice = static_cast<Text*>(_resolutionDropdown->GetSelectedItem())->GetText();
	resolutionChoice = choice;
}

void MainMenu::HandleFullscreenChange(StringHash eventType, VariantMap& eventData)
{
}

void MainMenu::saveSettings(StringHash eventType, VariantMap& eventData)
{
	if (resolutionChoice != "") {
		int width;
		int height;

		sscanf(resolutionChoice.CString(), "%d x %d", &width, &height);
		Config::instance().setResolution(width, height);
	}

    bool differ = false;
    if (Config::instance().getConfig().fullscreen != _fullscreenCheckbox->IsChecked()) {
        differ = true;
    }
	Config::instance().setFullscreen(_fullscreenCheckbox->IsChecked());

	Config::instance().write();
    _settingsView->Remove();
    _settingsView = nullptr;

    IntVector2 position;
    IntVector2 oldSize;
    IntVector2 newSize;
    if (!GetSubsystem<Graphics>()->GetFullscreen()) {
        position = GetSubsystem<Graphics>()->GetWindowPosition();
        oldSize.x_ = GetSubsystem<Graphics>()->GetWidth();
        oldSize.y_ = GetSubsystem<Graphics>()->GetHeight();
    }
    GetSubsystem<Graphics>()->SetMode(Config::instance().getConfig().width, Config::instance().getConfig().height);
    
    if (differ) {
        GetSubsystem<Graphics>()->ToggleFullscreen();
    }

    if (!GetSubsystem<Graphics>()->GetFullscreen()) {
        newSize.x_ = GetSubsystem<Graphics>()->GetWidth();
        newSize.y_ = GetSubsystem<Graphics>()->GetHeight();
        position += (oldSize - newSize) / 2;
        GetSubsystem<Graphics>()->SetWindowPosition(position);
    }
    
    SendEvent(E_GRAPHICS_CHANGED);

    createNewGameWindow();
}

void MainMenu::closeSettings(StringHash eventType, VariantMap& eventData)
{
    if (_settingsView) {
        _settingsView->Remove();
        _settingsView = nullptr;
    }
    createNewGameWindow();
}

void MainMenu::exitGame(StringHash eventType, VariantMap& eventData)
{
	SendEvent(E_GAME_EXIT);
}

void MainMenu::startGame(StringHash eventType, VariantMap& eventData)
{
    VariantMap map;
    map[P_GAME_SETTINGS_START_VEHICLE] = _startGameOptions.startVehicle;
    map[P_GAME_SETTINGS_CAR_COUNT] = _startGameOptions.cars;
    map[P_GAME_SETTINGS_SLED_COUNT] = _startGameOptions.sleds;
    map[P_GAME_SETTINGS_AI_FOLLOW] = _startGameOptions.aiChasing;
	SendEvent(E_GAME_NEW, map);
	show(false);
}

void MainMenu::show(bool val)
{
    if (!GetSubsystem<Graphics>()) {
        return;
    }

	/*if (_newButton) {
		_newButton->SetVisible(val);
	}*/
    if (_gameSettings) {
        _gameSettings->Remove();
        _gameSettings = nullptr;
    }
    if (val) {
        createNewGameWindow();
    }
	if (_settingsButton) {
		_settingsButton->SetVisible(val);
	}
    if (_leaderboardButton) {
        _leaderboardButton->SetVisible(val);
    }
    if (_achievmentsButton) {
        _achievmentsButton->SetVisible(val);
    }
	if (_exitButton) {
		_exitButton->SetVisible(val);
	}
	if (_settingsView) {
        if (val == false) {
            _settingsView->Remove();
            _settingsView = nullptr;
        }
	}

    if (val) {
        createNicknameBox();
    }
    else {
        closeNicknameBox();
    }
}

void MainMenu::createNicknameBox()
{
    if (!_nicknameBox) {
        ResourceCache* cache = GetSubsystem<ResourceCache>();
        UI* ui = GetSubsystem<UI>();
        _nicknameBox = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/nickname_box.xml"));
        ui->GetRoot()->AddChild(_nicknameBox);

        _nicknameInputField = static_cast<LineEdit*>(_nicknameBox->GetChild("nicknameBox", true));
        if (_nicknameInputField) {
            _nicknameInputField->SetText(Config::instance().getConfig().nickname.c_str());
            SubscribeToEvent(_nicknameInputField, E_RELEASED, URHO3D_HANDLER(MainMenu, HandleCreateLeaderboard));
        }

        Text* nicknameLabel = static_cast<Text*>(_nicknameBox->GetChild("nicknameLabel", true));
        if (nicknameLabel) {
            if (Config::instance().getConfig().nickname.length() > 0) {
                nicknameLabel->SetVisible(false);
            }
            SubscribeToEvent(nicknameLabel, E_RELEASED, URHO3D_HANDLER(MainMenu, HandleInputSelected));
        }

        SubscribeToEvent(E_TEXTCHANGED, URHO3D_HANDLER(MainMenu, HandleNicknameChanged));
    }
}

void MainMenu::closeNicknameBox()
{
    if (_nicknameBox) {
        _nicknameInputField->Remove();
        _nicknameInputField = nullptr;

        _nicknameBox->Remove();
        _nicknameBox = nullptr;

        UnsubscribeFromEvent(E_TEXTCHANGED);
    }
}

void MainMenu::HandleInputSelected(StringHash eventType, VariantMap& eventData)
{
    _nicknameInputField = static_cast<LineEdit*>(_nicknameBox->GetChild("nicknameBox", true));
    if (_nicknameInputField) {
        _nicknameBox->SetFocus(true);
    }
}

void MainMenu::HandleNicknameChanged(StringHash eventType, VariantMap& eventData)
{
    if (_nicknameBox) {
        using namespace TextChanged;
        String value = eventData[P_TEXT].GetString();
        Text* nicknameLabel = static_cast<Text*>(_nicknameBox->GetChild("nicknameLabel", true));
        Config::instance().setNickname(std::string(value.CString()));
        if (nicknameLabel) {
            if (nicknameLabel && value.Length() == 0) {
                nicknameLabel->SetVisible(true);
            }
            else {
                nicknameLabel->SetVisible(false);
            }
        }
    }
}