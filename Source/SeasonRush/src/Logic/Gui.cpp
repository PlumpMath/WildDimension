#include "Urho3D/Urho3DAll.h"
#include "Logic/Gui.h"
#include "Logic/Players.h"
#include "Events.h"
#include "Fonts.h"
#include "Config/Config.h"

using namespace Urho3D;

Gui::Gui(Context* context) :
Urho3D::Component(context),
_countdownTimer(3),
_gameStarted(false),
_finishReached(false),
_gameTimer(0.0f),
_globalTimer(0.0f),
_currentPosition(0),
_currentPoints(0)
{
}

Gui::~Gui()
{
	if (_checkpointsCounter) {
        _checkpointsCounter->Remove();
        _checkpointsCounter = nullptr;
	}
	if (_scoreLayout) {
		_scoreLayout->Remove();
		_scoreLayout = nullptr;
	}
    if (_finalScore) {
        _finalScore->Remove();
        _finalScore = nullptr;
    }
	if (_countdown) {
		_countdown->Remove();
		_countdown = nullptr;
	}

    if (_latestEventsElement) {
        _latestEvents.Clear();
        _latestEventsElement->Remove();
        _latestEventsElement = nullptr;
    }

    if (_timerElement) {
        _timerElement->Remove();
        _timerElement = nullptr;
    }

    if (_positionsView) {
        _positionsView->Remove();
        _positionsView = nullptr;
    }
}

