#pragma once

#include <Urho3D/Input/Controls.h>
#include <Urho3D/Scene/LogicComponent.h>
#include "Logic/Vehicles/Offroad/RaycastVehicle.h"
#include "Logic/Vehicles/PowerupPicker.h"
#include "Logic/Vehicles/DriveableObject.h"
#include "Logic/Vehicles/CheckpointPicker.h"

namespace Urho3D
{
	class Constraint;
	class Node;
	class RigidBody;
	class SoundSource3D;
}

namespace Offroad {

	using namespace Urho3D;
	using namespace Offroad;

	class WheelTrackModel;
	class RaycastVehicle;

#define KMH_TO_MPH              (1.0f/1.60934f)

	class Sled : public LogicComponent, public PowerupPicker, public DriveableObject, public CheckpointPicker
	{
		URHO3D_OBJECT(Sled, LogicComponent)

	public:
		/// Construct.
		Sled(Context* context);
		~Sled();

		/// Register object factory and attributes.
		static void RegisterObject(Context* context);

		/// Perform post-load after deserialization. Acquire the components from the scene nodes.
		virtual void ApplyAttributes();

		/// Initialize the vehicle. Create rendering and physics components. Called by the application.
		void Init();

		/// Handle physics world update. Called by LogicComponent base class.
		virtual void FixedUpdate(float timeStep);
		virtual void FixedPostUpdate(float timeStep);
		virtual void PostUpdate(float timeStep);

		void ResetForces()
		{
			raycastVehicle_->ResetForces();
			raycastVehicle_->SetAngularVelocity(Vector3::ZERO);
		}

		float GetSpeedKmH() const { return raycastVehicle_->GetCurrentSpeedKmHour(); }
		float GetSpeedMPH() const { return raycastVehicle_->GetCurrentSpeedKmHour()*KMH_TO_MPH; }
		void SetDbgRender(bool enable) { dbgRender_ = enable; }
		int GetCurrentGear() const { return curGearIdx_; }
		float GetCurrentRPM() const { return curRPM_; }

		void DebugDraw(const Color &color);

		/// Movement controls.
		Controls controls_;

		Node* getNode();
        virtual Component* getComponent();

		void SetSledID(unsigned int id);
		unsigned int getSledID();

		/**
		 * Enable/Disable node
		 */
		void setReady(bool val);

		bool isReady();

        void sendPredictedNodeIds();

	protected:
		void UpdateSteering(float newSteering);
		void ApplyEngineForces(float accelerator, bool braking);
		bool ApplyStiction(float steering, float acceleration, bool braking);
		void ApplyDownwardForce();
		void AutoCorrectPitchRoll();
		void UpdateGear();
		void UpdateDrift();
		void LimitLinearAndAngularVelocity();
		void PostUpdateSound(float timeStep);
		void PostUpdateWheelEffects();

	protected:
		unsigned int _id;

		WeakPtr<RaycastVehicle> raycastVehicle_;

		/// Current left/right steering amount (-1 to 1.)
		float steering_;

		// IDs of the wheel scene nodes for serialization.
		Vector<Node*>           m_vpNodeWheel;

		float   m_fVehicleMass;
		float   m_fEngineForce;
		float   m_fBreakingForce;

		float   m_fmaxEngineForce;
		float   m_fmaxBreakingForce;

		float   m_fVehicleSteering;
		float   m_fsteeringIncrement;
		float   m_fsteeringClamp;
		float   m_fwheelRadius;
		float   m_fwheelWidth;
		float   m_fwheelFriction;
		float   m_fsuspensionStiffness;
		float   m_fsuspensionDamping;
		float   m_fsuspensionCompression;
		float   m_frollInfluence;
		float   m_fsuspensionRestLength;

		// slip vars
		float   m_fMaxSteering;
		float   m_fsideFrictionStiffness;
		float   m_fRearSlip;

		Vector3 centerOfMassOffset_;

		// acceleration
		float currentAcceleration_;

		// ang velocity limiter
		float   m_fYAngularVelocity;

		// wheel contacts
		int numWheels_;
		int numWheelContacts_;
		int prevWheelContacts_;
		bool isBraking_;
		PODVector<float> gearShiftSpeed_;
		PODVector<bool>  prevWheelInContact_;

		// gears
		float downShiftRPM_;
		float upShiftRPM_;
		int numGears_;
		int curGearIdx_;
		float curRPM_;
		float minIdleRPM_;

		// sound
		SharedPtr<Sound>         engineSnd_;
		SharedPtr<Sound>         skidSnd_;
		SharedPtr<Sound>         shockSnd_;
		SharedPtr<SoundSource3D> engineSoundSrc_;
		SharedPtr<SoundSource3D> skidSoundSrc_;
		SharedPtr<SoundSource3D> shockSoundSrc_;
		bool                     playAccelerationSoundInAir_;

		// wheel effects - skid track and particles
		SharedPtr<WheelTrackModel> wheelTrackList_[4];
		Vector<Node*>              particleEmitterNodeList_;

		// dbg render
		bool dbgRender_;

        void HandleSpeedChange(StringHash eventType, VariantMap& eventData);

        void HandleNodeCollision(StringHash eventType, VariantMap& eventData);
	};
}
