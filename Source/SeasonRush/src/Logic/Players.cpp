#include <Urho3D/Urho3DAll.h>
#include "Logic/Players.h"
#include "Events.h"
#include "Logic/Gui.h"

using namespace Urho3D;

Players::Players(Context* context) :
Urho3D::LogicComponent(context),
_guiUpdateCooldown(0.0f)
{
    SetUpdateEventMask( USE_FIXEDUPDATE | USE_POSTUPDATE );
    SubscribeToEvent(E_EXIT_DRIVEABLES, URHO3D_HANDLER(Players, HandleDriveableClear));
}


Players::~Players()
{
}


void Players::RegisterObject(Context* context)
{
	context->RegisterFactory<Players>();
	OnePlayer::RegisterObject(context);
}

void Players::setScene(SharedPtr<Scene> scene)
{
	_scene = scene;
}

void Players::setTerrain(Terrain** terrain)
{
	_terrain = terrain;
}

OnePlayer* Players::createPlayer(bool localPlayer, int playerId)
{	
	Node* playerNode;

	if (localPlayer) {
		playerNode = createPlayerControlledNode(_scene, *_terrain);
		OnePlayer *player = playerNode->CreateComponent<OnePlayer>();
		player->setServerPlayer(localPlayer);
		player->setUsables(GetScene()->GetComponent<Usables>());
		player->setControlledNode(playerNode);
		player->setCameraNode(player->getControlledNode());
		player->togglePhysics(true);
		_playerList.push_back(player);
		return player;
	}
	else {
		playerNode = _scene->GetNode(playerId);
		OnePlayer* player = playerNode->GetComponent<OnePlayer>();
		player->setControlledNode(_scene->GetNode(playerId));
		player->setCameraNode(player->getCameraNode());
		_playerList.push_back(player);
		return player;
	}

	return nullptr;
}

Node* Players::createPlayerControlledNode(Scene* scene, Terrain* terrain)
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();

	Node* node;
	//Create new node to the player
	node = scene->CreateChild("PlayerNode");

	StaticModel* model = node->CreateComponent<StaticModel>();
	model->SetCastShadows(false);
	//What static model will be used for this node
	model->SetModel(cache->GetResource<Model>("Models/Sphere.mdl"));
	model->SetMaterial(cache->GetResource<Material>("Materials/Colors/Green.xml"));

	//Don't allow this node to fall trough ground - check terrain height in specific point
	Vector3 position(20, 0, 10);
	position.y_ = terrain->GetHeight(position) + 2;
	node->SetPosition(position);
	
	return node;
}

void Players::removePlayer(unsigned short id)
{
	for (auto it = _playerList.begin(); it != _playerList.end(); ++it) {
		if ((*it)->GetID() == id) {
			OnePlayer* player = (*it);
			player->destroy();
			//delete player;
			player->getControlledNode()->Remove();
			_playerList.erase(it);
			return;
		}
	}
}

OnePlayer* Players::getPlayerByNode(Node* node)
{
	for (auto it = _playerList.begin(); it != _playerList.end(); ++it) {
		if ((*it)->getControlledNode() == node) {
			return (*it);
		}
	}

	return nullptr;
}

OnePlayer* Players::getPlayerById(unsigned short id)
{
	for (auto it = _playerList.begin(); it != _playerList.end(); ++it) {
		if ((*it)->GetID() == id) {
			return (*it);
		}
	}

	return nullptr;
}

OnePlayer* Players::getRandomPlayer()
{
	int randomNumber = Random(0, _playerList.size());
	int i = 0;
	for (auto it = _playerList.begin(); it != _playerList.end(); ++it) {
		if (i == randomNumber) {
			return (*it);
		}
		i++;
	}

	return nullptr;
}

void Players::FixedUpdate(float timeStep)
{
	for (auto it = _playerList.begin(); it != _playerList.end(); ++it) {
		(*it)->FixedUpdate(timeStep);
	}
}

void Players::PostUpdate(float timeStep)
{
	for (auto it = _playerList.begin(); it != _playerList.end(); ++it) {
		(*it)->PostUpdate(timeStep);
	}
}

void Players::cleanup()
{
	for (auto it = _playerList.begin(); it != _playerList.end(); ++it) {
		(*it)->getControlledNode()->Remove();
	}
	_playerList.clear();
}

void Players::HandleDriveableClear(StringHash eventType, VariantMap& eventData)
{
    for (auto it = _playerList.begin(); it != _playerList.end(); ++it) {
        (*it)->exitDriveableObject();
    }
}