void Gui::init()
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();
	UI* ui = GetSubsystem<UI>();

	if (!_checkpointsCounter) {
        _checkpointsCounter = new Text(context_);
        _checkpointsCounter->SetAlignment(HorizontalAlignment::HA_CENTER, VerticalAlignment::VA_TOP);
        _checkpointsCounter->SetFont(cache->GetResource<Font>(FONT_PLAYER_LIST), 18);
        _checkpointsCounter->SetPosition(IntVector2(0, 0));
        _checkpointsCounter->SetColor(Color::GREEN);
        _checkpointsCounter->SetEffectRoundStroke(true);
        _checkpointsCounter->SetEffectStrokeThickness(2);
        _checkpointsCounter->SetTextEffect(TextEffect::TE_STROKE);
        _checkpointsCounter->SetText("Checkpoints: 0");
		ui->GetRoot()->AddChild(_checkpointsCounter);
	}

    if (!_timerElement) {
        _timerElement = new Text(context_);
        _timerElement->SetAlignment(HorizontalAlignment::HA_CENTER, VerticalAlignment::VA_TOP);
        _timerElement->SetFont(cache->GetResource<Font>(FONT_PLAYER_LIST), 18);
        _timerElement->SetPosition(IntVector2(0, 28));
        _timerElement->SetColor(Color::GREEN);
        _timerElement->SetTextEffect(TextEffect::TE_STROKE);
        _timerElement->SetEffectRoundStroke(true);
        _timerElement->SetEffectStrokeThickness(2);
        _timerElement->SetText("00:00");
        ui->GetRoot()->AddChild(_timerElement);
    }

	if (!_countdown) {
		_countdown = new Text(context_);
		_countdown->SetAlignment(HorizontalAlignment::HA_CENTER, VerticalAlignment::VA_CENTER);
		_countdown->SetFont(cache->GetResource<Font>(FONT_DEFAULT), 100);
		_countdown->SetColor(Color::WHITE);
		_countdown->SetTextEffect(TextEffect::TE_STROKE);
		ui->GetRoot()->AddChild(_countdown);
	}
	_countdown->SetText("");

	//Create score layout
	_scoreLayout = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/score.xml"));
	ui->GetRoot()->AddChild(_scoreLayout);
	toggleScore(false);

    if (!_latestEventsElement) {
        _latestEventsElement = new UIElement(context_);
        _latestEventsElement->SetAlignment(HorizontalAlignment::HA_LEFT, VerticalAlignment::VA_BOTTOM);
        _latestEventsElement->SetPosition(IntVector2(10, 0));
        ui->GetRoot()->AddChild(_latestEventsElement);

        int elementHeight = 8;
        int border = elementHeight + 6;
        int posY = 10 * (-border);
        for (int i = 0; i < 10; i++) {
            Text* evt = new Text(context_);
            evt->SetAlignment(HorizontalAlignment::HA_LEFT, VerticalAlignment::VA_BOTTOM);
            evt->SetPosition(IntVector2(0, 0));
            evt->SetHeight(elementHeight);
            evt->SetFont(cache->GetResource<Font>(FONT_PLAYER_LIST), elementHeight);
            evt->SetColor(Color::WHITE);
            evt->SetTextEffect(TextEffect::TE_STROKE);
            evt->SetEffectRoundStroke(true);
            evt->SetEffectStrokeThickness(1);

            evt->SetPosition(IntVector2(0, posY));
            _latestEventsElement->AddChild(evt);
            posY += border;
            _latestEvents.Push(SharedPtr<Text>(evt));
        }
    }

    if (!_positionsView) {
        _positionsView = new UIElement(context_);
        _positionsView->SetAlignment(HorizontalAlignment::HA_RIGHT, VerticalAlignment::VA_CENTER);
        _positionsView->SetPosition(IntVector2(-150, -50));
        ui->GetRoot()->AddChild(_positionsView);

        int elementHeight = 8;
        int border = elementHeight + 6;
        int posY = -200;
        for (int i = 0; i < 5; i++) {
            Text* evt = new Text(context_);
            evt->SetAlignment(HorizontalAlignment::HA_LEFT, VerticalAlignment::VA_BOTTOM);
            evt->SetPosition(IntVector2(0, 0));
            evt->SetHeight(elementHeight);
            evt->SetFont(cache->GetResource<Font>(FONT_PLAYER_LIST), elementHeight);
            evt->SetColor(Color::WHITE);
            evt->SetTextEffect(TextEffect::TE_STROKE);
            evt->SetEffectRoundStroke(true);
            evt->SetEffectStrokeThickness(2);

            evt->SetPosition(IntVector2(0, posY));
            if (i == 2) {
                posY += border;
                evt->SetFontSize(elementHeight * 2);
                evt->SetPosition(IntVector2(0, posY));\
            }
            _positionsView->AddChild(evt);
            posY += border;
            _positions.Push(SharedPtr<Text>(evt));
        }
    }

	subscribe();
}

void Gui::RegisterObject(Context* context)
{
	context->RegisterFactory<Gui>();
}

void Gui::subscribe()
{
	SubscribeToEvent(E_TOGGLE_SCORE, URHO3D_HANDLER(Gui, updateScoreBoard));
	SubscribeToEvent(E_UPDATE_SCORE, URHO3D_HANDLER(Gui, updateScoreBoard));
    SubscribeToEvent(E_REMOVE_DRIVEABLES, URHO3D_HANDLER(Gui, updateScoreBoard));

	SubscribeToEvent(E_GUI_POINTS_CHANGED, URHO3D_HANDLER(Gui, HandleGuiUpdate));
	SubscribeToEvent(E_GAME_COUNTDOWN_START, URHO3D_HANDLER(Gui, HandleStartCountdown));

    SubscribeToEvent(E_SET_PLAYER_ID, URHO3D_HANDLER(Gui, HandlePlayerID));

    SubscribeToEvent(E_SHOW_FINAL_SCORE, URHO3D_HANDLER(Gui, HandleShowFinalScore));

    SubscribeToEvent(E_CHECKPOINT_REACHED, URHO3D_HANDLER(Gui, HandlePointChange));
    SubscribeToEvent(E_LAST_CHECKPOINT_REACHED, URHO3D_HANDLER(Gui, HandlePointChange));
}

