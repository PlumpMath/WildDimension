#include "Logic/Vehicles/Offroad/DriverAI.h"
#include "Logic/Vehicles/Offroad/Sled.h"
#include "Logic/Vehicles/Offroad/NewVehicle.h"
#include <Urho3D/Urho3DAll.h>
#include "Events.h"

using namespace Offroad;

DriverAI::DriverAI(Context* context) :
	LogicComponent(context),
	_arriveRadius(4),
	_currentPathIndex(-1),
	_isSled(false),
	_isVehicle(false),
    _steerAngle(8.0f),
    _driftAngleMin(50.0f),
    _driftAngleMax(70.0f),
	_resetThreshold(5.0f),
	_resetTime(0.0f)
{
	SetUpdateEventMask(USE_FIXEDUPDATE | USE_FIXEDPOSTUPDATE | USE_POSTUPDATE);
    SubscribeToEvent(E_AI_START_FROM_FIRST_CHECKPOINT, URHO3D_HANDLER(DriverAI, HandleAIEvents));
    SubscribeToEvent(E_AI_ARRIVE_RADIUS, URHO3D_HANDLER(DriverAI, HandleAIEvents));
    SubscribeToEvent(E_AI_STEER_ANGLE, URHO3D_HANDLER(DriverAI, HandleAIEvents));
    SubscribeToEvent(E_AI_DRIFT_MIN_ANGLE, URHO3D_HANDLER(DriverAI, HandleAIEvents));
    SubscribeToEvent(E_AI_DRIFT_MAX_ANGLE, URHO3D_HANDLER(DriverAI, HandleAIEvents));
    SubscribeToEvent(E_AI_DRIFT_MIN_SPEED, URHO3D_HANDLER(DriverAI, HandleAIEvents));
    SubscribeToEvent(E_AI_RESET_TIME, URHO3D_HANDLER(DriverAI, HandleAIEvents));
    SubscribeToEvent(E_AI_SET_TARGET_NODE, URHO3D_HANDLER(DriverAI, HandleAIEvents));
    SubscribeToEvent(E_AI_REMOVE_TARGET_NODE, URHO3D_HANDLER(DriverAI, HandleAIEvents));
}

DriverAI::~DriverAI()
{
}

void DriverAI::RegisterObject(Context* context)
{
    context->RegisterFactory<DriverAI>();
}

void DriverAI::setTargetPosition(Vector3 pos)
{
	_targetPosition = pos;
	_targetPosition.y_ = 0;
}

void DriverAI::setArriveRadius(float r)
{
	_arriveRadius = r;
}

