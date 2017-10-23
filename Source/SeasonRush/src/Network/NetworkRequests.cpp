#include "Urho3D/Urho3DAll.h"
#include "Network/NetworkRequests.h"
#include "JSONParse.h"
#include "Config/Config.h"
#include "Events.h"

using namespace Synchronization;

NetworkRequests::NetworkRequests(Context* context) :
Urho3D::Object(context)
{
	String serverUrl = Config::instance().getConfig().webUrl.c_str();
	String apiUrl = Config::instance().getConfig().apiUrl.c_str();

	_urls[LATEST_VERSION] = apiUrl + "info";
	_urls[SERVER_LIST] = apiUrl + "servers";
	_urls[NEWS] = apiUrl + "news";
	_urls[NEW_SERVER] = apiUrl + "servers/update";
	_urls[NEW_GAME_SESSION] = apiUrl + "session/new";
    _urls[SUBMIT_SCORE] = apiUrl + "leaderboard";
    _urls[LEADERBOARD] = apiUrl + "leaderboard";
}


NetworkRequests::~NetworkRequests()
{
}


void NetworkRequests::RegisterObject(Context* context)
{
	context->RegisterFactory<NetworkRequests>();
}

RequestInfo* NetworkRequests::addNewRequest(RequestType type)
{
    return addNewRequest(type, RequestInfo());
}

RequestInfo* NetworkRequests::addNewRequest(RequestType type, RequestInfo info)
{
	for (auto it = _requests.begin(); it != _requests.end(); ++it) {
		if ((*it).type == type) {

			//WE already have this kind of request in the list
			return nullptr;
		}
	}

	//Create new request
	//info.network = makeRequest(_urls[type]);
	info.started = false;
	info.type = type;
	info.url = _urls[type];
	_requests.push_back(info);
    URHO3D_LOGDEBUG("New network request registered for:" + info.url);
	SubscribeToEvent(E_UPDATE, URHO3D_HANDLER(NetworkRequests, HandleUpdate));

	return &_requests.back();
}

SharedPtr<HttpRequest> NetworkRequests::makeRequest(String url, String postData)
{
    //URHO3D_LOGINFOF("Making request to %s, post data: %s", url.CString(), postData.CString());
    Vector<String> headers;
    String requestType = "GET";
    if (postData.Length() > 0) {
        headers.Push("Content-Type:application/x-www-form-urlencoded");
        requestType = "POST";
    }
	return GetSubsystem<Network>()->MakeHttpRequest(url, requestType, headers, postData);
}

void NetworkRequests::HandleUpdate(StringHash eventType, VariantMap& eventData)
{
	//Check if we have unprocessed requests
	if (!_requests.empty()) {

		for (auto it = _requests.begin(); it != _requests.end(); ++it) {
            if (!(*it).started) {
                int getValueCount = 0;
                for (auto get = (*it).getVariables.begin(); get != (*it).getVariables.end(); ++get) {
                    if (getValueCount == 0) {
                        (*it).url += "?";
                    } else {
                        (*it).url += "&";
                    }
                    (*it).url += (*get).first + "=" + (*get).second;
                    getValueCount++;
                }

                String postData = String::EMPTY;
                int postValueCount = 0;
                for (auto post = (*it).postVariables.begin(); post != (*it).postVariables.end(); ++post) {
                    if (postValueCount > 0) {
                        postData += "&";
                    }
                    postData += (*post).first + "=" + (*post).second;
                    postValueCount++;
                }

                (*it).network = makeRequest((*it).url, postData);
                (*it).started = true;
                continue;
            }

			//Check if we received the response from the server
			if ((*it).network->GetAvailableSize() > 0) {

				//Prepare our response buffer for data receiving
				_buffer.Resize((*it).network->GetAvailableSize());

				//Read the buffer data into the string
				(*it).network->Read((void*)_buffer.CString(), (*it).network->GetAvailableSize());

				//URHO3D_LOGINFOF("Request to %s made, response :%s", (*it).url.CString(), _buffer.CString());

				switch ((*it).type) {
				case LATEST_VERSION:
					parseVersion(_buffer);
					break;
				case SERVER_LIST:
					break;
				case NEWS:
					parseNews(_buffer);
					break;
                case LEADERBOARD:
                    parseLeaderboard(_buffer);
                    break;
				}

				//We should remove this request from the unprocessed request list
				it = _requests.erase(it);
			}
		}
	}
	else {
		UnsubscribeFromEvent(E_UPDATE);
	}
}

