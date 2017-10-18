#pragma once
#include <Urho3D/Urho3DAll.h>
#include <list>
#include <map>

#include "Logic/OnePlayer.h"

using namespace Urho3D;

struct PlayerListGuiElements {
	UIElement* wrapper;
	Text* name;
	Text* points;
	Text* ping;
};

struct PlayerScore {
    unsigned int checkpoints;
    float racetime;
    unsigned int vehicleType;
    String playerName;
};

/**
 * This component should draw the users GUI on the screen, his points, health etc.
 */
class Gui : public Urho3D::Component
{
private:

	/**
	 * Subscribe to events
	 */
	void subscribe();

	SharedPtr<Text> _checkpointsCounter;
    SharedPtr<Text> _timerElement;

	SharedPtr<UIElement> _scoreLayout;

    SharedPtr<UIElement> _finalScore;

    SharedPtr<UIElement> _latestEventsElement;
    Vector<SharedPtr<Text>> _latestEvents;

    SharedPtr<UIElement> _positionsView;
    Vector<SharedPtr<Text>> _positions;

	SharedPtr<Text> _countdown;

	float _countdownTimer;

	bool _gameStarted;
    bool _finishReached;

    unsigned int _playerId;

	/**
	* Player scores
	*/
	std::map<unsigned int, Text*> _scores;

    float _gameTimer;
    float _globalTimer;

    String getTimeFormat(float t);

    std::map<unsigned int, unsigned int> _playerPoints;

    unsigned int calculatePoints(int checkpointsReached);

    void calculateClosestPositions();

    unsigned int _currentPosition;
    unsigned int _currentPoints;

    PlayerScore _playerScore;
public:
	Gui(Context* context);
	~Gui();

	void init();

	/**
	* Handle event when catcher changes
	*/
	void HandleGuiUpdate(StringHash eventType, VariantMap& eventData);

	void HandlePostUpdate(StringHash eventType, VariantMap& eventData);

	void HandleStartCountdown(StringHash eventType, VariantMap& eventData);

    void HandlePlayerID(StringHash eventType, VariantMap& eventData);

    void HandleFinishCrossing(StringHash eventType, VariantMap& eventData);

    void HandleShowFinalScore(StringHash eventType, VariantMap& eventData);

    void HandlePointChange(StringHash eventType, VariantMap& eventData);

	/**
	 * Register object factory and attributes.
	 */
	static void RegisterObject(Context* context);

	void updateScoreBoard(StringHash eventType, VariantMap& eventData);

	void toggleScore(bool val);
	void toggleScore();

	URHO3D_OBJECT(Gui, Urho3D::Component);
};

