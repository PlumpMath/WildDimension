#include <Urho3D/Urho3DAll.h>
#include "Logic/Usables.h"
#include "Events.h"
#include "JSONParse.h"
#include <string>
#include <fstream>
#include <iostream>
#include "Logic/Vehicles/Offroad/DriverAI.h"

using namespace std;
using namespace Urho3D;

Usables::Usables(Context* context) :
Urho3D::Component(context),
_lastFinishedPosition(1)
{
	SubscribeToEvent(E_POSTUPDATE, URHO3D_HANDLER(Usables, HandlePostUpdate));
	SubscribeToEvent(E_GAME_COUNTDOWN_FINISHED, URHO3D_HANDLER(Usables, HandleCountDownFinished));

    SubscribeToEvent(E_ADD_SLED, URHO3D_HANDLER(Usables, HandleDriveableEvents));
    SubscribeToEvent(E_ADD_VEHICLE, URHO3D_HANDLER(Usables, HandleDriveableEvents));

    SubscribeToEvent(E_REMOVE_DRIVEABLES, URHO3D_HANDLER(Usables, HandleDriveableClear));
}


Usables::~Usables()
{
}


void Usables::RegisterObject(Context* context)
{
	context->RegisterFactory<Usables>();
}

void Usables::setScene(Scene* scene)
{
    _scene = scene;
}

void Usables::setTerrain(Terrain* terrain)
{
	_terrain = terrain;
}

Scene* Usables::getActiveScene()
{
    return _scene;
}

NewVehicle* Usables::createVehicle(Vector3 position, Vector3 direction, bool ready)
{
    //Create nev vehicle node
    Node* vehicleNode = _scene->CreateChild("VehicleNode");
    //Init controllable object
	NewVehicle* vehicle = vehicleNode->CreateComponent<NewVehicle>(LOCAL);
	vehicle->Init();
	vehicle->setReady(ready);
	vehicle->setVehicleID(_vehicles.Size());

	DriverAI *ai = vehicleNode->CreateComponent<DriverAI>();
	if (!_trackPath.Empty()) {
		ai->setTrackPath(_trackPath);
	}

    vehicleNode->SetRotation(Quaternion());
    vehicleNode->SetDirection(direction);

    vehicleNode->SetPosition(position);

    CheckpointPicker* cp = dynamic_cast<CheckpointPicker*>(vehicle);
    cp->setCpId(_checkpointPickers.Size());

    _vehicles.Push(SharedPtr<NewVehicle>(vehicle));
    _driveables.Push(vehicle);
    _checkpointPickers.Push(vehicle);
    _powerupPickers.Push(vehicle);

    return vehicle;
}

Sled* Usables::createSled(Vector3 position, Vector3 direction, bool ready)
{
	//Create nev vehicle node
	Node* vehicleNode = _scene->CreateChild("VehicleNode");
	//Init controllable object
	Sled* vehicle = vehicleNode->CreateComponent<Sled>(LOCAL);
	vehicle->Init();
	vehicle->setReady(ready);

	DriverAI *ai = vehicleNode->CreateComponent<DriverAI>();
	if (!_trackPath.Empty()) {
		ai->setTrackPath(_trackPath);
	}

    vehicleNode->SetRotation(Quaternion());
    vehicleNode->SetDirection(direction);

	vehicle->SetSledID(_sleds.Size());
	vehicleNode->SetPosition(position);
	vehicleNode->SetDirection(Vector3::LEFT);

    CheckpointPicker* cp = dynamic_cast<CheckpointPicker*>(vehicle);
    cp->setCpId(_checkpointPickers.Size());

	_sleds.Push(SharedPtr<Sled>(vehicle));
    _driveables.Push(vehicle);
    _checkpointPickers.Push(vehicle);
    _powerupPickers.Push(vehicle);

	return vehicle;
}

Checkpoint* Usables::createCheckpoint(Node* node, Vector3 position, bool last)
{
    bool alreadyExists = true;
    if (node == nullptr) {
        alreadyExists = false;
        node = _scene->CreateChild("Checkpoint_" + String(_checkpoints.Size()));
    }
	Checkpoint* checkpoint = node->CreateComponent<Checkpoint>();
    if (!alreadyExists) {
        checkpoint->create(position);
    }
    checkpoint->setId(_checkpoints.Size());
    //if (last) {
        checkpoint->initFireworks();
    //}
    checkpoint->setPosition(position);
    checkpoint->setLast(last);
	_checkpoints.Push(SharedPtr<Checkpoint>(checkpoint));
	return checkpoint;
}

PowerUp* Usables::createPowerUp(Vector3 position)
{
	Node* node = _scene->CreateChild("PowerUp_" + String(_powerups.Size()));
	node->SetPosition(position);
	PowerUp* powerup = node->CreateComponent<PowerUp>();
	powerup->Init(POWERUP_TYPE_SPEED);
	_powerups.Push(SharedPtr<PowerUp>(powerup));
	return powerup;
}

