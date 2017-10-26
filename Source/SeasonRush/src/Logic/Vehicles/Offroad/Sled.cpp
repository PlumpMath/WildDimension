#include <Urho3D/Urho3D.h>

#include <Urho3D/Physics/CollisionShape.h>
#include <Urho3D/Physics/Constraint.h>
#include <Urho3D/Core/Context.h>
#include <Urho3D/Graphics/Material.h>
#include <Urho3D/Graphics/Model.h>
#include <Urho3D/Physics/PhysicsEvents.h>
#include <Urho3D/Physics/PhysicsWorld.h>
#include <Urho3D/Physics/PhysicsUtils.h>
#include <Urho3D/Resource/ResourceCache.h>
#include <Urho3D/Physics/RigidBody.h>
#include <Urho3D/Scene/Scene.h>
#include <Urho3D/Graphics/StaticModel.h>
#include <Urho3D/Graphics/DebugRenderer.h>
#include <Urho3D/Graphics/ParticleEmitter.h>
#include <Urho3D/Graphics/ParticleEffect.h>
#include <Urho3D/Audio/SoundSource3D.h>
#include <Urho3D/Audio/Sound.h>

#include "Logic/Vehicles/Offroad/Sled.h"
#include "Logic/Vehicles/Offroad/RaycastVehicle.h"
#include "Logic/Vehicles/Offroad/WheelTrackModel.h"
#include "Logic/Vehicles/Offroad/DriverAI.h"

#include <SDL/SDL_log.h>
#include <Urho3D/DebugNew.h>
#include <Urho3D/IO/Log.h>

#include "Events.h"

#define CUBE_HALF_EXTENTS       0.7f

#define MIN_SLOW_DOWN_VEL       15.0f
#define MIN_STICTION_VEL        5.0f
#define MIN_BRAKE_FORCE         0.0f
#define MIN_IDLE_RPM            1000.0f

#define MIN_DOWN_FORCE          10.0f
#define MAX_DOWN_FORCE          1e4f
#define MAX_ANGULAR_VEL_LIMIT   10.0f
#define LINEAR_VEL_LIMIT_MPH    60.0f
#define VEL_TO_MPH              (3.6f/1.60934f)
#define MAX_LINEAR_VEL_LIMIT    (LINEAR_VEL_LIMIT_MPH/VEL_TO_MPH)

#define AUDIO_FIXED_FREQ_44K    44100.0f
#define MIN_SHOCK_IMPACT_VEL    3.0f
#define MAX_SKID_TRACK_SPEED    70.0f
#define MIN_SIDE_SLIP_VEL       4.0f

#define MIN_WHEEL_RPM           0.60f
#define MAX_WHEEL_RPM           0.75f
#define MIN_WHEEL_RPM_AIR       0.89f
#define MAX_WHEEL_RPM_AIR       0.90f

#define MIN_PEELOUT_VAL_AT_ZER0 0.8f
#define MAX_REAR_SLIP           5.6f

using namespace Offroad;

Sled::Sled(Context* context)
    : LogicComponent( context )
    , steering_( 0.0f ),
	_id(0)
{
    // fixed update() for inputs and post update() to sync wheels for rendering
    SetUpdateEventMask( USE_FIXEDUPDATE | USE_FIXEDPOSTUPDATE| USE_POSTUPDATE );

    m_fVehicleMass = 10.0f;
    m_fEngineForce = 0.0f;
    m_fBreakingForce = 0.0f;

    m_fmaxEngineForce = 5.f;
    m_fmaxBreakingForce = 0.5f;

    m_fVehicleSteering = 0.0f;

    //Steering speed
    m_fsteeringIncrement = 0.01f;

    m_fsteeringClamp = 0.3f;
    m_fwheelRadius = 0.3f;
    m_fwheelWidth = 0.2f;
    m_fwheelFriction = 1.8f;

    m_fsuspensionStiffness = 40.0f;
    m_fsuspensionDamping = 2.0f;
    m_fsuspensionCompression = 3.0f;
    m_frollInfluence = 0.1f;
    m_fsuspensionRestLength = 0.1f;
    m_fsideFrictionStiffness = 0.5f;

    // skid
    m_fYAngularVelocity = 1.0f;
    m_fMaxSteering = 0.5f;
    numWheelContacts_ = 0;

    currentAcceleration_ = 0.0f;

    // gear
    downShiftRPM_ = 4500.0f;
    upShiftRPM_   = 7500.0f;
    curGearIdx_   = 0;
    curRPM_       = MIN_IDLE_RPM;

    // most vehicle dynamics have complicated gear ratio equations, gear shifting formulas, etc.
    // but it all comes down to at speeds to shift gear
    // speed shown is in mph - has no effect on whether the speed is displayed in KmH or MPH
    gearShiftSpeed_.Push(50.0f);
    gearShiftSpeed_.Push(70.0f);
    gearShiftSpeed_.Push(90.0f);
    gearShiftSpeed_.Push(110.0f);
    gearShiftSpeed_.Push(130.0f);
    numGears_ = gearShiftSpeed_.Size();

    // wheel nodes
    m_vpNodeWheel.Clear();

    // sound
    playAccelerationSoundInAir_ = true;

    SubscribeToEvent(E_SLED_SPEED, URHO3D_HANDLER(Sled, HandleSpeedChange));

}

