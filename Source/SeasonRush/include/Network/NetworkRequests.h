#pragma once

#include <Urho3D/Urho3DAll.h>
#include <map>
#include <list>

using namespace Urho3D;

namespace Synchronization {

	enum RequestType {
		//Obtain available server list
		NEW_GAME_SESSION,
		SERVER_LIST,
		LATEST_VERSION,
		NEWS,
		NEW_SERVER,
        SUBMIT_SCORE,
        LEADERBOARD
	};

	struct RequestInfo {
        bool started;
		SharedPtr<HttpRequest> network; //Network object
		RequestType type; //Request type
		String url;
		std::map<String, String> getVariables;
		std::map<String, String> postVariables;
		void addGetVariable(String name, String value) {
            getVariables[name] = value;
		}
		void addPostVariable(String name, String value) {
            postVariables[name] = value;
		}
	};

	class NetworkRequests : public Urho3D::Object
	{

	private:
		std::list<RequestInfo> _requests;

		/**
		 * Map specific task to an url
		 */
		std::map < RequestType, String > _urls;
		/**
		 * Make the actual request via Urho3D network subsystem
		 */
		SharedPtr<HttpRequest> makeRequest(String url, String postData);

		/**
		 * Response buffer
		 */
		String _buffer;

		/**
		 * Get version information out of json string
		 */
		void parseVersion(String val);

		/**
		* Get news out of json string
		*/
		void parseNews(String val);

        /**
         * Get leaderboard results
         */
        void parseLeaderboard(String val);
	public:
		NetworkRequests(Context* context);
		~NetworkRequests();

		/**
		 * Make new request
		 */
		RequestInfo* addNewRequest(RequestType type);
        RequestInfo* addNewRequest(RequestType type, RequestInfo info);

		/// Register object factory and attributes.
		static void RegisterObject(Context* context);

		void HandleUpdate(StringHash eventType, VariantMap& eventData);

		URHO3D_OBJECT(NetworkRequests, Urho3D::Object);
	};
}
