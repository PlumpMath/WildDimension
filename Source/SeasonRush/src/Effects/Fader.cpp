#include "Urho3D/Urho3DAll.h"

#include "Effects/Fader.h"

// All Urho3D classes reside in namespace Urho3D
using namespace Urho3D;

Fader::Fader(Context* context) :
    Object(context)
{
    // ======== Create default Sprite ===============
   Graphics* gfx = GetSubsystem<Graphics>();
   
    // Get Fader texture
    ResourceCache* cache = GetSubsystem<ResourceCache>();
    Texture2D* faderTexture = cache->GetResource<Texture2D>("Textures/black.png");
    if (!faderTexture)
        return;

    // Create fader sprite and add to the UI layout
    UI* ui = GetSubsystem<UI>();
    faderSprite_ = ui->GetRoot()->CreateChild<Sprite>();
    if (faderSprite_ && gfx) {

        // Set fader sprite texture
        faderSprite_->SetTexture(faderTexture);

        // Set fader sprite size
        faderSprite_->SetSize(gfx->GetWidth(), gfx->GetHeight());

        // Set fader sprite alignment
        faderSprite_->SetAlignment(HA_LEFT, VA_TOP);

        // Hide by default
        faderSprite_->SetVisible(false);

        // Z order for fader so that other UI elements can be drawn on bottom
        faderSprite_->SetPriority(400);
        // ======== End Create default Sprite ===========

       // Reset all to default state.
        fadeState_ = FADE_NONE;
        currentAlpha_ = 0.0f;
        faderDone_ = true;
        faderNowCalled_ = false;
    }

   SubscribeToEvents();
}

Fader::~Fader(void)
{
    if (faderSprite_) {
        faderSprite_->Remove();
    }
}

    /// Subscribe to necessary events.
void Fader::SubscribeToEvents()
{
    // get Time step for Fader in E_RENDERUPDATE Core step
    SubscribeToEvent(E_RENDERUPDATE, URHO3D_HANDLER(Fader, HandleUpdate));
}

void Fader::HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    if (faderNowCalled_)
   {
       using namespace Update;
       
      float timeStep = eventData[P_TIMESTEP].GetFloat();

        if(!faderDone_)
         fade(timeStep);
   }
}

void Fader::BlackScreen()
{
    if(faderDone_ && faderSprite_) {
        faderSprite_->SetOpacity(1.0f);
        faderSprite_->SetVisible(true);
    }
}

void Fader::FadeIn(float duration)
{
    if (!faderSprite_) {
        return;
    }

    if( duration < 0 )
        duration = 1.0f;//-duration;
//    if( duration < 0.000001 )
//        duration = 1.0;
    currentAlpha_ = 1.0f;
    totalDuration_ = duration;
    currentDuration_ = duration;
    fadeState_ = FADE_IN;
   faderSprite_->SetVisible(true);

    faderDone_ = false;
   faderNowCalled_ = true;
}

void Fader::FadeOut(float duration)
{
    if (!faderSprite_) {
        return;
    }
    if( duration < 0 )
      duration = 1.0f;//-duration;
//   if( duration < 0.000001 )
//      duration = 1.0;

    currentAlpha_ = 0.0f;
    totalDuration_ = duration;
    currentDuration_ = 0.0f;
    fadeState_ = FADE_OUT;
    faderSprite_->SetVisible(true);

    faderDone_ = false;
    faderNowCalled_ = true;
}

void Fader::fadeNowIn(float duration)
{
   if( faderNowCalled_ == false )
   {
      FadeIn(duration);
      faderNowCalled_ = true;
   }
}

void Fader::fadeNowOut(float duration)
{
   if( faderNowCalled_ == false )
   {
      FadeOut(duration);
      faderNowCalled_ = true;
   }
}

void Fader::fade(float timeStep)
{
    if (!faderSprite_) {
        return;
    }

    if( fadeState_ != FADE_NONE && faderSprite_)
    {
        // Set the currentAlpha_ value of the _overlay
            faderSprite_->SetOpacity(currentAlpha_);

        // If fading in, decrease the currentAlpha_ until it reaches 0.0
        if( fadeState_ == FADE_IN )
        {
            currentDuration_ -= timeStep;
            currentAlpha_ = currentDuration_ / totalDuration_;
            if( currentAlpha_ < 0.0f )
            {
                faderSprite_->SetVisible(false);
            fadeState_ = FADE_NONE;
            faderDone_ = true;
            faderNowCalled_ = false;
            }
        }

        // If fading out, increase the currentAlpha_ until it reaches 1.0
        else if( fadeState_ == FADE_OUT )
        {
            currentDuration_ += timeStep;
            currentAlpha_ = currentDuration_ / totalDuration_;
            if( currentAlpha_ > 1.0 )
            {
                faderSprite_->SetVisible(false);
            fadeState_ = FADE_NONE;
            faderDone_ = true;
            faderNowCalled_ = false;
            }
        }
    }
}