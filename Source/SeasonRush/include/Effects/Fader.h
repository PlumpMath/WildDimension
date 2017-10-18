#pragma once

#include "Urho3D/Urho3DAll.h"

namespace Urho3D
{
class Sprite;
}

using namespace Urho3D;

class Fader : public Object
{
    URHO3D_OBJECT(Object, Fader);

protected:
    enum fadeState_{
      FADE_NONE,
      FADE_IN,
      FADE_OUT,
      }fadeState_;

    // Fader sprite.
   SharedPtr<Sprite> faderSprite_;

    float currentAlpha_;
    float currentDuration_;
    float totalDuration_;
    bool faderDone_;
    bool faderNowCalled_;

public:

    Fader(Context* context);
    ~Fader(void);

    void BlackScreen();
    void FadeIn(float duration = 1.0f);
    void FadeOut(float duration = 1.0f);
    void fadeNowIn(float duration = 1.0f);   // Can only be called once
    void fadeNowOut(float duration = 1.0f);   // Can only be called once
    void fade(float timeSinceLastFrame);
    bool isFaderCalled(void){return faderNowCalled_;};
    bool isFaderDone(void){ return faderDone_; };

private:
    // Subscribe to necessary events.
    void SubscribeToEvents();
    // Handle application update. Fader need for Time step.
    void HandleUpdate(StringHash eventType, VariantMap& eventData);
};