Sled::~Sled()
{
    //Remove wheels
    for (auto it = m_vpNodeWheel.Begin(); it != m_vpNodeWheel.End(); ++it) {
        (*it)->Remove();
    }
    //Remove particle emitters for wheels
    for (auto it = particleEmitterNodeList_.Begin(); it != particleEmitterNodeList_.End(); ++it) {
        (*it)->Remove();
    }
    m_vpNodeWheel.Clear();
}

void Sled::RegisterObject(Context* context)
{
    context->RegisterFactory<Sled>();
	context->RegisterFactory<DriverAI>();
}

void Sled::ApplyAttributes()
{
}

void Sled::Init()
{
    SubscribeToEvent(node_, E_NODECOLLISIONSTART, URHO3D_HANDLER(Sled, HandleNodeCollision));

	GetNode()->SetScale(0.3);
    ResourceCache* cache = GetSubsystem<ResourceCache>();
   
    RibbonTrail* boxTrail1 = node_->CreateComponent<RibbonTrail>();
    boxTrail1->SetTrailType(TT_FACE_CAMERA);
    boxTrail1->SetMaterial(cache->GetResource<Material>("Materials/RibbonTrail.xml"));
    boxTrail1->SetStartColor(Color(1.0f, 1.0f, 1.0f, 0.5f));
    boxTrail1->SetEndColor(Color(1.0f, 1.0f, 1.0f, 0.0f));
    boxTrail1->SetWidth(0.5f);
    boxTrail1->SetEmitting(false);
    boxTrail1->SetUpdateInvisible(true);
    boxTrail1->SetTailColumn(1);
    boxTrail1->SetLifetime(1.0f);

    raycastVehicle_ = node_->CreateComponent<RaycastVehicle>();
    CollisionShape* hullColShape = node_->CreateComponent<CollisionShape>();
    StaticModel* hullObject = node_->CreateComponent<StaticModel>();

    raycastVehicle_->SetMass(m_fVehicleMass);
    raycastVehicle_->SetLinearDamping(0.0f);
    raycastVehicle_->SetAngularDamping(0.05f);
    raycastVehicle_->SetCollisionLayer(1);
   
    Model *vehModel = cache->GetResource<Model>("Models/christmas/sled.mdl");
    hullObject->SetModel(vehModel);
	hullObject->SetMaterial(0, cache->GetResource<Material>("Materials/Sled.xml"));
	hullObject->SetMaterial(1, cache->GetResource<Material>("Materials/SledBottom.xml"));

    hullObject->SetCastShadows(true);

    // set convex hull and resize local AABB.Y size
    Model *vehColModel = cache->GetResource<Model>("Models/christmas/sled.mdl");
    hullColShape->SetConvexHull(vehColModel);
    raycastVehicle_->CompoundScaleLocalAabbMin(Vector3(0.8f, 0.5f, 1.0f));
    raycastVehicle_->CompoundScaleLocalAabbMax(Vector3(0.8f, 0.5f, 1.0f));

    bool isFrontWheel=true;
    Vector3 wheelDirectionCS0(0,-1,0);
    Vector3 wheelAxleCS(-1,0,0);

    //******************
    // center of mass
    centerOfMassOffset_ = Vector3(0.0f, 0.0f, 0.0f);

    // change center of mass
    raycastVehicle_->SetVehicleCenterOfMass(centerOfMassOffset_);

	float h = 0.1f;
	float w = 2.3f;
    // add wheels
    Vector3 connectionPointCS0(CUBE_HALF_EXTENTS - (w * m_fwheelWidth), centerOfMassOffset_.y_ + h, 2*CUBE_HALF_EXTENTS-m_fwheelRadius-0.4f-centerOfMassOffset_.z_);
    raycastVehicle_->AddWheel(connectionPointCS0,wheelDirectionCS0,wheelAxleCS,m_fsuspensionRestLength,m_fwheelRadius,isFrontWheel);

    connectionPointCS0 = Vector3(-CUBE_HALF_EXTENTS + (w * m_fwheelWidth), centerOfMassOffset_.y_ + h, 2*CUBE_HALF_EXTENTS-m_fwheelRadius-0.4f-centerOfMassOffset_.z_);
    raycastVehicle_->AddWheel(connectionPointCS0,wheelDirectionCS0,wheelAxleCS,m_fsuspensionRestLength,m_fwheelRadius,isFrontWheel);

    isFrontWheel = false;
    connectionPointCS0 = Vector3(-CUBE_HALF_EXTENTS + (w * m_fwheelWidth), centerOfMassOffset_.y_ + h, -2*CUBE_HALF_EXTENTS+m_fwheelRadius+0.4f-centerOfMassOffset_.z_);
    raycastVehicle_->AddWheel(connectionPointCS0,wheelDirectionCS0,wheelAxleCS,m_fsuspensionRestLength,m_fwheelRadius,isFrontWheel);

    connectionPointCS0 = Vector3(CUBE_HALF_EXTENTS - (w * m_fwheelWidth), centerOfMassOffset_.y_ + h, -2*CUBE_HALF_EXTENTS+m_fwheelRadius+0.4f-centerOfMassOffset_.z_);
    raycastVehicle_->AddWheel(connectionPointCS0,wheelDirectionCS0,wheelAxleCS,m_fsuspensionRestLength,m_fwheelRadius,isFrontWheel);

    numWheels_ = raycastVehicle_->GetNumWheels();
    prevWheelInContact_.Resize(numWheels_);

    for ( int i = 0; i < numWheels_; i++ )
    {
        btWheelInfo& wheel = raycastVehicle_->GetWheelInfo( i );
        wheel.m_suspensionStiffness = m_fsuspensionStiffness;
        wheel.m_wheelsDampingRelaxation = m_fsuspensionDamping;
        wheel.m_wheelsDampingCompression = m_fsuspensionCompression;
        wheel.m_frictionSlip = m_fwheelFriction;
        wheel.m_rollInfluence = m_frollInfluence;

        prevWheelInContact_[i] = false;

        // side friction stiffness is different for front and rear wheels
        if (i < 2)
        {
            wheel.m_sideFrictionStiffness = 0.9f;
        }
        else
        {
            m_fRearSlip = MAX_REAR_SLIP;
            wheel.m_sideFrictionStiffness = MAX_REAR_SLIP;
        }
    }

    if ( raycastVehicle_ )
    {
        raycastVehicle_->ResetSuspension();

        float wheelDim = m_fwheelRadius*2.0f;
        float wheelThickness = 0.5f;
        Model *tireModel = cache->GetResource<Model>("Offroad/Models/tire.mdl");
        BoundingBox tirebbox = tireModel->GetBoundingBox();
        float tireScaleXZ = wheelDim/tirebbox.Size().x_;

        const Color LtBrown(0.972f,0.780f,0.412f );
		const Color LtWhite(0.8f, 0.8f, 0.8f, 0.2f);
        Model *trackModel = cache->GetResource<Model>("Offroad/Models/wheelTrack.mdl");

        for ( int i = 0; i < raycastVehicle_->GetNumWheels(); i++ )
        {
            //synchronize the wheels with the chassis worldtransform
            raycastVehicle_->UpdateWheelTransform(i,true);

            Vector3 v3Origin = raycastVehicle_->GetWheelPositionWS(i);
            Quaternion qRot = raycastVehicle_->GetWheelRotation(i);

            // wheel node
            Node *wheelNode = GetScene()->CreateChild();
            m_vpNodeWheel.Push( wheelNode );

            wheelNode->SetPosition( v3Origin );
            btWheelInfo &whInfo = raycastVehicle_->GetWheelInfo( i );
            Vector3 v3PosLS = ToVector3( whInfo.m_chassisConnectionPointCS );

            wheelNode->SetRotation( v3PosLS.x_ >= 0.0 ? Quaternion(0.0f, 0.0f, -90.0f) : Quaternion(0.0f, 0.0f, 90.0f) );
            wheelNode->SetScale(Vector3(tireScaleXZ, wheelThickness, tireScaleXZ));

            // tire model
            //StaticModel *pWheel = wheelNode->CreateComponent<StaticModel>();
            //pWheel->SetModel(tireModel);
            //pWheel->SetMaterial(cache->GetResource<Material>("Offroad/Models/Materials/Tire.xml"));
            //pWheel->SetCastShadows(true);

            // track
            Node *trackNode = GetScene()->CreateChild();;
            wheelTrackList_[i] = trackNode->CreateComponent<WheelTrackModel>();
            wheelTrackList_[i]->SetModel(trackModel->Clone());
            wheelTrackList_[i]->SetMaterial(cache->GetResource<Material>("Offroad/Models/Materials/TireTrack.xml"));

            wheelTrackList_[i]->SetParentNode(node_);
            wheelTrackList_[i]->SetColor(LtWhite);
            wheelTrackList_[i]->SetWidth(wheelThickness * 0.25f);
            wheelTrackList_[i]->ValidateBufferElements();

            // particle emitter
            Node *pNodeEmitter = GetScene()->CreateChild();
            Vector3 emitPos = v3Origin + Vector3(0,-m_fwheelRadius,0);
            pNodeEmitter->SetPosition( emitPos );
            ParticleEmitter* particleEmitter = pNodeEmitter->CreateComponent<ParticleEmitter>();
            particleEmitter->SetEffect( cache->GetResource<ParticleEffect>("Offroad/Particles/SnowSmall.xml"));
            particleEmitter->SetEmitting( false );

            particleEmitterNodeList_.Push( pNodeEmitter );
        }
    }

    // init sound
    /*engineSoundSrc_ = node_->CreateComponent<SoundSource3D>();
    engineSnd_ = cache->GetResource<Sound>("Offroad/Sounds/engine-prototype.ogg");
    engineSnd_->SetLooped(true);

    engineSoundSrc_->SetDistanceAttenuation( 1.0f, 30.0f, 0.1f );
    engineSoundSrc_->SetSoundType(SOUND_EFFECT);
    engineSoundSrc_->SetGain(0.7f);
    engineSoundSrc_->Play(engineSnd_);
    engineSoundSrc_->SetFrequency(AUDIO_FIXED_FREQ_44K * 0.05f);

    skidSoundSrc_ = node_->CreateComponent<SoundSource3D>();
    skidSnd_ = cache->GetResource<Sound>("Offroad/Sounds/skid-gravel.ogg");
    skidSoundSrc_->SetSoundType(SOUND_EFFECT);
    skidSoundSrc_->SetGain(0.4f);
    skidSoundSrc_->SetDistanceAttenuation( 1.0f, 30.0f, 0.1f );
    skidSoundSrc_->SetFrequency(AUDIO_FIXED_FREQ_44K * 1.4f );

    shockSoundSrc_ = node_->CreateComponent<SoundSource3D>();
    shockSnd_ = cache->GetResource<Sound>("Offroad/Sounds/shocks-impact.ogg");
    shockSoundSrc_->SetSoundType(SOUND_EFFECT);
    shockSoundSrc_->SetGain(0.7f);
    shockSoundSrc_->SetDistanceAttenuation( 1.0f, 30.0f, 0.1f );
	*/
    // acceleration sound while in air - most probably want this on
    playAccelerationSoundInAir_ = false;
}

