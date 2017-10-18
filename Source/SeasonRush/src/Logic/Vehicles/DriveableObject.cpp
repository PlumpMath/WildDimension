#include "Logic/Vehicles/DriveableObject.h"
#include "Events.h"
#include "Logic/Vehicles/Offroad/DriverAI.h"

DriveableObject::DriveableObject():
_busy(false)
{
}

DriveableObject::~DriveableObject()
{

}

void DriveableObject::setControls(Controls controls)
{
	_controls = controls;
}


unsigned int DriveableObject::getDriveableObjectID()
{
	return getNode()->GetID();
}

void DriveableObject::setBusy(bool val)
{
	_busy = val;
}

bool DriveableObject::getBusy()
{
	return _busy;
}

void DriveableObject::setAIEnabled(bool val)
{
	if (getNode()->HasComponent<DriverAI>()) {
		getNode()->GetComponent<DriverAI>()->SetEnabled(val);
	}
}

bool DriveableObject::getAIEnabled()
{
	if (getNode()->HasComponent<DriverAI>()) {
		return getNode()->GetComponent<DriverAI>()->IsEnabled();
	}
	return false;
}

void DriveableObject::reset()
{
	reset(getNode()->GetDirection());
}

void DriveableObject::reset(Vector3 dir)
{
	Quaternion newRot = Quaternion();
	getNode()->SetRotation(newRot);
	getNode()->SetDirection(dir);
	Vector3 pos = getNode()->GetPosition();
	pos.y_ += 0.5f;
	//raycastVehicle_->SetLinearVelocity(Vector3::ZERO);
	//raycastVehicle_->SetAngularVelocity(Vector3::ZERO);
}