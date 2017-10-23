#include <Urho3D/Urho3DAll.h>
#include "Logic/CameraController.h"
#include "Events.h"

CameraController::CameraController(Context* context):
	LogicComponent(context),
	_target(0),
	_mode(CAMERA_THIRD_PERSON),
	_lastCameraChange(0),
	_lastCameraMove(0.0f),
	_isMoving(0.0f),
	_backDistance(5.0f),
    _enabled(true)
{
	//SetUpdateEventMask(USE_POSTUPDATE);
    SubscribeToEvent(E_END_CAMERA, URHO3D_HANDLER(CameraController, HandleFinalCamera));
}

CameraController::~CameraController()
{
}

void CameraController::RegisterObject(Context* context)
{
    context->RegisterFactory<CameraController>();
}

void CameraController::init(Scene* scene)
{
	//Create camera
	_cameraNode = scene->CreateChild("Camera", LOCAL);
	_rotationNode = _cameraNode->CreateChild("rotationNode", LOCAL);
	_rotationNode->Translate(Vector3::ZERO);
	_rotationNode->CreateComponent<SoundListener>();
	_camera = _rotationNode->CreateComponent<Camera>(LOCAL);
	_cameraNode->LookAt(Vector3(0, 0, 0));
	_camera->SetNearClip(0.01f);
	_camera->SetFarClip(1000);
	_camera->SetFov(60.0f);
    setCameraMode(CAMERA_THIRD_PERSON);
}

Camera* CameraController::getCamera()
{
	return _camera;
}

Node* CameraController::getCameraNode()
{
	return _cameraNode;
}

Node* CameraController::getRotationNode()
{
	return _rotationNode;
}

void CameraController::setTarget(Node* node)
{
	_target = node;
}

void CameraController::PostUpdate(float timeStep)
{
	//Input* input = GetSubsystem<Input>();
	//int scroll = input->GetMouseW();

	//if (input->GetKeyDown(KEY_0) {
	//	_backDistance += 0.1;
	//	setCameraMode(_mode);
	//}
    Network* network = GetSubsystem<Network>();

    if (_target && !network->IsServerRunning()) {
        network->GetServerConnection()->SetPosition(_target->GetPosition());
    }

	_lastCameraMove += timeStep;

	if (_lastCameraChange > 0) {
		_lastCameraChange -= timeStep;
	}
	
	if (_controls.buttons_ & PLAYER_CAMERA && _enabled) {
		setCameraMode();
	}

	if (_isMoving) {
		_lastCameraMove = 0;
	}

	if (_mode == CAMERA_FIRST_PERSON) {

		if (!_target) {
			return;
		}
		_cameraNode->SetPosition(_target->GetPosition());
	}
	else if (_mode == CAMERA_THIRD_PERSON) {

		if (!_target) {
			return;
		}
		_cameraNode->SetPosition(_target->GetPosition());
	}
	else if (_mode == CAMERA_FREELOOK && _enabled) {

		float MOVE_SPEED = 10;

		//Is shift pressed
		if (_controls.buttons_ & PLAYER_SPRINT) { // 1 is shift, 2 is ctrl, 4 is alt
			MOVE_SPEED *= 10;
		}
		if (_controls.buttons_ & PLAYER_FORWARD) {
			_cameraNode->Translate(Vector3(0, 0, 1)*MOVE_SPEED*timeStep);
		}
		if (_controls.buttons_ & PLAYER_BACK) {
			_cameraNode->Translate(Vector3(0, 0, -1)*MOVE_SPEED*timeStep);
		}
		if (_controls.buttons_ & PLAYER_LEFT) {
			_cameraNode->Translate(Vector3(-1, 0, 0)*MOVE_SPEED*timeStep);
		}
		if (_controls.buttons_ & PLAYER_RIGHT) {
			_cameraNode->Translate(Vector3(1, 0, 0)*MOVE_SPEED*timeStep);
		}

	}

	/*if (_lastCameraMove > 2.0f && _mode != CAMERA_FREELOOK) {
		_cameraNode->SetDirection(Vector3::FORWARD);
		float yaw = _target->GetRotation().EulerAngles().y_;
		_cameraNode->Yaw(yaw);
		if (_mode == CAMERA_THIRD_PERSON) {
			_cameraNode->Pitch(20);
		}
	}
	else {
	*/
		_cameraNode->SetDirection(Vector3::FORWARD);
		_cameraNode->Yaw(_controls.yaw_);
		_cameraNode->Pitch(_controls.pitch_);
	//}

}

void CameraController::setCameraMode(CameraMode mode)
{
	if (_lastCameraChange > 0) {
		return;
	}

	CameraMode nextMode = mode;
	if (mode == CAMERA_NEXT_MODE) {
		if (_mode == CAMERA_FIRST_PERSON) {
			nextMode = CAMERA_THIRD_PERSON;
		}
		else if (_mode == CAMERA_THIRD_PERSON) {
			nextMode = CAMERA_FREELOOK;
		}
		else if (_mode == CAMERA_FREELOOK) {
			nextMode = CAMERA_FIRST_PERSON;
		}
	}

	switch (nextMode) {
	case CAMERA_FIRST_PERSON:
		_rotationNode->SetPosition(Vector3::ZERO);
		break;
	case CAMERA_THIRD_PERSON:
		_rotationNode->SetPosition(Vector3::BACK * _backDistance);
		break;
	case CAMERA_FREELOOK:
		_rotationNode->SetPosition(Vector3::ZERO);
		break;
	}

	_mode = nextMode;
	_lastCameraChange = 0.5f;
}

bool CameraController::isFreelookMode()
{
	return _mode == CAMERA_FREELOOK;
}

void CameraController::setControls(Controls controls)
{
	if (_controls.yaw_ == controls.yaw_ && _controls.pitch_ == controls.pitch_) {
		_isMoving = false;
	}
	else {
		_isMoving = true;
	}
	_controls = controls;
}

void CameraController::HandleFinalCamera(StringHash eventType, VariantMap& eventData)
{
    setCameraMode(CAMERA_FREELOOK);
    _enabled = false;
}