void Sled::FixedUpdate(float timeStep)
{
	if (!raycastVehicle_->IsEnabled()) {
		return;
	}

    float newSteering = 0.0f;
    float accelerator = 0.0f;
    bool braking = false;

    // Read controls
    if (_controls.buttons_ & PLAYER_LEFT)
        newSteering = -1.0f;
    if (_controls.buttons_ & PLAYER_RIGHT)
        newSteering = 1.0f;
    if (_controls.buttons_ & PLAYER_FORWARD)
        accelerator = 1.0f;
    if (_controls.buttons_ & PLAYER_BACK)
        accelerator = -0.4f;
    if (_controls.buttons_ & PLAYER_JUMP)
    {
        braking = true;
        accelerator = 0.0f;
    }

    if ( newSteering != 0.0f || accelerator != 0.0f )
    {
        raycastVehicle_->Activate();
    }

    UpdateGear();

    UpdateSteering(newSteering);

    ApplyEngineForces(accelerator, braking);

    // do this right after applyEngineForce and before applying other forces
    if ( ApplyStiction(newSteering, accelerator, braking) )
    {
        return;
    }

    ApplyDownwardForce();

    LimitLinearAndAngularVelocity();

    AutoCorrectPitchRoll();

    //UpdateDrift();

}

void Sled::FixedPostUpdate(float timeStep)
{
    float curSpdMph = GetSpeedMPH();

    // clear contact states
    prevWheelContacts_ = numWheelContacts_;
    numWheelContacts_ = 0;
    float wheelVelocity = 0.0f;
    Vector3 linVel = raycastVehicle_->GetLinearVelocity();

    for ( int i = 0; i < raycastVehicle_->GetNumWheels(); i++ )
    {
        btWheelInfo &whInfo = raycastVehicle_->GetWheelInfo( i );

        // adjust wheel rotation based on acceleration
        if ( (curGearIdx_ == 0 || !whInfo.m_raycastInfo.m_isInContact ) && currentAcceleration_ > 0.0f )
        {
            // peel out on 1st gear
            if ( curGearIdx_ == 0 && whInfo.m_skidInfoCumulative > MIN_PEELOUT_VAL_AT_ZER0)
            {
                whInfo.m_skidInfoCumulative = MIN_PEELOUT_VAL_AT_ZER0;
            }

            if (whInfo.m_skidInfoCumulative > 0.05f)
            {
                whInfo.m_skidInfoCumulative -= 0.002f;
            }

            float deltaRotation = (gearShiftSpeed_[curGearIdx_] * (1.0f - whInfo.m_skidInfoCumulative) * timeStep) / (whInfo.m_wheelsRadius);

            if ( deltaRotation > whInfo.m_deltaRotation )
            {
                whInfo.m_rotation += deltaRotation - whInfo.m_deltaRotation;
                whInfo.m_deltaRotation = deltaRotation;
            }
        }
        else
        {
            whInfo.m_skidInfoCumulative = whInfo.m_skidInfo;

            if (!whInfo.m_raycastInfo.m_isInContact && currentAcceleration_ < M_EPSILON)
            {
                whInfo.m_rotation *= 0.95f;
                whInfo.m_deltaRotation *= 0.95f;
            }
        }

        // ground contact
        float whSlipVel = 0.0f;
        if ( whInfo.m_raycastInfo.m_isInContact )
        {
            numWheelContacts_++;

            // check side velocity slip
            whSlipVel = Abs(ToVector3(whInfo.m_raycastInfo.m_wheelAxleWS).DotProduct(linVel));

            if ( whSlipVel > MIN_SIDE_SLIP_VEL )
            {
                whInfo.m_skidInfoCumulative = (whInfo.m_skidInfoCumulative > 0.9f)?0.89f:whInfo.m_skidInfoCumulative;
            }
        }

        // wheel velocity from rotation
        // note (correct eqn): raycastVehicle_->GetLinearVelocity().Length() ~= whInfo.m_deltaRotation * whInfo.m_wheelsRadius)/timeStep
        wheelVelocity += (whInfo.m_deltaRotation * whInfo.m_wheelsRadius)/timeStep;
    }

    // set cur rpm based on wheel rpm
    int numPoweredWheels = raycastVehicle_->GetNumWheels();

    // adjust rpm based on wheel speed
    if (curGearIdx_ == 0 || numWheelContacts_ == 0)
    {
        // average wheel velocity
        wheelVelocity /= (float)numPoweredWheels;

        // physics velocity to kmh to mph (based on Bullet's calculation for KmH)
        wheelVelocity = wheelVelocity * 3.6f * KMH_TO_MPH;
        float wheelRPM = upShiftRPM_ * wheelVelocity / gearShiftSpeed_[curGearIdx_];

        if (curGearIdx_ == 0)
        {
            if ( wheelRPM > upShiftRPM_ * MAX_WHEEL_RPM )
            {
                wheelRPM = upShiftRPM_ * Random(MIN_WHEEL_RPM, MAX_WHEEL_RPM);
            }
        }
        else
        {
            if (playAccelerationSoundInAir_)
            {
                if (wheelRPM > upShiftRPM_ * MAX_WHEEL_RPM_AIR)
                {
                    wheelRPM = upShiftRPM_ * Random(MIN_WHEEL_RPM_AIR, MAX_WHEEL_RPM_AIR);
                }
            }
            else
            {
                wheelRPM = 0.0f;
            }
        }

        if ( wheelRPM > curRPM_ ) 
            curRPM_ = wheelRPM;

        if ( curRPM_ < MIN_IDLE_RPM ) 
            curRPM_ += minIdleRPM_;
    }
}

