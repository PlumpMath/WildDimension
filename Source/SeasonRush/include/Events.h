#pragma once

/**
 * Player movement
 */
const int PLAYER_FORWARD = 1; //W
const int PLAYER_BACK = 2; //S
const int PLAYER_LEFT = 4; //A
const int PLAYER_RIGHT = 8; //D
const int PLAYER_SPRINT = 16; // LSHIFT
const int PLAYER_USE = 32; //E
const int PLAYER_CAMERA = 64; //V
const int PLAYER_RESET = 128; //R
const int PLAYER_JUMP = 256; //SPACE

/**
 *
 */
const int MESSAGE_INTRODUCTION = 32;

/**
 * Ping messages
 */
const int MESSAGE_PING_REQUEST = 33;
const int MESSAGE_PING_RESPONSE = 34;

/**
 * Main game events
 */
static const StringHash E_GAME_EXIT("GameExit");
static const StringHash E_GAME_NEW("GameNew");
static const StringHash E_GAME_JOIN("GameJoin");
static const StringHash E_GAME_STOP("GameStop");

/**
 * Start game start countdown timer
 */
static const StringHash E_GAME_COUNTDOWN_START("GameCountdownStart");

/**
 * Start the game when countdown timer reaches 0
 */
static const StringHash E_GAME_COUNTDOWN_FINISHED("GameCountdownFinished");

/**
 * Player information update events
 */
static const StringHash E_CATCHER_INFO("ServerCatcherInfo");
static const StringHash E_SERVER_INTRODUCTION("PlayerIntroduction");
static const StringHash E_CLIENT_ID("ServerClientId");
static const StringHash E_CLIENT_NODE_CHANGED("ServerClientNodeChanged");
static const StringHash E_TOGGLE_SCORE("ShowHidePlayerScore");
static const StringHash E_UPDATE_SCORE("UpdatePlayerScore");

/**
 * Player information values
 */
static const StringHash P_PLAYER_NAME("ServerPlayerName");
static const StringHash P_PLAYER_HEALTH("ServerPlayerHealth");
static const StringHash P_PLAYER_POINTS("ServerPlayerPoints");
static const StringHash P_PLAYER_TYPE("ServerPlayerType");
static const StringHash P_PLAYER_ID("ServerPlayerID");
static const StringHash P_DRIVEABLE_ID("DriveableId");
static const StringHash P_PLAYER_NODE_ID("ServerPlayerNodeID");
static const StringHash P_PLAYER_NODE_PTR("ServerPlayerNodePtr");
static const StringHash P_PLAYER_LIST("ServerPlayerID");
static const StringHash P_PLAYER_PING("ServerPlayerPing");
static const StringHash P_PLAYER_INCAR("ServerPlayerInCar");
static const StringHash P_PLAYER_INCAR_ID("ServerPlayerInCarId");
static const StringHash P_RACE_TIME("PRaceTime");
static const StringHash P_CHECKPOINT_COUNT("CheckpointCount");

const int USABLE_TYPE_SLED = 0;
const int USABLE_TYPE_VEHICLE = 1;

/**
 * Server specific values
 */
static const StringHash P_SERVER_ADDRESS("ServerAddress");
static const StringHash P_SERVER_PORT("ServerPort");
static const StringHash P_SERVER_LAN("ServerLan");
static const StringHash P_SERVER_HEADLESS("ServerHeadless");

/**
 * API response events
 */
static const StringHash E_HTTP_RESPONSE("HTMLResponse");

/**
 * API response values
 */

static const StringHash P_REQUEST_TYPE("RequestType");
static const StringHash P_REQUEST_VALUE("RequestValue");

/**
 * Api news endpoint response events and values
 */
static const StringHash E_SERVER_NEWS("ServerNews");
static const StringHash P_NEWS_TITLE("NewsTitle");
static const StringHash P_NEWS_CONTENT("NewsContent");
static const StringHash P_NEWS_DATE("NewsDate");
static const StringHash P_NEWS_IMPORTANCE("NewsImportance");
static const StringHash P_NEWS_INDEX("NewsIndex");

/**
 * Debug level change event and value
 */
static const StringHash E_DEBUG_TOGGLE("DebugToggle");
static const StringHash P_DEBUG_LEVEL("DebugLevel");

/**
 * GUI Events
 */
