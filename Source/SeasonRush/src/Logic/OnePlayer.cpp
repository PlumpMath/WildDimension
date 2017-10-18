#include <Urho3D/Urho3DAll.h>
#include "Logic/OnePlayer.h"
#include "Events.h"
#include "Logic/Vehicles/Offroad/DriverAI.h"
#include "Logic/Vehicles/CheckpointPicker.h"

using namespace Urho3D;


OnePlayer::OnePlayer(Context* context) :
Urho3D::LogicComponent(context),
_node(0),
_cameraNode(0),
_driveableObject(nullptr),
_ping(0),
_isServerPlayer(false),
_updateNeeded(false),
_lastActionCooldown(0.0f)
{
    SubscribeToEvent(E_CP_POINTS_CHANGED, URHO3D_HANDLER(OnePlayer, playerPointsChanged));
    SubscribeToEvent(E_LAST_CHECKPOINT_REACHED, URHO3D_HANDLER(OnePlayer, lastCheckpointReached));
}


OnePlayer::~OnePlayer()
{
}


void OnePlayer::RegisterObject(Context* context)
{
	context->RegisterFactory<OnePlayer>();
}

void OnePlayer::setUsables(Usables* usables)
{
    _usables = usables;
}

void OnePlayer::setControlledNode(Node* node)
{
    assert(node);
    _node = node;
}

Node* OnePlayer::getControlledNode()
{
    return _node;
}

void OnePlayer::setName(String name)
{
    _name = name;
}

String OnePlayer::getName()
{
    return _name;
}

void OnePlayer::setHealth(unsigned short val)
{
    _health = val;
}

unsigned short OnePlayer::getHealth()
{
    return _health;
}

void OnePlayer::setPingRequestTime(unsigned int time)
{
    _pingRequestTime = time;
}

unsigned int OnePlayer::getPingRequestTime()
{
    return _pingRequestTime;
}

void OnePlayer::setPing(unsigned int time)
{
    _ping = time;
}

unsigned short OnePlayer::getPing()
{
    return _ping;
}

void OnePlayer::setCameraNodeById(unsigned int id)
{
    _cameraNode = _usables->getActiveScene()->GetNode(id);
}

void OnePlayer::setCameraNode(Node* node)
{
    _cameraNode = node;
}

Node* OnePlayer::getCameraNode()
{
    if (_cameraNode == nullptr) {
        return _node;
    }
    return _cameraNode;
}

void OnePlayer::addPoints(float val)
{
    _points += val;
}

void OnePlayer::setPoints(float val)
{
    _points = val;
}

float OnePlayer::getPoints()
{
    return _points;
}

void OnePlayer::setControls(Controls controls)
{
    _controls = controls;
}

Controls OnePlayer::getControls()
{
    return _controls;
}

void OnePlayer::setServerPlayer(bool val)
{
	_isServerPlayer = val;
}

bool OnePlayer::isServerPlayer()
{
    return _isServerPlayer;
}

void OnePlayer::togglePhysics(bool val)
{
	if (!_isServerPlayer) {
		return;
	}

	if (!val) {
		//Remove physics related components
		if (_node) {
			if (_node->HasComponent<RigidBody>()) {
				_node->RemoveComponent<RigidBody>();
			}
			if (_node->HasComponent<CollisionShape>()) {
				_node->RemoveComponent<CollisionShape>();
			}
		}
	}
	else {
		//Add physics related components
		if (_node) {
			if (!_node->HasComponent<RigidBody>()) {
				_node->CreateComponent<RigidBody>();
			}
			if (!_node->HasComponent<CollisionShape>()) {
				_node->CreateComponent<CollisionShape>();
			}
			//Enable physics for this node
			RigidBody* body = _node->GetComponent<RigidBody>();
			body->SetMass(1);
			body->SetRestitution(0.7);
			body->SetFriction(1000);
			body->SetAngularDamping(0.6);
			body->SetLinearDamping(0.6);

			//What shape will be used for this node
			CollisionShape* shape = _node->GetComponent<CollisionShape>();
			shape->SetSphere(1);
		}
	}
}