void Sled::PostUpdate(float timeStep)
{
    float curSpdMph = GetSpeedMPH();

	updatePowerupPicker(timeStep);

    for ( int i = 0; i < raycastVehicle_->GetNumWheels(); i++ )
    {
        btWheelInfo &whInfo = raycastVehicle_->GetWheelInfo( i );

        // update wheel transform - performed after whInfo.m_rotation is adjusted from above
        raycastVehicle_->UpdateWheelTransform( i, true );

        Vector3 v3Origin = raycastVehicle_->GetWheelPositionWS( i );
        Quaternion qRot = raycastVehicle_->GetWheelRotation( i );

        Node *pWheel = m_vpNodeWheel[ i ];
        pWheel->SetPosition( v3Origin );
       
        Vector3 v3PosLS = ToVector3( whInfo.m_chassisConnectionPointCS );
        Quaternion qRotator = ( v3PosLS.x_ >= 0.0 ? Quaternion(0.0f, 0.0f, -90.0f) : Quaternion(0.0f, 0.0f, 90.0f) );
        pWheel->SetRotation( qRot * qRotator );
    }

    // update sound and wheel effects
    //PostUpdateSound(timeStep);

    PostUpdateWheelEffects();
}

void Sled::UpdateSteering(float newSteering)
{
    // gradual change
    if ( newSteering != 0.0f )
    {
        steering_ += newSteering * m_fsteeringIncrement;
    }
    else
    {
        steering_ *= 0.90f;
    }

    steering_ = Clamp( steering_, -m_fsteeringClamp, m_fsteeringClamp );

    // angular velocity
    if ( Abs(steering_ ) > m_fsteeringClamp * 0.75f )
    {
        m_fYAngularVelocity += 0.2f;
    }
    else
    {
        m_fYAngularVelocity *= 0.98f;
    }

    m_fYAngularVelocity = Clamp(m_fYAngularVelocity, 2.0f, 4.0f);

    // apply value
    m_fVehicleSteering = steering_;

    for ( int i = 0; i < 2; ++i )
    {
        raycastVehicle_->SetSteeringValue( m_fVehicleSteering, i );
    }
}

