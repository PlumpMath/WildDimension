#pragma once

#include <Urho3D/Urho3DAll.h>

using namespace Urho3D;

class DriverAI : public LogicComponent
{
	URHO3D_OBJECT(DriverAI, LogicComponent);

public:
	DriverAI(Context* context);
	~DriverAI();

	static void RegisterObject(Context* context);

	void setTargetPosition(Vector3 pos);

	void setArriveRadius(float r);

	virtual void FixedUpdate(float timeStep);
	virtual void FixedPostUpdate(float timeStep);
	virtual void PostUpdate(float timeStep);
	void setTrackPath(Vector<Vector3> trackPath);

    void HandleAIEvents(StringHash eventType, VariantMap& eventData);

    void setSteerAngle(float val);
    void setDriftAngleMin(float val);
    void setDriftAngleMax(float val);
    void setDriftSpeedMin(float val);
    void setResetThreshold(float val);

    void setTargetNode(Node* node);

private:
	/**
	 * Target position to reach
	 */
	Vector3 _targetPosition;

	/**
	 * Radius which defines when the target was reached
	 */
	float _arriveRadius;

	Vector<Vector3> _trackPath;

	bool _isSled;
	bool _isVehicle;

	int _currentPathIndex;

	/**
	 * Object should be marked for restarting for some time
	 * before actually restarting the object
	 */
	float _resetTime;

	/**
	 * For how long this object should stay inactive before restarting
	 */
	float _resetThreshold;

    float _steerAngle;

    float _driftAngleMin;
    float _driftAngleMax;
    float _driftSpeedMin;

    /**
     * A node to follow
     */
    SharedPtr<Node> _targetNode;
};