void OnePlayer::fixYPos(float y)
{
	Vector3 curPos = _node->GetPosition();
	curPos.y_ = y;
	_node->SetPosition(curPos);
}

void OnePlayer::enterDriveableObject(DriveableObject* driveableObject)
{
	if (!_isServerPlayer) {
		return;
	}

    if (_lastActionCooldown > 0) {
        return;
    }

    if (_driveableObject != nullptr) {
        return;
    }

    if (driveableObject == nullptr) {
        return;
    }

    assert(driveableObject);

    URHO3D_LOGDEBUGF("Player entering in vehicle %d", driveableObject->getDriveableObjectID());

	togglePhysics(false);
	_driveableObject = driveableObject;
    doAction();

	_driveableObject->setBusy(true);

	_cameraNode = _driveableObject->getNode();

	_driveableObject->setAIEnabled(false);

	_node->SetEnabled(false);

    if (GetSubsystem<Network>()->IsServerRunning()) {
        VariantMap map;
        map[P_PLAYER_NODE_ID] = _cameraNode->GetID();
        map[P_PLAYER_ID] = getControlledNode()->GetID();
        if (_connection) {
            _connection->SendRemoteEvent(E_CLIENT_NODE_CHANGED, true, map);
        }
    }

    if (CheckpointPicker* cp = dynamic_cast<CheckpointPicker*>(_driveableObject)) {
        cp->updateGui();
    }

}

void OnePlayer::exitDriveableObject()
{
	if (!_isServerPlayer) {
		return;
	}

    if (_lastActionCooldown > 0) {
        return;
    }
	
    if (_driveableObject == nullptr) {
        return;
    }

	_node->SetEnabled(true);
    URHO3D_LOGDEBUGF("Player exiting from vehicle %d", _driveableObject->getDriveableObjectID());

	togglePhysics(true);

	_driveableObject->setBusy(false);

	Vector3 pos = _driveableObject->getNode()->GetPosition();
	pos.y_ += 1;
	_node->SetPosition(pos);

	_driveableObject->setControls(Controls());

	_driveableObject->setAIEnabled(true);

	_driveableObject = nullptr;
    doAction();

	_cameraNode = _node;

	VariantMap map;
	map[P_PLAYER_POINTS] = (unsigned int)0;
	map[P_PLAYER_ID] = GetID();
	SendEvent(E_GUI_POINTS_CHANGED, map);

    if (_connection) {
        map[P_PLAYER_NODE_ID] = _cameraNode->GetID();
        _connection->SendRemoteEvent(E_GUI_POINTS_CHANGED, true, map);
        _connection->SendRemoteEvent(E_CLIENT_NODE_CHANGED, true, map);
    }
}

void OnePlayer::doAction(float cooldown)
{
    _lastActionCooldown = cooldown;
	_updateNeeded = true;
}