void Sled::ApplyEngineForces(float accelerator, bool braking)
{
    // 4x wheel drive
    const float numDriveTrains = 2.0f;
    const float invNumDriveTrains = 1.0f/numDriveTrains;

    isBraking_ = braking;
    currentAcceleration_ = accelerator;
    m_fBreakingForce = braking?m_fmaxBreakingForce*0.5f:0.0f;
    m_fEngineForce = m_fmaxEngineForce * accelerator * invNumDriveTrains;
	m_fEngineForce += m_fEngineForce * _speedBoost;

    if (_speedBoost > 0) {
        node_->GetComponent<RibbonTrail>()->SetEmitting(true);
    }
    else {
        node_->GetComponent<RibbonTrail>()->SetEmitting(false);
    }

    for ( int i = 0; i < numWheels_; ++i )
    {
        raycastVehicle_->ApplyEngineForce( m_fEngineForce, i );

        // apply brake to rear wheels only
        if (i > 1)
        {
            raycastVehicle_->SetBrake(m_fBreakingForce, i);
        }
    }
}

bool Sled::ApplyStiction(float steering, float acceleration, bool braking)
{
    const float vel = raycastVehicle_->GetLinearVelocity().Length();
    const float absAccel = Abs(acceleration);
    const float absSteer = Abs(steering);
    bool setStiction = false;

    if ( absSteer < M_EPSILON && absAccel < M_EPSILON && 
         numWheelContacts_ > 0 && vel < MIN_STICTION_VEL )
    {
        setStiction = true;
    }

    // slow down and change rolling friction on stiction
    for ( int i = 0; i < numWheels_; ++i )
    {
        btWheelInfo &wheel = raycastVehicle_->GetWheelInfo( i );

        if ( absAccel < M_EPSILON && !braking && vel < MIN_SLOW_DOWN_VEL )
        {
            raycastVehicle_->SetBrake( MIN_BRAKE_FORCE, i );
        }

        if ( setStiction )
        {
            wheel.m_rollInfluence = Lerp(m_frollInfluence, 1.0f, 1.0f - vel/MIN_STICTION_VEL);
        }
        else
        {
            wheel.m_rollInfluence = m_frollInfluence;
        }
    }

    return setStiction;
}