void DriverAI::FixedUpdate(float timeStep)
{
	if (_currentPathIndex == -1 || _currentPathIndex >= _trackPath.Size()) {
		//Haha, go back to the map start and start all over again
		//_currentPathIndex = 0;
        Controls controls;
        controls.Set(PLAYER_FORWARD, false);
        controls.Set(PLAYER_BACK, false);
        controls.Set(PLAYER_LEFT, false);
        controls.Set(PLAYER_RIGHT, false);
        if (_isSled) {
            GetNode()->GetComponent<Sled>()->setControls(controls);
        }
        else if (_isVehicle) {
            GetNode()->GetComponent<NewVehicle>()->setControls(controls);
        }
		return;
	}

    Vector3 dirToTarget;
    Vector3 direction = GetNode()->GetWorldDirection();
    direction.y_ = 0;
    Vector3 currentPosition = GetNode()->GetWorldPosition();
    currentPosition.y_ = 0;

    if (!_targetNode) {
        _trackPath.At(_currentPathIndex).y_ = 0;
        dirToTarget = _trackPath.At(_currentPathIndex) - currentPosition;
    }
    else {
        Vector3 targetPos = _targetNode->GetWorldPosition();
        targetPos.y_ = 0;
        dirToTarget = targetPos - currentPosition;
    }

	if (dirToTarget.LengthSquared() <= _arriveRadius * _arriveRadius) {
        if (!_targetNode) {
            //This AI player reached the waypoint
            _currentPathIndex++;

            if (_currentPathIndex >= _trackPath.Size()) {
                if (_isSled) {
                    URHO3D_LOGDEBUGF("Sled %d reached finish line!", GetNode()->GetComponent<Sled>()->getSledID());
                }
                else if (_isVehicle) {
                    URHO3D_LOGDEBUGF("Vehicle %d reached finish line!", GetNode()->GetComponent<NewVehicle>()->getVehicleID());
                }
            }
        }
	}

	direction.Normalize();
	dirToTarget.Normalize();

	float angle = (atan2(dirToTarget.z_, dirToTarget.x_) - atan2(direction.z_, direction.x_)) * 180.0f / M_PI;

	if (angle < -180) {
		angle += 360;
	}

	if (angle > 180) {
		angle -= 360;
	}

    Controls controls;
    controls.Set(PLAYER_FORWARD, true);
    controls.Set(PLAYER_BACK, false);
    controls.Set(PLAYER_LEFT, false);
    controls.Set(PLAYER_RIGHT, false);

	if (_isSled) {
		if (GetNode()->GetComponent<Sled>()->isReady() && GetNode()->GetComponent<Sled>()->GetSpeedKmH() < 3.0f) {
            _resetTime += timeStep;
			if (_resetTime > _resetThreshold) {
				GetNode()->GetComponent<Sled>()->reset(dirToTarget);
                _resetTime = 0;
			}
		}
		else {
            _resetTime = 0;
		}
        if (Abs(angle) > _driftAngleMin && Abs(angle) < _driftAngleMax && GetNode()->GetComponent<Sled>()->GetSpeedKmH() > _driftSpeedMin) {
            controls.Set(PLAYER_JUMP, true);
            //URHO3D_LOGDEBUGF("Sled %d drifting", GetNode()->GetComponent<Sled>()->getSledID());
        }
		if (Abs(angle) < _steerAngle) {
            controls.Set(PLAYER_LEFT, false);
            controls.Set(PLAYER_RIGHT, false);
            controls.Set(PLAYER_FORWARD, true);
		}
		else if (angle < 0) {
            controls.Set(PLAYER_RIGHT, true);
            controls.Set(PLAYER_LEFT, false);
			if (angle < -80) {
                controls.Set(PLAYER_FORWARD, false);
			}
		}
		else if (angle > 0) {
            controls.Set(PLAYER_RIGHT, false);
            controls.Set(PLAYER_LEFT, true);
			if (angle > 80) {
                controls.Set(PLAYER_FORWARD, false);
			}
		}
		if (GetNode()->GetComponent<Sled>()->GetSpeedKmH() < 20) {
            controls.Set(PLAYER_FORWARD, true);
		}
        GetNode()->GetComponent<Sled>()->setControls(controls);
	}
	else if (_isVehicle) {
		if (GetNode()->GetComponent<NewVehicle>()->isReady() && GetNode()->GetComponent<NewVehicle>()->GetSpeedKmH() < 3.0f) {
			_resetTime += timeStep;
			if (_resetTime > _resetThreshold) {
				GetNode()->GetComponent<NewVehicle>()->reset(dirToTarget);
                _resetTime = 0;
			}
		}
		else {
			_resetTime = 0;
		}

        if (Abs(angle) > _driftAngleMin && Abs(angle) < _driftAngleMax && GetNode()->GetComponent<NewVehicle>()->GetSpeedKmH() > _driftSpeedMin) {
            controls.Set(PLAYER_JUMP, true);
            //URHO3D_LOGDEBUGF("Vehicle %d drifting", GetNode()->GetComponent<NewVehicle>()->getVehicleID());
        }
		if (Abs(angle) < _steerAngle) {
            controls.Set(PLAYER_LEFT, false);
            controls.Set(PLAYER_RIGHT, false);
            controls.Set(PLAYER_FORWARD, true);
		}
		else if (angle < 0) {
            controls.Set(PLAYER_LEFT, false);
            controls.Set(PLAYER_RIGHT, true);
			if (angle < -80) {
                controls.Set(PLAYER_FORWARD, false);
			}
		}
		else if (angle > 0) {
            controls.Set(PLAYER_LEFT, true);
            controls.Set(PLAYER_RIGHT, false);
			if (angle > 80) {
                controls.Set(PLAYER_FORWARD, false);
			}
		}
		if (GetNode()->GetComponent<NewVehicle>()->GetSpeedKmH() < 20) {
            controls.Set(PLAYER_FORWARD, true);
		}

        GetNode()->GetComponent<NewVehicle>()->setControls(controls);
	}
	
	/*if (GetNode()->GetComponent<Sled>()->GetSpeedKmH() < 1) {
		GetNode()->GetComponent<Sled>()->reset();
	}*/
}

void DriverAI::FixedPostUpdate(float timeStep)
{

}

void DriverAI::PostUpdate(float timeStep)
{

}

void DriverAI::setTrackPath(Vector<Vector3> trackPath)
{
	_trackPath = trackPath;
	if (!_trackPath.Empty()) {
		_currentPathIndex = 0;
	}

	if (GetNode()->HasComponent<Sled>()) {
		_isSled = true;
		_isVehicle = false;
	}
	else if (GetNode()->HasComponent<NewVehicle>()) {
		_isSled = false;
		_isVehicle = true;
	}
}

void DriverAI::HandleAIEvents(StringHash eventType, VariantMap& eventData)
{
    if (eventType == E_AI_START_FROM_FIRST_CHECKPOINT) {
        //Basically start off from first checkpoint again
        _currentPathIndex = 0;
    }
    else if (eventType == E_AI_ARRIVE_RADIUS) {
        setArriveRadius(eventData[P_VALUE].GetInt());
    }
    else if (eventType == E_AI_STEER_ANGLE) {
        setSteerAngle(eventData[P_VALUE].GetInt());
    }
    else if (eventType == E_AI_DRIFT_MIN_ANGLE) {
        setDriftAngleMin(eventData[P_VALUE].GetInt());
    }
    else if (eventType == E_AI_DRIFT_MAX_ANGLE) {
        setDriftAngleMax(eventData[P_VALUE].GetInt());
    }
    else if (eventType == E_AI_DRIFT_MIN_SPEED) {
        setDriftSpeedMin(eventData[P_VALUE].GetInt());
    }
    else if (eventType == E_AI_RESET_TIME) {
        setResetThreshold(eventData[P_VALUE].GetInt());
    }
    else if (eventType == E_AI_SET_TARGET_NODE) {
        setTargetNode((Node*) eventData[P_PLAYER_NODE_PTR].GetPtr());
    }
    else if (eventType == E_AI_REMOVE_TARGET_NODE) {
        setTargetNode(nullptr);
    }
}

void DriverAI::setSteerAngle(float val)
{
    _steerAngle = val;
}

void DriverAI::setDriftAngleMin(float val)
{
    _driftAngleMin = val;
}

void DriverAI::setDriftAngleMax(float val)
{
    _driftAngleMax = val;
}

void DriverAI::setDriftSpeedMin(float val)
{
    _driftSpeedMin;
}

void DriverAI::setResetThreshold(float val)
{
    _resetThreshold = val;
}

void DriverAI::setTargetNode(Node* node)
{
    _targetNode = node;
}