void Usables::HandlePostUpdate(StringHash eventType, VariantMap& eventData)
{
	const float timeStep = eventData[PostUpdate::P_TIMESTEP].GetFloat();
	for (auto it = _checkpointPickers.Begin(); it != _checkpointPickers.End(); ++it) {
		for (auto it2 = _checkpoints.Begin(); it2 != _checkpoints.End(); ++it2) {
			CheckpointPicker* cp = (*it);
			Checkpoint* checkpoint = (*it2);
			if (cp->haveReached(checkpoint->getId())) {
				continue;
			}
			
			Node* cpNode = cp->getComponent()->GetNode();
			
			Vector3 cpPosition = cpNode->GetPosition();
			Vector3 checkpointPosition = checkpoint->getPosition();

			Vector3 dist = cpPosition - checkpointPosition;
			if (dist.LengthSquared() < 10) {
                ResourceCache* cache = GetSubsystem<ResourceCache>();
                Sound* sound = cache->GetResource<Sound>("Sounds/checkpoint.wav");
                Node* soundNode = cpNode->CreateChild("CheckpointSound");
                SoundSource3D* soundSource = soundNode->CreateComponent<SoundSource3D>();
                soundSource->SetDistanceAttenuation(1.0f, 100.0f, 4.0f);
                soundSource->Play(sound);
                soundSource->SetFrequency(sound->GetFrequency());
                soundSource->SetGain(0.2f);
                soundSource->SetAutoRemoveMode(REMOVE_NODE);

                checkpoint->startFireworks();
				cp->checkpointReached(checkpoint->getId());

                unsigned int type = 0;
                if (cp->getComponent()->GetNode()->HasComponent<NewVehicle>()) {
                    type = 1;
                }
                else if (cp->getComponent()->GetNode()->HasComponent<Sled>()) {
                    type = 0;
                }

                VariantMap map;
                map[P_CP_ID] = cp->getCpId();
                map[P_PLAYER_POSITION] = _lastFinishedPosition;
                map[P_VEHICLE_TYPE] = type;
                map[P_CHECKPOINT_ID] = checkpoint->getId();
                map[P_PLAYER_POINTS] = cp->reachedCheckpointCount();
                SendEvent(E_CHECKPOINT_REACHED, map);
			}
            if (checkpoint->isLast() && dist.LengthSquared() < 300) {
                cp->checkpointReached(checkpoint->getId());

                unsigned int type = 0;
                if (cp->getComponent()->GetNode()->HasComponent<NewVehicle>()) {
                    type = 1;
                }
                else if (cp->getComponent()->GetNode()->HasComponent<Sled>()) {
                    type = 0;
                }

                VariantMap map;
                map[P_CP_ID] = cp->getCpId();
                map[P_PLAYER_POSITION] = _lastFinishedPosition;
                map[P_VEHICLE_TYPE] = type;
                map[P_CHECKPOINT_ID] = checkpoint->getId();
                map[P_PLAYER_POINTS] = cp->reachedCheckpointCount();
                SendEvent(E_LAST_CHECKPOINT_REACHED, map);
                _lastFinishedPosition++;
                URHO3D_LOGINFOF("Last checkpoint reached CP_ID: %u", cp->getCpId());
            }
		}
	}

	for (auto it = _powerupPickers.Begin(); it != _powerupPickers.End(); ++it) {
		for (auto it2 = _powerups.Begin(); it2 != _powerups.End(); ++it2) {
			PowerUp* powerup = (*it2);
			Node* powerupNode = powerup->GetNode();
			if (!powerupNode->IsEnabled()) {
				continue;
			}

			PowerupPicker* pup = (*it);

			Node* pupNode = pup->getNode();

			Vector3 pupPosition = pupNode->GetPosition();
			Vector3 checkpointPosition = powerupNode->GetPosition();

			Vector3 dist = pupPosition - checkpointPosition;
			if (dist.LengthSquared() < 10) {
                pup->pickUpPowerup(powerup);
			}
		}
	}
}

void Usables::destroyAllVehicles()
{
	for (auto it = _vehicles.Begin(); it != _vehicles.End(); ++it) {
		(*it)->GetNode()->Remove();
	}
	_vehicles.Clear();
}

void Usables::destroyAllSleds()
{
	for (auto it = _sleds.Begin(); it != _sleds.End(); ++it) {
		(*it)->GetNode()->Remove();
	}
	_sleds.Clear();
}

NewVehicle* Usables::getNearestVehicle(Vector3 position)
{
	NewVehicle* vehicle = (*_vehicles.Begin());

	float smallest = -1;
    for (auto it = _vehicles.Begin(); it != _vehicles.End(); ++it) {
		if ((*it)->getBusy()) {
			continue;
		}

        float distance = ((*it)->GetNode()->GetPosition() - position).LengthSquared();
        if (distance < smallest || smallest == -1) {
			vehicle = (*it);
			smallest = distance;
        }
    }

    return vehicle;
}