void Sled::ApplyDownwardForce()
{
    // apply downward force when some wheels are grounded
    if ( numWheelContacts_ > 0 && numWheelContacts_ != numWheels_ )
    {
        // small arbitrary multiplier
        const float velocityMultiplyer = 0.5f;
        Vector3 downNormal = node_->GetUp() * -1.0f;
        float velocityMag = raycastVehicle_->GetLinearVelocity().LengthSquared() * velocityMultiplyer;
        velocityMag = Clamp( velocityMag, MIN_DOWN_FORCE, MAX_DOWN_FORCE );
        raycastVehicle_->ApplyForce( velocityMag * downNormal  );
    }
}

void Sled::AutoCorrectPitchRoll()
{
    // auto correct pitch and roll while air borne
    if ( numWheelContacts_ == 0 )
    {
        Vector3 fwdVec = node_->GetDirection();
        Vector3 rgtVec = node_->GetRight();
        Vector3 torque;
        // pitch - small arbitrary multiplier
        torque += rgtVec * fwdVec.DotProduct( Vector3::UP ) * 4.0f;
        // roll - small arbitrary multiplier
        torque += fwdVec * rgtVec.DotProduct( Vector3::UP ) * -1.0f;
        // total torque - small arbitrary multiplier
        torque = torque * raycastVehicle_->GetLinearVelocity().Length() * 2.0f;
		torque *= 0.1f;

        raycastVehicle_->ApplyTorque( torque );
    }
}

void Sled::LimitLinearAndAngularVelocity()
{
    // velocity limit
    Vector3 linVel = raycastVehicle_->GetLinearVelocity();
    if ( linVel.Length() > MAX_LINEAR_VEL_LIMIT )
    {
        raycastVehicle_->SetLinearVelocity( linVel.Normalized() * MAX_LINEAR_VEL_LIMIT );
    }

    // angular velocity limiters
    Vector3 v3AngVel = raycastVehicle_->GetAngularVelocity();
    v3AngVel.x_ = Clamp( v3AngVel.x_, -MAX_ANGULAR_VEL_LIMIT,  MAX_ANGULAR_VEL_LIMIT );
    v3AngVel.y_ = Clamp( v3AngVel.y_, -m_fYAngularVelocity,    m_fYAngularVelocity );
    v3AngVel.z_ = Clamp( v3AngVel.z_, -MAX_ANGULAR_VEL_LIMIT,  MAX_ANGULAR_VEL_LIMIT );
    raycastVehicle_->SetAngularVelocity( v3AngVel );
}