void OnePlayer::FixedUpdate(float timeStep)
{
    if (_lastActionCooldown > 0) {
        _lastActionCooldown -= timeStep;
		if (_lastActionCooldown < 0) {
			_lastActionCooldown = 0;
		}
    }

	if (_driveableObject != nullptr) {
		if (_controls.buttons_ & PLAYER_RESET && _lastActionCooldown <= 0) {
			doAction();
			_driveableObject->reset();
		}
        Input* input = GetSubsystem<Input>();
		_driveableObject->setControls(_controls);

        if (_controls.buttons_ & PLAYER_USE) {
            exitDriveableObject();
			doAction();
        }

        //We're on foot, control ourselves
    }
    else if (_node) {
        if (_node->HasComponent<RigidBody>()) {
            RigidBody* body = _node->GetComponent<RigidBody>();

            //Where the player is looking
            Quaternion rotation(_controls.pitch_, _controls.yaw_, 0.0f);
            float MOVE_TORQUE = PLAYER_SPEED;

            if (_controls.buttons_ & PLAYER_SPRINT) {
                MOVE_TORQUE *= 2;
            }

            if (_controls.buttons_ & PLAYER_FORWARD) {
                body->ApplyForce(rotation * Vector3::FORWARD * MOVE_TORQUE);
            }
            if (_controls.buttons_ & PLAYER_BACK) {
                body->ApplyForce(rotation * Vector3::BACK * MOVE_TORQUE);
            }
            if (_controls.buttons_ & PLAYER_LEFT) {
                body->ApplyForce(rotation * Vector3::LEFT * MOVE_TORQUE);
            }
            if (_controls.buttons_ & PLAYER_RIGHT) {
                body->ApplyForce(rotation * Vector3::RIGHT * MOVE_TORQUE);
            }

            //Safety mechanism to avoid players from falling trough ground
            Vector3 currentPosition = body->GetPosition();
            /*const float terrainHeight = _terrain->GetHeight(currentPosition);
            if (currentPosition.y_ < terrainHeight) {
                currentPosition.y_ = terrainHeight;
                body->SetPosition(currentPosition);
            }*/
        }
        //drawAimRay(controls.yaw_, controls.pitch_, clientNode);

        if (_controls.buttons_ & PLAYER_USE) {
            DriveableObject* obj = _usables->getNearestDriveableObject(GetNode()->GetPosition());
            enterDriveableObject(obj);
        }
    }
}

void OnePlayer::PostUpdate(float timeStep)
{
	if (!_isServerPlayer) {
		return;
	}

	if (_driveableObject) {
		_node->SetDirection(_driveableObject->getNode()->GetDirection());
		_node->SetPosition(_driveableObject->getNode()->GetPosition());
	}
}

void OnePlayer::destroy()
{
	if (_driveableObject != nullptr) {
		exitDriveableObject();
	}

    if (_node) {
        //_node->Remove();
    }
    if (_cameraNode) {
        //_cameraNode->Remove();
    }
}

bool OnePlayer::isUpdateNeeded()
{
	if (_updateNeeded) {
		_updateNeeded = false;
		return true;
	}

	return false;
}

void OnePlayer::playerPointsChanged(StringHash eventType, VariantMap& eventData)
{
    unsigned int id = eventData[P_CP_ID].GetUInt();
    unsigned int points = eventData[P_CP_POINTS].GetUInt();
    if (_driveableObject != nullptr) {
        if (CheckpointPicker* cp = dynamic_cast<CheckpointPicker*>(_driveableObject)) {
            if (cp->getCpId() == id) {
                VariantMap map;
                map[P_PLAYER_POINTS] = points;
                map[P_PLAYER_ID] = GetID();
                SendEvent(E_GUI_POINTS_CHANGED, map);
                if (_connection) {
                    map[P_PLAYER_ID] = getControlledNode()->GetID();
                    _connection->SendRemoteEvent(E_GUI_POINTS_CHANGED, true, map);
                }
            }
        }
    }

}

void OnePlayer::lastCheckpointReached(StringHash eventType, VariantMap& eventData)
{
    unsigned int id = eventData[P_CP_ID].GetUInt();
    unsigned int position = eventData[P_PLAYER_POSITION].GetUInt();
    if (_driveableObject != nullptr) {
        if (CheckpointPicker* cp = dynamic_cast<CheckpointPicker*>(_driveableObject)) {
            if (cp->getCpId() == id) {
                VariantMap map;
                map[P_PLAYER_ID] = GetID();
                map[P_PLAYER_POINTS] = cp->reachedCheckpointCount();
                map[P_PLAYER_POSITION] = position;
                SendEvent(E_SHOW_FINAL_SCORE, map);
            }
        }
    }
}

void OnePlayer::setPlayerConnection(Connection* connection)
{
    _connection = connection;
}