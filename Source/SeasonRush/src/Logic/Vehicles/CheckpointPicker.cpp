#include "Logic/Vehicles/CheckpointPicker.h"
#include "Events.h"

CheckpointPicker::CheckpointPicker():
    _cpId(0)
{

}

CheckpointPicker::~CheckpointPicker()
{

}

void CheckpointPicker::checkpointReached(unsigned int id)
{
    _reachedCheckpoints[id] = true;

    updateGui();
}

bool CheckpointPicker::haveReached(unsigned int id)
{
    return (bool) _reachedCheckpoints.count(id);
}

unsigned int CheckpointPicker::reachedCheckpointCount()
{
    return _reachedCheckpoints.size();
}

void CheckpointPicker::updateGui()
{
    {
        VariantMap map;
        map[P_PLAYER_ID] = getNode()->GetID();
        map[P_PLAYER_NAME] = "Node " + String(map[P_PLAYER_ID]);
        map[P_PLAYER_TYPE] = USABLE_TYPE_SLED;
        map[P_PLAYER_POINTS] = (unsigned int)_reachedCheckpoints.size();
        getComponent()->SendEvent(E_UPDATE_SCORE, map);
        getComponent()->GetSubsystem<Network>()->BroadcastRemoteEvent(E_UPDATE_SCORE, true, map);
    }

    {
        VariantMap map;
        map[P_CP_POINTS] = (unsigned int)_reachedCheckpoints.size();
        map[P_CP_ID] = getCpId();
        getComponent()->SendEvent(E_CP_POINTS_CHANGED, map);
    }
}

unsigned int CheckpointPicker::getCpId()
{
    return _cpId;
}

void CheckpointPicker::setCpId(unsigned int id)
{
    _cpId = id;
}