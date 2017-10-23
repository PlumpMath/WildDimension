#pragma once

#include "Logic/PowerUp.h"
#include <map>

/**
 * Powerup picker
 */
class CheckpointPicker
{
private:
    /**
     * Checkpoint picker identification
     */
    unsigned int _cpId;

    /**
     * List of reached checkpoints
     */
    std::map<unsigned int, bool> _reachedCheckpoints;

public:
    CheckpointPicker();
    ~CheckpointPicker();

    /**
    * When checkpoint is reached
    */
    void checkpointReached(unsigned int id);

    /**
    * Did object reached specific checkpoint
    */
    bool haveReached(unsigned int id);

    /**
     * Get reached checkpoint count
     */
    unsigned int reachedCheckpointCount();

    /**
     * Send out GUI update events
     */
    void updateGui();

    /**
     * Get parent component node
     */
    virtual Node* getNode() = 0;

    /**
     * Get checkpoint picker ID
     */
    unsigned int getCpId();

    /**
     * Set checkpoint picker ID
     */
    void setCpId(unsigned int id);

    /**
     * Get parent component
     */
    virtual Component* getComponent() = 0;

};
