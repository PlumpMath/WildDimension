#pragma once
#include <Urho3D/Urho3DAll.h>

using namespace Urho3D;

enum CameraMode {
	CAMERA_FREELOOK,
	CAMERA_FIRST_PERSON,
	CAMERA_THIRD_PERSON,
	CAMERA_NEXT_MODE
};

/**
 * Camera is responsible for the things that are visible in the viewport
 */
class CameraController : public LogicComponent
{
private:
	/**
	 * Which node the camera follows
	 */
	Node* _target;

	/**
	 * The actual camera node
	 */
	Node* _cameraNode;

	/**
	 * This is used for the 3rd person view
	 */
	Node* _rotationNode;

	/**
	 * Camera component for the _cameraNode
	 */
	Camera* _camera;

	/**
	 * Camera mode
	 */
	CameraMode _mode;

	/**
	 * User keys
	 */
	Controls _controls;

	/**
	 *
	 */
	float _lastCameraChange;

	float _lastCameraMove;

	bool _isMoving;

	float _backDistance;

    bool _enabled;

public:
	CameraController(Context* context);
    ~CameraController();

    /// Register object factory and attributes.
    static void RegisterObject(Context* context);

	/**
	* Initialize the camera
	*/
	void init(Scene* scene);

	/**
	 * Get the camera controller
	 */
	Camera* getCamera();

	/**
	* Get the camera node
	*/
	Node* getCameraNode();

	Node* getRotationNode();

	/**
	 * Set the camera target node
	 */
	void setTarget(Node* node);

	/**
	* Post update
	*/
	virtual void PostUpdate(float timeStep);

	/**
	 * Change camera node
	 * by default this will toggle between modes
	 */
	void setCameraMode(CameraMode mode = CAMERA_NEXT_MODE);

	/**
	 * Is the camera in freelook mode
	 */
	bool isFreelookMode();

	/**
	 * Set the user controls
	 * Whichc keys are pressed etc.
	 */
	void setControls(Controls controls);

    void HandleFinalCamera(StringHash eventType, VariantMap& eventData);

    URHO3D_OBJECT(CameraController, Urho3D::LogicComponent);
};