void NetworkRequests::parseVersion(String val)
{
	rapidjson::Document json;

	//#if _WIN32
	//For some reason this doesnt work on linux
	const char* data = val.CString();
	json.Parse<rapidjson::ParseFlag::kParseDefaultFlags>(data);
	//#endif // _WIN32

	if (json.IsObject()) {
		if (json.HasMember("data") && json["data"].IsObject()) {
			if (json["data"].HasMember("versions") && json["data"]["versions"].IsObject()) {
				if (json["data"]["versions"].HasMember("Win32")) {
					VariantMap response;
					response[P_REQUEST_TYPE] = RequestType::LATEST_VERSION;
					response[P_REQUEST_VALUE] = json["data"]["versions"]["Win32"].GetString();
					SendEvent(E_HTTP_RESPONSE, response);
				}
			}
		}
	}
}


void NetworkRequests::parseNews(String val)
{
	rapidjson::Document json;

	//#if _WIN32
	//For some reason this doesnt work on linux
	const char* data = val.CString();
	json.Parse<rapidjson::ParseFlag::kParseDefaultFlags>(data);
	//#endif // _WIN32

	int index = 0;
	if (json.IsArray()) {
		for (auto it = json.Begin(); it != json.End(); ++it) {
			if ((*it).IsObject()) {
				if ((*it).HasMember("title") &&
					(*it).HasMember("content") &&
					(*it).HasMember("published_at") &&
					(*it).HasMember("importance")) {
					using namespace std;
					String title = (*it)["title"].GetString();
					String content = (*it)["content"].GetString();
					String published_at = (*it)["published_at"].GetString();
					String importance = (*it)["importance"].GetString();
					VariantMap map;
					map[P_NEWS_TITLE] = title;
					map[P_NEWS_CONTENT] = content;
					map[P_NEWS_DATE] = published_at;
					map[P_NEWS_IMPORTANCE] = importance;
					map[P_NEWS_INDEX] = index;
					SendEvent(E_SERVER_NEWS, map);
					index++;
				}
			}
		}
	}
}

void NetworkRequests::parseLeaderboard(String val)
{
    rapidjson::Document json;

    //#if _WIN32
    //For some reason this doesnt work on linux
    const char* data = val.CString();
    json.Parse<rapidjson::ParseFlag::kParseDefaultFlags>(data);
    //#endif // _WIN32

    int index = 0;
    if (json.IsObject()) {
        if (json.HasMember("data")) {
            for (auto it = json["data"].Begin(); it != json["data"].End(); ++it) {
                if ((*it).IsObject()) {
                    if ((*it).HasMember("nickname") &&
                        (*it).HasMember("racetime") &&
                        (*it).HasMember("checkpoints")) {
                        using namespace std;
                        String nickname = (*it)["nickname"].GetString();
                        int racetime = (*it)["racetime"].GetInt();
                        int checkpoints = (*it)["checkpoints"].GetInt();
                        URHO3D_LOGINFOF("Nickname: %s; Racetime: %i; Checkpoints: %i", nickname.CString(), racetime, checkpoints);
                        VariantMap map;
                        map[P_PLAYER_NAME] = nickname;
                        map[P_RACE_TIME] = racetime;
                        map[P_CHECKPOINT_COUNT] = checkpoints;
                        map[P_INDEX] = index;
                        SendEvent(E_ADD_LEADERBOARD_ITEM, map);
                        index++;
                    }
                }
            }
        }
    }
}