void Sled::UpdateGear()
{
    float curSpdMph = GetSpeedMPH();
    int gearIdx = 0;

    // no negative speed value
    if (curSpdMph < 0.0f) curSpdMph *= -1.0f;

    for ( int i = 0; i < (int)gearShiftSpeed_.Size()-1; ++i )
    {
        if (curSpdMph > gearShiftSpeed_[i])
        {
            gearIdx = i + 1;
        }
    }

    // up or down shift when a wheel is in contact with the ground
    if ( gearIdx != curGearIdx_ && numWheelContacts_ > 0 )
    {
        curRPM_ = upShiftRPM_ * curSpdMph/gearShiftSpeed_[curGearIdx_];

        if ( curRPM_ < downShiftRPM_ )
        {
            if (curGearIdx_ > 0)
            {
                curGearIdx_--;
            }
        }
        else if ( gearIdx > curGearIdx_ )
        {
            curGearIdx_++;
        }
    }

    // final rpm
    curRPM_ = upShiftRPM_ * curSpdMph / gearShiftSpeed_[curGearIdx_];

    if (curGearIdx_ == 0)
    {
        minIdleRPM_ = Random(1000.0f, 1025.0f);
        if ( curRPM_ < MIN_IDLE_RPM ) curRPM_ += minIdleRPM_;
    }
}

void Sled::UpdateDrift()
{
    // rear wheel slip condition values
    // -note1: these are rough constants, you may want to re-evaluate them
    // -note2: changes to center of mass and size of inertia change drift behavior
    const float slipConditon0 = 0.00f; // ice
    const float slipConditon1 = 0.01f; // wet pavement
    const float slipConditon2 = 0.02f; // loose dirt
    const float slipConditon3 = 0.04f; // dirt
    const float slipConditon4 = 0.06f; // pavement

    // set slip
    const float slipConditionValue = slipConditon4;
    const float slipMax = MAX_REAR_SLIP;
    
    // for demo purpose, limit the drift speed to provide high speed steering experience w/o any drifting
    const float maxDriftSpeed = 40.0f;
    const float absSteeringVal = Abs( raycastVehicle_->GetSteeringValue(0) );
    const float curSpdMph = GetSpeedMPH();

    // set rear wheel slip values
    for ( int i = 2; i < numWheels_; ++i )
    {
        // re-calc the slip value only once
        if (i == 2)
        {
            if ( currentAcceleration_ > 0.0f )
            {
                const float slipMin = (curSpdMph < maxDriftSpeed)?slipConditionValue:slipMax;
                const float slipAdj = Lerp(slipMax, slipMin, absSteeringVal/m_fsteeringClamp);
                float deltaSlip = slipAdj - m_fRearSlip;

                m_fRearSlip += deltaSlip * 0.05f;
                m_fRearSlip = Clamp(m_fRearSlip, slipConditionValue, slipMax);
            }
            else
            {
                m_fRearSlip = slipMax;
            }
        }

        // set value
        raycastVehicle_->GetWheelInfo(i).m_sideFrictionStiffness = m_fRearSlip;
    }
}

void Sled::PostUpdateSound(float timeStep)
{
    int playSkidSound = 0;
    bool playShockImpactSound = false;

    for ( int i = 0; i < numWheels_; ++i )
    {
        const btWheelInfo &whInfo = raycastVehicle_->GetWheelInfo(i);

        // skid sound
        if ( whInfo.m_raycastInfo.m_isInContact )
        {
            if (whInfo.m_skidInfoCumulative < 0.9f)
            {
                playSkidSound++;
            }

            // shock impact
            if ( !prevWheelInContact_[i] )
            {
                Vector3 velAtWheel = raycastVehicle_->GetVelocityAtPoint( raycastVehicle_->GetWheelPositionLS(i) );
                float downLinVel = velAtWheel.DotProduct( Vector3::DOWN );

                if ( downLinVel > MIN_SHOCK_IMPACT_VEL )
                {
                    playShockImpactSound = true;
                }
            }
        }

        // update prev wheel in contact
        prevWheelInContact_[i] = whInfo.m_raycastInfo.m_isInContact;
    }

    // -ideally, you want the engine sound to sound like it's at 10k rpm w/o any pitch adjustment, and 
    // we nomralize x to be from 0.1f to 1.0f by dividing by 10k in SetFrequency(AUDIO_FIXED_FREQ_44K * x)
    // -if shifting rmps sounds off then change the normalization value. for the engine prototype sound, 
    // the pitch sound is low, so it's normalized by diving by 8k instead of 10k
    const float rpmNormalizedForEnginePrototype = 8000.0f;
    engineSoundSrc_->SetFrequency(AUDIO_FIXED_FREQ_44K * curRPM_/rpmNormalizedForEnginePrototype);

    // shock impact when transitioning from partially off ground (or air borne) to landing
    if ( prevWheelContacts_ <= 2 && playShockImpactSound )
    {
        if ( !shockSoundSrc_->IsPlaying() )
        {
            shockSoundSrc_->Play(shockSnd_);
        }
    }

    // skid sound
    if ( playSkidSound > 1 )
    {
        if ( !skidSoundSrc_->IsPlaying() )
        {
            skidSoundSrc_->Play(skidSnd_);
        }
    }
    else
    {
        skidSoundSrc_->Stop();
    }
}

