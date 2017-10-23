#pragma once

#include "Logic/PowerUp.h"

/**
 * Powerup picker
 */
class DriveableObject
{
protected:
    /**
     * User controls
     */
	Controls _controls;

    /**
     * Is this driveable available for use.
     * Busy means that either driveable object is inaccessible or other
     * player is already using this object
     */
	bool _busy;
public:
	DriveableObject();
    ~DriveableObject();

    /**
     * Set user controls
     */
	void setControls(Controls controls);

    /**
     * Get driveable object identificator
     */
	unsigned int getDriveableObjectID();

    /**
     * Set busy state for this object.
     * True - players will be unable to use this object
     * False - all the players can access this object
     */
	void setBusy(bool val);

    /**
     * Get the status of this vehicle
     */
	bool getBusy();

    /**
     * Enable AI driving for this object
     */
	void setAIEnabled(bool val);

    /**
     * Check if the AI is enabled for this object
     */
	bool getAIEnabled();
	
    /**
     * Reset object. Rotation will be changed but the direction
     * will remain the same
     */
	void reset();

    /**
     * Reset object. Rotation will be changed but the direction
     * will be set based on provided parameter
     */
	void reset(Vector3 dir);

    /**
     * Get parent component node
     */
	virtual Node* getNode() = 0;
};
