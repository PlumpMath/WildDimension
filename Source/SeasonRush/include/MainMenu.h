#pragma once
#include <Urho3D/Urho3DAll.h>
#include <list>
#include <map>

using namespace Urho3D;

struct StartGameOptions {
    StartGameOptions() :
        cars(0),
        sleds(0),
        aiChasing(false),
        startVehicle(0)
    {}
    int cars;
    int sleds;
    bool aiChasing;
    int startVehicle;
};

struct LeaderboardItem {
    SharedPtr<Text> nickname;
    SharedPtr<Text> checkpoints;
    SharedPtr<Text> racetime;
};

class MainMenu : public Urho3D::Component
{
private:
	SharedPtr<UIElement> _settingsView;
	SharedPtr<DropDownList> _resolutionDropdown;
	SharedPtr<CheckBox> _fullscreenCheckbox;

	SharedPtr<UIElement> _settingsButton;
	SharedPtr<UIElement> _exitButton;
	SharedPtr<UIElement> _newButton;
    SharedPtr<UIElement> _achievmentsButton;
    SharedPtr<UIElement> _leaderboardButton;

    SharedPtr<UIElement> _leaderboard;
    Vector<LeaderboardItem> _leaderboardList;

    SharedPtr<UIElement> _nicknameBox;
    SharedPtr<LineEdit> _nicknameInputField;

	std::list< SharedPtr< HttpRequest > > responses;
	String dest;

	String resolutionChoice;

    SharedPtr<UIElement> _gameSettings;

    StartGameOptions _startGameOptions;

	/**
	 * How many news posts are there
	 */
	int _newsPosts;

    String getTimeFormat(int t);
public:
	MainMenu(Context* context);
	~MainMenu();

	/// Register object factory and attributes.
	static void RegisterObject(Context* context);

	void exitGame(StringHash eventType, VariantMap& eventData);
	void startGame(StringHash eventType, VariantMap& eventData);

    void changeCarCount(StringHash eventType, VariantMap& eventData);
    void changeSledCount(StringHash eventType, VariantMap& eventData);
    void setStartVehicle(StringHash eventType, VariantMap& eventData);
    void setAIFollow(StringHash eventType, VariantMap& eventData);

    void createNewGameWindow();
    void closeNewGameWindow();

    void createNicknameBox();
    void closeNicknameBox();
    void HandleInputSelected(StringHash eventType, VariantMap& eventData);
    void HandleNicknameChanged(StringHash eventType, VariantMap& eventData);

	/**
	 * Settings view related events
	 */
	void showSettings(StringHash eventType, VariantMap& eventData);
	void HandleResolutionChange(StringHash eventType, VariantMap& eventData);
	void HandleFullscreenChange(StringHash eventType, VariantMap& eventData);
	void saveSettings(StringHash eventType, VariantMap& eventData);
	void closeSettings(StringHash eventType, VariantMap& eventData);

    void createLeaderboard();
    void closeLeaderboard();
    void HandleCreateLeaderboard(StringHash eventType, VariantMap& eventData);
    void HandleCloseLeaderboard(StringHash eventType, VariantMap& eventData);

    void HandleAddLeaderboardItem(StringHash eventType, VariantMap& eventData);

	void draw();

	void show(bool val);

	/**
	* When any news are received
	*/
	void HandleNewsReceived(StringHash eventType, VariantMap& eventData);

	URHO3D_OBJECT(MainMenu, Urho3D::Component);
};

