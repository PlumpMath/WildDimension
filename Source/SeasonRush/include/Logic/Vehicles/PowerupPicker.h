#pragma once

#include "Logic/PowerUp.h"

/**
 * Powerup picker
 */
class PowerupPicker
{
protected:
    /**
     * Extra speed multiplicator
     * 0 - means no extra boost
     * 1 - means 100% more engine power
     */
	float _speedBoost;

    /**
     * Lifetime for the boost effect. After this
     * time have passed, all the boost values will
     * be set to 0
     */
	float _powerupLifetime;

    /**
     * Is the powerup picker able to pickup any powerups
     */
	bool _active;

    /**
     * If power picker have retrieved powerup, it will
     * be stored here
     */
	SharedPtr<PowerUp> _powerUp;

public:
	PowerupPicker();
    ~PowerupPicker();

    /**
     * Pick up powerup
     */
	void pickUpPowerup(PowerUp *powerup);

    /**
     * If powerup is picked up, we should check it's
     * effect lifetime. After the pickup lifetime has expired
     * powerup should be reenabled again
     */
	void updatePowerupPicker(float timeStep);

    /**
     * Get parent component node
     */
    virtual Node* getNode() = 0;
};