Sled* Usables::getNearestSled(Vector3 position)
{
	Sled* sled = nullptr;
	float smallest = -1;
	for (auto it = _sleds.Begin(); it != _sleds.End(); ++it) {
		if ((*it)->getBusy()) {
			continue;
		}

		float distance = ((*it)->GetNode()->GetPosition() - position).LengthSquared();
		if (distance < smallest || smallest < 0) {
			sled = (*it);
			smallest = distance;
		}
	}

	return sled;
}

DriveableObject* Usables::getNearestDriveableObject(Vector3 position)
{
    DriveableObject* obj = nullptr;
    unsigned int smallest = -1;
    for (auto it = _driveables.Begin(); it != _driveables.End(); ++it) {
        if ((*it)->getBusy()) {
            continue;
        }

        unsigned int distance = ((*it)->getNode()->GetPosition() - position).LengthSquared();
        if (distance < smallest || smallest < 0) {
            obj = (*it);
            smallest = distance;
        }
    }

    return obj;
}

void Usables::FixedUpdate(float timeStep)
{

}

void Usables::PostUpdate(float timeStep)
{
}

void Usables::setTrackPath(Vector<Vector3> trackPath)
{
	_trackPath = trackPath;
}

void Usables::HandleCountDownFinished(StringHash eventType, VariantMap& eventData)
{
	URHO3D_LOGINFO("Countdown finished, enabling vehicles and sleds");
	for (auto it = _sleds.Begin(); it != _sleds.End(); ++it) {
		(*it)->setReady(true);
	}

	for (auto it = _vehicles.Begin(); it != _vehicles.End(); ++it) {
		(*it)->setReady(true);
	}
}

void Usables::HandleDriveableEvents(StringHash eventType, VariantMap& eventData)
{
    Vector3 startPosition = Vector3::ZERO;
    Vector3 direction = Vector3::FORWARD;
    int count = 1;
    bool ready = false;

    if (eventData.Contains(P_DIRECTION)) {
        direction = eventData[P_DIRECTION].GetVector3();
    }

    if (eventData.Contains(P_POSITION)) {
        startPosition = eventData[P_POSITION].GetVector3();
    }
    else {
        Node* startNode = _scene->GetChild("startNode", true);
        if (startNode) {
            startPosition = startNode->GetWorldPosition();
        }
    }

    if (eventData.Contains(P_READY)) {
        ready = eventData[P_READY].GetBool();
    }

    if (eventData.Contains(P_COUNT)) {
        count = eventData[P_COUNT].GetInt();
    }

    direction.y_ = 0;

    if (eventType == E_ADD_SLED) {
        for (int i = 0; i < count; i++) {
            startPosition.x_ += 10.0f;
            //startPosition.z_ += 3;
            startPosition.y_ = _terrain->GetHeight(startPosition);
            startPosition = _terrain->GetNode()->GetRotation() * startPosition;
            startPosition.y_ += 1.0f;
            //URHO3D_LOGINFOF("Adding sled (%f, %f, %f)", startPosition.x_, startPosition.y_, startPosition.z_);
            createSled(startPosition, direction, ready);
        }
    }
    else if (eventType == E_ADD_VEHICLE) {
        for (int i = 0; i < count; i++) {
            startPosition.x_ += 10.0f;
            //startPosition.z_ += 3;
            startPosition.y_ = _terrain->GetHeight(startPosition) + 1.5f;
            startPosition = _terrain->GetNode()->GetRotation() * startPosition;
            //startPosition.z_ += 5.0f;
            //URHO3D_LOGINFOF("Adding vehicle (%f, %f, %f)", startPosition.x_, startPosition.y_, startPosition.z_);
            createVehicle(startPosition, direction, ready);
        }
    }

    sendOutPredictedNodes();
}

void Usables::HandleDriveableClear(StringHash eventType, VariantMap& eventData)
{
    //To succesfully remove vehicles all players should exit from them
    SendEvent(E_EXIT_DRIVEABLES);
    destroyAllSleds();
    destroyAllVehicles();
    regroupDriveables();
}

void Usables::regroupDriveables()
{
    _driveables.Clear();
    _checkpointPickers.Clear();
    _powerupPickers.Clear();

    for (auto it = _sleds.Begin(); it != _sleds.End(); ++it) {
        _driveables.Push((*it));
        _checkpointPickers.Push((*it));
        _powerupPickers.Push((*it));
    }

    for (auto it = _vehicles.Begin(); it != _vehicles.End(); ++it) {
        _driveables.Push((*it));
        _checkpointPickers.Push((*it));
        _powerupPickers.Push((*it));
    }
}

void Usables::sendOutPredictedNodes()
{
    for (auto it = _vehicles.Begin(); it != _vehicles.End(); ++it) {
        (*it)->sendPredictedNodeIds();
    }

    for (auto it = _sleds.Begin(); it != _sleds.End(); ++it) {
        (*it)->sendPredictedNodeIds();
    }
}