void Sled::PostUpdateWheelEffects()
{
    float curSpdMph = GetSpeedMPH();
    Vector3 linVel = raycastVehicle_->GetLinearVelocity();

    for ( int i = 0; i < 2/*raycastVehicle_->GetNumWheels()*/; ++i )
    {
        const btWheelInfo &whInfo = raycastVehicle_->GetWheelInfo( i );

        // wheel skid track and particles
        wheelTrackList_[i]->UpdateWorldPos();
        ParticleEmitter *particleEmitter = particleEmitterNodeList_[i]->GetComponent<ParticleEmitter>();

        if ( whInfo.m_raycastInfo.m_isInContact /*&& whInfo.m_skidInfoCumulative < 0.9f*/)
        {
            Vector3 pos2 = ToVector3(whInfo.m_raycastInfo.m_contactPointWS);
            particleEmitterNodeList_[i]->SetPosition(pos2);

            //if ( curSpdMph < MAX_SKID_TRACK_SPEED )
            //{
                wheelTrackList_[i]->AddStrip( pos2, ToVector3(whInfo.m_raycastInfo.m_contactNormalWS) );
            //}
            //else
           // {
                wheelTrackList_[i]->ClearStrip();
           // }

            // emit dust if moving
            if ( particleEmitter && !particleEmitter->IsEmitting() && curSpdMph > 10.0f)
            {
                particleEmitter->SetEmitting( true );
            }
            else {
                particleEmitter->SetEmitting(false);
            }
        }
        else
        {
            wheelTrackList_[i]->ClearStrip();

            if ( !wheelTrackList_[i]->InSkidState() && particleEmitter && particleEmitter->IsEmitting() )
            {
                particleEmitter->SetEmitting( false );
            }
        }
    }
}

void Sled::DebugDraw(const Color &color)
{
    DebugRenderer *dbgRenderer = GetScene()->GetComponent<DebugRenderer>();

    if ( dbgRenderer )
    {
        // draw compound shape bounding box (the inertia bbox)
        Vector3 localExtents = raycastVehicle_->GetCompoundLocalExtents();
        Vector3 localCenter  = raycastVehicle_->GetCompooundLocalExtentsCenter();
        BoundingBox bbox(-localExtents, localExtents);

        btTransform trans;
        raycastVehicle_->getWorldTransform(trans);
        Vector3 posWS = ToVector3(trans.getOrigin());
        Vector3 centerWS = ToQuaternion(trans.getRotation()) * localCenter;
        posWS += centerWS;
        Matrix3x4 mat34(posWS, ToQuaternion(trans.getRotation()), 1.0f);

        dbgRenderer->AddBoundingBox(bbox, mat34, color);
        dbgRenderer->AddLine(posWS, posWS + node_->GetUp(), color);
        dbgRenderer->AddLine(posWS, posWS + node_->GetRight(), color);
    }
}

void Sled::SetSledID(unsigned int id)
{
	_id = id;
}

unsigned int Sled::getSledID()
{
	return _id;
}

void Sled::setReady(bool val)
{
	//GetNode()->SetEnabled(val);
	raycastVehicle_->SetEnabled(val);
}

bool Sled::isReady()
{
	return raycastVehicle_->IsEnabled();
}

Node* Sled::getNode()
{
	return GetNode();
}

Component* Sled::getComponent()
{
    return this;
}

void Sled::HandleSpeedChange(StringHash eventType, VariantMap& eventData)
{
    int val = eventData[P_VALUE].GetInt();
    m_fmaxEngineForce = val;
}

void Sled::sendPredictedNodeIds()
{
    VariantMap map;
    map[P_NODE_ID] = node_->GetID();
    GetSubsystem<Network>()->BroadcastRemoteEvent(E_PREDICT_NODE_POSITION, true, map);
}

void Sled::HandleNodeCollision(StringHash eventType, VariantMap& eventData)
{
    using namespace NodeCollision;
    //URHO3D_LOGINFO("Collision detected!");
    if (!node_->GetChild("CollisionSound")) {
        int random = Random(4);
        ResourceCache* cache = GetSubsystem<ResourceCache>();
        Sound* sound;
        if (random == 0) {
            sound = cache->GetResource<Sound>("Sounds/Wood-Wood.wav");
        }
        else if(random == 1) {
            sound = cache->GetResource<Sound>("Sounds/Wood-Wood1.wav");
        }
        else if (random == 2) {
            sound = cache->GetResource<Sound>("Sounds/Wood-Wood2.wav");
        }
        else {
            sound = cache->GetResource<Sound>("Sounds/Wood-Wood3.wav");
        }
        
        Node* soundNode = node_->CreateChild("CollisionSound");
        SoundSource3D* soundSource = soundNode->CreateComponent<SoundSource3D>();
        soundSource->Play(sound);
        soundSource->SetAutoRemoveMode(REMOVE_NODE);
        soundSource->SetFrequency(sound->GetFrequency());
        soundSource->SetGain(0.2f);
        soundSource->SetDistanceAttenuation(1.0f, 100.0f, 4.0f);
    }
}