static const StringHash E_UPDATE_GUI("UpdatePlayerGUI");
static const StringHash E_PLAYER_POINTS_CHANGED("PlayerPointsChanged");
static const StringHash E_GUI_POINTS_CHANGED("GuiPointsChanged");

/**
 * Screen events
 */
static const StringHash E_SPLASHSCREEN_END("SplashscreenEnd");

/**
 * Physics settings changed
 */
static const StringHash E_PHYSICS_STEP_CHANGED("PhysicsStepChanged");
static const StringHash E_PHYSICS_SUBSTEP_CHANGED("PhysicsSubStepChanged");
static const StringHash E_DRAW_PHYSICS("PhysicsDrawDebug");
static const StringHash E_PHYSICS_GRAVITY("PhysicsGravity");
static const StringHash P_VALUE("Value");

static const StringHash P_POSITION("PositionVector");
static const StringHash P_DIRECTION("DirectionVector");
static const StringHash P_READY("Ready");
static const StringHash P_COUNT("Count");

static const StringHash E_ADD_SLED("AddSled");
static const StringHash E_ADD_VEHICLE("AddVehicle");
static const StringHash E_EXIT_DRIVEABLES("ExitDriveables");
static const StringHash E_REMOVE_DRIVEABLES("RemoveDriveables");
static const StringHash E_SLED_SPEED("ESledSpeed");
static const StringHash E_VEHICLE_SPEED("EVehicleSpeed");

static const StringHash E_AI_START_FROM_FIRST_CHECKPOINT("AIStartFromFirstCheckpoint");
static const StringHash E_AI_ARRIVE_RADIUS("AIArriveRadius");
static const StringHash E_AI_STEER_ANGLE("AISteerAngle");
static const StringHash E_AI_DRIFT_MIN_ANGLE("AIDriftMinAngle");
static const StringHash E_AI_DRIFT_MAX_ANGLE("AIDriftMaxAngle");
static const StringHash E_AI_DRIFT_MIN_SPEED("AIDriftMinSpeed");
static const StringHash E_AI_RESET_TIME("AIResetTime");
static const StringHash E_AI_SET_TARGET_NODE("AISetTargetNode");
static const StringHash E_AI_REMOVE_TARGET_NODE("AIRemoveTargetNode");

static const StringHash E_AI_TOGGLE_TREE_COLLISION("AIToggleTreeCollision");

static const StringHash E_GRAPHICS_CHANGED("EGraphicsChanged");

/**
 * Checkpoint picker events and parameters
 */
static const StringHash P_CP_ID("PCpID");
static const StringHash P_CP_POINTS("PCpPoints");
static const StringHash P_TIME("PTime");
static const StringHash P_PLAYER_POSITION("PPlayerPosition");
static const StringHash P_INDEX("PIndex");
static const StringHash E_CP_POINTS_CHANGED("ECPPointsChanged");

static const StringHash E_SET_PLAYER_ID("SetPlayerID");

static const StringHash E_PREDICT_NODE_POSITION("PredictNodePosition");
static const StringHash P_NODE_ID("NodeID");
static const StringHash P_VEHICLE_TYPE("PVehicleType");
static const StringHash P_CHECKPOINT_ID("PCheckpointID");

static const StringHash P_GAME_SETTINGS_START_VEHICLE("GameSettingsStartVehicle");
static const StringHash P_GAME_SETTINGS_CAR_COUNT("GameSettingsCarCount");
static const StringHash P_GAME_SETTINGS_SLED_COUNT("GameSettingsSledCount");
static const StringHash P_GAME_SETTINGS_AI_FOLLOW("GameSettingsAIFollow");

static const StringHash E_LAST_CHECKPOINT_REACHED("LastCheckpointReached");

static const StringHash E_SHOW_FINAL_SCORE("ShowFinalScore");
static const StringHash E_END_CAMERA("EndCamera");

static const StringHash E_CHECKPOINT_REACHED("CheckpointReached");

static const StringHash E_SUBMIT_SCORE("SubmitScore");
static const StringHash E_LOAD_LEADERBOARD("LoadLeaderboard");
static const StringHash E_ADD_LEADERBOARD_ITEM("AddLeaderboardItem");

static const StringHash E_BROADCAST_STEER("BroadcastSteer");

static const StringHash E_BROADCAST_NEW_VERSION("BroadcastNewVersion");