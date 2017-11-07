//
// Copyright (c) 2008-2016 the Urho3D project.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#include "Core/ProcessUtils.h"
#include "Graphics/Graphics.h"
#include "Graphics/Renderer.h"
#include "Input/Controls.h"
#include "Input/Input.h"
#include "Resource/ResourceCache.h"
#include "IO/Log.h"

#include <GameController/GameController.h>

#include "DebugNew.h"
//=============================================================================
//=============================================================================
GameController::GameController(Context* context)
    : Object(context)
    , joystickID_(-1)
    , minTolerance_(0.2f)

{
}

GameController::~GameController()
{
}

bool GameController::CreateController()
{
    ResourceCache* cache = GetSubsystem<ResourceCache>();
    Input* input = GetSubsystem<Input>();

    // create or detect joystick
    if (GetPlatform() == "Android" || GetPlatform() == "iOS" || 1 == 1)
    {
        // remove the default screen joystick created in the Sample::InitTouchInput() fn.
        //**note** this would not be required if you don't inherit your app from the Sample class
        //RemoveScreenJoystick();

        // and create our own
        XMLFile *layout = cache->GetResource<XMLFile>("ScreenJoystick/ScreenJoystick.xml");
        joystickID_ = input->AddScreenJoystick(layout, cache->GetResource<XMLFile>("UI/DefaultStyle.xml"));
    }
    else
    {
        // get the 1st controller joystick detected
        for ( unsigned i = 0; i < input->GetNumJoysticks(); ++i )
        {
            JoystickState *joystick = input->GetJoystickByIndex(i);

            if (joystick->IsController())
            {
                joystickID_ = joystick->joystickID_;
                break;
            }
        }
    }

    //#define DUMP_JOYSTICK_INFO
    #ifdef DUMP_JOYSTICK_INFO
    if (joystickID_ != -1)
    {
        JoystickState *joystick = input->GetJoystick(joystickID_);

        if (joystick)
        {
            URHO3D_LOGINFOF("Selected joystick: id=%d, name='%s'", 
                            joystickID_,
                            !joystick->name_.Empty()?joystick->name_.CString():"null");
        }
        DumpAll();
    }
    #endif

    SubscribeToEvent(E_JOYSTICKCONNECTED, URHO3D_HANDLER(GameController, HandleJoystickConnected));
    SubscribeToEvent(E_JOYSTICKDISCONNECTED, URHO3D_HANDLER(GameController, HandleJoystickDisconnected));

    return (joystickID_ != -1);
}

void GameController::RemoveScreenJoystick()
{
    Input* input = GetSubsystem<Input>();

    for ( unsigned i = 0; i < input->GetNumJoysticks(); ++i )
    {
        JoystickState *joystick = input->GetJoystickByIndex(i);

        if (joystick->screenJoystick_)
        {
            input->RemoveScreenJoystick(joystick->joystickID_);
            break;
        }
    }
}

void GameController::UpdateControlInputs(Controls& controls)
{
    // clear buttons
    controls.buttons_ = 0;

    if (IsValid())
    {
        JoystickState *joystick = GetSubsystem<Input>()->GetJoystick(joystickID_);

        if (joystick)
        {
            // buttons
            for ( unsigned i = 0; i < joystick->GetNumButtons() && i < SDL_CONTROLLER_BUTTON_MAX; ++i )
            {
                controls.Set((1<<i), joystick->GetButtonDown(i));
            }

            // axis
            const StringHash axisHashList[SDL_CONTROLLER_AXIS_MAX/2] = { VAR_AXIS_0, VAR_AXIS_1, VAR_AXIS_2 };
            for ( unsigned i = 0; i < joystick->GetNumAxes() && i < SDL_CONTROLLER_AXIS_MAX; i += 2 )
            {
                Vector2 val(joystick->GetAxisPosition(i), joystick->GetAxisPosition(i+1));

                // clamp values except for triggers
                if (i < SDL_CONTROLLER_AXIS_TRIGGERLEFT)
                {
                    ClampValues(val, minTolerance_);
                }

                controls.extraData_[axisHashList[i/2]] = val;
            }
        }
    }
}

void GameController::ClampValues(Vector2 &vec, float minVal) const
{
    if (Abs(vec.x_) < minVal)
    {
        vec.x_ = 0.0f;
    }
    if (Abs(vec.y_) < minVal)
    {
        vec.y_ = 0.0f;
    }

    // diagonal pts between x and y axis result in magnitude > 1, normalize
    if (vec.Length() > 1.0f)
    {
        vec.Normalize();
    }
}

void GameController::DumpAll() const
{
    Input* input = GetSubsystem<Input>();
    URHO3D_LOGINFOF("-------- num joysticks=%u --------", input->GetNumJoysticks());

    for ( unsigned i = 0; i < input->GetNumJoysticks(); ++i )
    {
        DumpControllerInfo(i, true);
    }
    URHO3D_LOGINFO("---------------------------------");
}

void GameController::DumpControllerInfo(unsigned idx, bool useIdx) const
{
    JoystickState *joystick = useIdx?GetSubsystem<Input>()->GetJoystickByIndex(idx):GetSubsystem<Input>()->GetJoystick((int)idx);

    if (joystick)
    {
        URHO3D_LOGINFOF("joystick: id=%d, name='%s', btns=%u, axes=%u, hats=%u, isctrl=%u",
                        joystick->joystickID_,
                        !joystick->name_.Empty()?joystick->name_.CString():"null",
                        joystick->GetNumButtons(),
                        joystick->GetNumAxes(),
                        joystick->GetNumHats(),
                        joystick->IsController()?1:0);
    }
}

void GameController::HandleJoystickConnected(StringHash eventType, VariantMap& eventData)
{
    using namespace JoystickConnected;
    int joystickID = eventData[P_JOYSTICKID].GetInt();

    // auto-assign if yet assigned
    if (joystickID_ == -1)
    {
        joystickID_ = joystickID;
    }
    URHO3D_LOGINFOF("Joystick connected: id=%d", joystickID);

    DumpControllerInfo((unsigned)joystickID);
}

void GameController::HandleJoystickDisconnected(StringHash eventType, VariantMap& eventData)
{
    using namespace JoystickDisconnected;
    int joystickID = eventData[P_JOYSTICKID].GetInt();

    URHO3D_LOGINFOF("Joystick disconnected: id=%d", joystickID);
}