void Gui::HandleGuiUpdate(StringHash eventType, VariantMap& eventData)
{
    int id = eventData[P_PLAYER_ID].GetUInt();
    if (id != _playerId) {
        return;
    }

	//Read all received information
	unsigned int points = eventData[P_PLAYER_POINTS].GetUInt();
    _checkpointsCounter->SetText("Checkpoints: " + String(points));
    _currentPoints = calculatePoints(points);
    if (_positionsView) {
        _positions.At(2)->SetText("Points: " + String(_currentPoints));// +"; Approx. Pos: " + String(_currentPosition));
        _positions.At(3)->SetText("Your position: " + String(_currentPosition));
    }

    URHO3D_LOGINFOF("id, points %u, %u", id, points);

}

String Gui::getTimeFormat(float t)
{
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

void Gui::HandlePostUpdate(StringHash eventType, VariantMap& eventData)
{
	const float timeStep = eventData[PostUpdate::P_TIMESTEP].GetFloat();
	_countdownTimer -= timeStep;

    if (_gameStarted) {
        _globalTimer += timeStep;
    }

    if (_gameStarted && !_finishReached) {
        _gameTimer += timeStep;
        if (_timerElement) {
            _timerElement->SetText(getTimeFormat(ceil(_gameTimer)));
        }
    }

    if (_countdown) {
        int value = ceil(_countdownTimer);
        if (value < 0) {
            value = 0;
        }

        if (value <= 0 && !_gameStarted) {
            _countdown->SetText("GO!");
            SendEvent(E_GAME_COUNTDOWN_FINISHED);
            _gameStarted = true;
        }

        if (value > 0) {
            _countdown->SetText(String(value));
        }

        if (_countdownTimer < -1) {
            //UnsubscribeFromEvent(E_POSTUPDATE);
            _countdown->SetText("");
            _countdown->SetVisible(false);
            _countdown->Remove();
            _countdown = nullptr;
        }
    }
}

void Gui::HandleStartCountdown(StringHash eventType, VariantMap& eventData)
{
    ResourceCache* cache = GetSubsystem<ResourceCache>();
    Sound* sound = cache->GetResource<Sound>("Sounds/321.wav");
    Node* soundNode = node_->CreateChild("CountdownSound");
    SoundSource* soundSource = soundNode->CreateComponent<SoundSource>();
    soundSource->Play(sound);
    soundSource->SetFrequency(sound->GetFrequency());
    soundSource->SetGain(0.2f);
    soundSource->SetAutoRemoveMode(REMOVE_NODE);

	_countdownTimer = 3.18f;
	_gameStarted = false;
	_countdown->SetVisible(true);
	_countdown->BringToFront();
	SubscribeToEvent(E_POSTUPDATE, URHO3D_HANDLER(Gui, HandlePostUpdate));
}

void Gui::toggleScore(bool val)
{
    if (_finalScore) {
        return;
    }
	if (_scoreLayout) {
		_scoreLayout->SetVisible(val);
		if (val) {
			_scoreLayout->BringToFront();
		}
	}
}

void Gui::toggleScore()
{
	if (_scoreLayout) {
		toggleScore(!_scoreLayout->IsVisible());
	}
}

void Gui::updateScoreBoard(StringHash eventType, VariantMap& eventData)
{
	if (_scoreLayout) {
		if (eventType == E_TOGGLE_SCORE) {
			toggleScore();
		}
		else if (eventType == E_UPDATE_SCORE) {
			String playerName = eventData[P_PLAYER_NAME].GetString();
			unsigned int playerId = eventData[P_PLAYER_ID].GetUInt();
			unsigned int playerPoints = eventData[P_PLAYER_POINTS].GetUInt();
			unsigned int playerType = eventData[P_PLAYER_TYPE].GetUInt();

			//Set unique id based on the player vehicle type
			unsigned int uniqueID = playerId + playerType * 1000;

			if (!_scores.count(uniqueID)) {
				UIElement *list = _scoreLayout->GetChild("playerList", true);
				ResourceCache* cache = GetSubsystem<ResourceCache>();
				Text* t = new Text(context_);
				t->SetPosition(IntVector2(0, _scores.size() * 16));
				t->SetVerticalAlignment(VerticalAlignment::VA_TOP);
				t->SetHorizontalAlignment(HorizontalAlignment::HA_LEFT);
				t->SetHeight(20);
				t->SetFont(cache->GetResource<Font>(FONT_PLAYER_LIST), 12);
				t->SetColor(Color::BLACK);
				list->AddChild(t);
				_scores[uniqueID] = t;
			}
			_scores[uniqueID]->SetText(playerName + " -> " + String(playerPoints) + " checkpoints");
        }
        else if (eventType == E_REMOVE_DRIVEABLES) {
            UIElement *list = _scoreLayout->GetChild("playerList", true);
            list->RemoveAllChildren();
            for (auto it = _scores.begin(); it != _scores.end(); ++it) {
                (*it).second->Remove();
            }
            _scores.clear();
        }
	}
}

void Gui::HandlePlayerID(StringHash eventType, VariantMap& eventData)
{
    _playerId = eventData[P_PLAYER_ID].GetUInt(); 
    URHO3D_LOGINFOF("Setting GUI player ID to %d", _playerId);
}

void Gui::HandleShowFinalScore(StringHash eventType, VariantMap& eventData)
{
    _finishReached = true;
    unsigned int id = eventData[P_PLAYER_ID].GetUInt();
    if (id == _playerId) {
        if (_timerElement) {
            _timerElement->Remove();
            _timerElement = nullptr;
        }
        if (_checkpointsCounter) {
            _checkpointsCounter->Remove();
            _checkpointsCounter = nullptr;
        }
        //disable further camera movement
        SendEvent(E_END_CAMERA);
        unsigned int points = eventData[P_PLAYER_POINTS].GetFloat();
        unsigned int position = eventData[P_PLAYER_POSITION].GetUInt();
        //URHO3D_LOGINFOF("Showing final score ID: %d; POINTS: %d; TIME: %d;", id, points, _gameTimer);
        //E_SUBMIT_SCORE
        VariantMap map;
        map[P_PLAYER_NAME] = String(Config::instance().getConfig().nickname.c_str());
        map[P_VEHICLE_TYPE] = _playerScore.vehicleType;
        map[P_RACE_TIME] = _playerScore.racetime;
        map[P_CHECKPOINT_COUNT] = _playerScore.checkpoints;
        SendEvent(E_SUBMIT_SCORE, map);

        ResourceCache* cache = GetSubsystem<ResourceCache>();
        UI* ui = GetSubsystem<UI>();

        //Hide score view if it is visible
        toggleScore(false);

        if (!_finalScore) {
            _finalScore = ui->LoadLayout(cache->GetResource<XMLFile>("UI/MyLayouts/final_score.xml"));
            ui->GetRoot()->AddChild(_finalScore);
            Text* positionText = static_cast<Text*>(_finalScore->GetChild("position", true));
            if (positionText) {
                positionText->SetText(String(position));
            }
            Text* checkpointText = static_cast<Text*>(_finalScore->GetChild("checkpoints", true));
            if (checkpointText) {
                checkpointText->SetText(String(points));
            }

            Text* timeText = static_cast<Text*>(_finalScore->GetChild("time", true));
            if (timeText) {
                timeText->SetText(getTimeFormat(ceil(_gameTimer)));
            }
            Text* totalPointsText = static_cast<Text*>(_finalScore->GetChild("points", true));
            if (totalPointsText) {
                totalPointsText->SetText(String(calculatePoints(points)));
            }

            Text* pointPosition = static_cast<Text*>(_finalScore->GetChild("pointPosition", true));
            if (pointPosition) {
                pointPosition->SetText(String(_currentPosition));
            }
        }
    }
}

void Gui::HandleFinishCrossing(StringHash eventType, VariantMap& eventData)
{
    if (!_latestEvents.Empty() && _latestEventsElement) {
        unsigned int vehId = eventData[P_CP_ID].GetUInt();
        unsigned int pos = eventData[P_PLAYER_POSITION].GetUInt();
        unsigned int type = eventData[P_VEHICLE_TYPE].GetUInt();
        unsigned int checkpointId = eventData[P_CHECKPOINT_ID].GetUInt();
        unsigned int points = eventData[P_PLAYER_POINTS].GetUInt();
        points = calculatePoints(points);
        for (int i = 1; i < _latestEvents.Size(); i++) {
            _latestEvents.At(i - 1)->SetText(_latestEvents.At(i)->GetText());
        }

        String vehType("Unknown");
        if (type == 0) {
            vehType = "Sled";
        }
        else if (type == 1) {
            vehType = "Car";
        }
        if (eventType == E_CHECKPOINT_REACHED) {
            _latestEvents.At(_latestEvents.Size() - 1)->SetText(vehType + "[" + String(vehId) + "] reached checkpoint[" + String(checkpointId) + "]");
        }
        else if (eventType == E_LAST_CHECKPOINT_REACHED) {
            _latestEvents.At(_latestEvents.Size() - 1)->SetText(vehType + "[" + String(vehId) + "] reached final checkpoint[" + String(checkpointId) + "] in position[" + String(pos) + "], total points " + String(points));
        }

        _playerScore.checkpoints = eventData[P_PLAYER_POINTS].GetUInt();
        _playerScore.playerName = "Unknown";
        _playerScore.racetime = _gameTimer;
        _playerScore.vehicleType = type;
    }

    if (_positionsView) {
        _positions.Clear();
        _positionsView->Remove();
        _positionsView = nullptr;
    }
}

unsigned int Gui::calculatePoints(int checkpointsReached)
{
    int points = (checkpointsReached * 200 - _globalTimer * 4);
    if (points < 0) {
        points = 0;
    }
    return points;
}

void Gui::HandlePointChange(StringHash eventType, VariantMap& eventData)
{
    unsigned int vehId = eventData[P_CP_ID].GetUInt();
    unsigned int pos = eventData[P_PLAYER_POSITION].GetUInt();
    unsigned int type = eventData[P_VEHICLE_TYPE].GetUInt();
    unsigned int checkpointId = eventData[P_CHECKPOINT_ID].GetUInt();
    unsigned int points = eventData[P_PLAYER_POINTS].GetUInt();
    _playerPoints[vehId] = calculatePoints(points);
    if (_positionsView) {
        if (!_positions.Empty()) {
            //URHO3D_LOGINFOF("Vehicle %u got %u points", vehId, _playerPoints[vehId]);
            _currentPosition = 1;
            for (auto it = _playerPoints.begin(); it != _playerPoints.end(); ++it) {
                if ((*it).second != _currentPoints && (*it).second > _currentPoints) {
                    //URHO3D_LOGINFOF("Points less than bot %u < %u", _currentPoints, (*it).second);
                    _currentPosition++;
                }
            }
            if (_finalScore) {
                Text* pointPosition = static_cast<Text*>(_finalScore->GetChild("pointPosition", true));
                if (pointPosition) {
                    pointPosition->SetText(String(_currentPosition));
                }
            }
            _positions.At(2)->SetText("Points: " + String(_currentPoints));// +"; Approx. Pos: " + String(_currentPosition));
            _positions.At(3)->SetText("Your position: " + String(_currentPosition));
        }
    }

    if (eventType == E_LAST_CHECKPOINT_REACHED) {
        HandleFinishCrossing(eventType, eventData);
    }
}

void Gui::calculateClosestPositions()
{
}