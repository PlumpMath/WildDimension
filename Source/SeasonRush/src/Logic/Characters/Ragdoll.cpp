#include <Urho3D/Graphics/AnimatedModel.h>
#include <Urho3D/IO/Log.h>
#include <Urho3D/Physics/PhysicsEvents.h>
#include <Urho3D/Physics/RigidBody.h>

#include "Logic/Characters/Ragdoll.h"
#include "Logic/Characters/RagdollClean.h"
#include <Urho3D/Urho3DAll.h>

#include <Urho3D/DebugNew.h>

Ragdoll::Ragdoll(Context* context) :
	Component(context)
{
}

void Ragdoll::RegisterObject(Context* context)
{
	context->RegisterFactory<Ragdoll>();
    context->RegisterFactory<RagdollClean>();
}

void Ragdoll::OnNodeSet(Node* node)
{
	// If the node pointer is non-null, this component has been created into a scene node. Subscribe to physics collisions that
	// concern this scene node
	if (node)
		SubscribeToEvent(node, E_NODECOLLISION, URHO3D_HANDLER(Ragdoll, HandleNodeCollision));
}

void Ragdoll::HandleNodeCollision(StringHash eventType, VariantMap& eventData)
{
	using namespace NodeCollision;

	// Get the other colliding body, make sure it is moving (has nonzero mass)
	RigidBody* otherBody = static_cast<RigidBody*>(eventData[P_OTHERBODY].GetPtr());

    if (otherBody->GetMass() > 0.0f)
	{
		// We do not need the physics components in the AnimatedModel's root scene node anymore
		node_->RemoveComponent<RigidBody>();
		node_->RemoveComponent<CollisionShape>();

		// Create RigidBody & CollisionShape components to bones
		CreateRagdollBone("Bip01_Pelvis", SHAPE_BOX, Vector3(0.3f, 0.2f, 0.25f), Vector3(0.0f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 0.0f));
		CreateRagdollBone("Bip01_Spine1", SHAPE_BOX, Vector3(0.35f, 0.2f, 0.3f), Vector3(0.15f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 0.0f));
		CreateRagdollBone("Bip01_L_Thigh", SHAPE_CAPSULE, Vector3(0.175f, 0.45f, 0.175f), Vector3(0.25f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 90.0f));
		CreateRagdollBone("Bip01_R_Thigh", SHAPE_CAPSULE, Vector3(0.175f, 0.45f, 0.175f), Vector3(0.25f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 90.0f));
		CreateRagdollBone("Bip01_L_Calf", SHAPE_CAPSULE, Vector3(0.15f, 0.55f, 0.15f), Vector3(0.25f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 90.0f));
		CreateRagdollBone("Bip01_R_Calf", SHAPE_CAPSULE, Vector3(0.15f, 0.55f, 0.15f), Vector3(0.25f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 90.0f));
		CreateRagdollBone("Bip01_Head", SHAPE_BOX, Vector3(0.2f, 0.2f, 0.2f), Vector3(0.1f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 0.0f));
		CreateRagdollBone("Bip01_L_UpperArm", SHAPE_CAPSULE, Vector3(0.15f, 0.35f, 0.15f), Vector3(0.1f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 90.0f));
		CreateRagdollBone("Bip01_R_UpperArm", SHAPE_CAPSULE, Vector3(0.15f, 0.35f, 0.15f), Vector3(0.1f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 90.0f));
		CreateRagdollBone("Bip01_L_Forearm", SHAPE_CAPSULE, Vector3(0.125f, 0.4f, 0.125f), Vector3(0.2f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 90.0f));
		CreateRagdollBone("Bip01_R_Forearm", SHAPE_CAPSULE, Vector3(0.125f, 0.4f, 0.125f), Vector3(0.2f, 0.0f, 0.0f),
			Quaternion(0.0f, 0.0f, 90.0f));

		// Create Constraints between bones
		CreateRagdollConstraint("Bip01_L_Thigh", "Bip01_Pelvis", CONSTRAINT_CONETWIST, Vector3::BACK, Vector3::FORWARD,
			Vector2(45.0f, 45.0f), Vector2::ZERO);
		CreateRagdollConstraint("Bip01_R_Thigh", "Bip01_Pelvis", CONSTRAINT_CONETWIST, Vector3::BACK, Vector3::FORWARD,
			Vector2(45.0f, 45.0f), Vector2::ZERO);
		CreateRagdollConstraint("Bip01_L_Calf", "Bip01_L_Thigh", CONSTRAINT_HINGE, Vector3::BACK, Vector3::BACK,
			Vector2(90.0f, 0.0f), Vector2::ZERO);
		CreateRagdollConstraint("Bip01_R_Calf", "Bip01_R_Thigh", CONSTRAINT_HINGE, Vector3::BACK, Vector3::BACK,
			Vector2(90.0f, 0.0f), Vector2::ZERO);
		CreateRagdollConstraint("Bip01_Spine1", "Bip01_Pelvis", CONSTRAINT_HINGE, Vector3::FORWARD, Vector3::FORWARD,
			Vector2(45.0f, 0.0f), Vector2(-10.0f, 0.0f));
		CreateRagdollConstraint("Bip01_Head", "Bip01_Spine1", CONSTRAINT_CONETWIST, Vector3::LEFT, Vector3::LEFT,
			Vector2(0.0f, 30.0f), Vector2::ZERO);
		CreateRagdollConstraint("Bip01_L_UpperArm", "Bip01_Spine1", CONSTRAINT_CONETWIST, Vector3::DOWN, Vector3::UP,
			Vector2(45.0f, 45.0f), Vector2::ZERO, false);
		CreateRagdollConstraint("Bip01_R_UpperArm", "Bip01_Spine1", CONSTRAINT_CONETWIST, Vector3::DOWN, Vector3::UP,
			Vector2(45.0f, 45.0f), Vector2::ZERO, false);
		CreateRagdollConstraint("Bip01_L_Forearm", "Bip01_L_UpperArm", CONSTRAINT_HINGE, Vector3::BACK, Vector3::BACK,
			Vector2(90.0f, 0.0f), Vector2::ZERO);
		CreateRagdollConstraint("Bip01_R_Forearm", "Bip01_R_UpperArm", CONSTRAINT_HINGE, Vector3::BACK, Vector3::BACK,
			Vector2(90.0f, 0.0f), Vector2::ZERO);

		// Disable keyframe animation from all bones so that they will not interfere with the ragdoll
		AnimatedModel* model = GetComponent<AnimatedModel>();
		Skeleton& skeleton = model->GetSkeleton();
		for (unsigned i = 0; i < skeleton.GetNumBones(); ++i)
			skeleton.GetBone(i)->animated_ = false;

        GetNode()->CreateComponent<RagdollClean>();
        //GetScene()->AddChild(GetNode());
        //GetNode()->SetPosition(GetNode()->GetParent()->GetPosition());
		// Finally remove self from the scene node. Note that this must be the last operation performed in the function
		Remove();
	}
}

void Ragdoll::CreateRagdollBone(const String& boneName, ShapeType type, const Vector3& size, const Vector3& position,
	const Quaternion& rotation)
{
	// Find the correct child scene node recursively
	Node* boneNode = node_->GetChild(boneName, true);
	if (!boneNode)
	{
		URHO3D_LOGWARNING("Could not find bone " + boneName + " for creating ragdoll physics components");
		return;
	}

	RigidBody* body = boneNode->CreateComponent<RigidBody>();
   
	// Set mass to make movable
	body->SetMass(5.0f);
	// Set damping parameters to smooth out the motion
	body->SetLinearDamping(0.1f);
	body->SetAngularDamping(0.2f);
	// Set rest thresholds to ensure the ragdoll rigid bodies come to rest to not consume CPU endlessly
	body->SetLinearRestThreshold(0.5f);
	body->SetAngularRestThreshold(0.5f);
	body->SetFriction(1.0);

	CollisionShape* shape = boneNode->CreateComponent<CollisionShape>();
	// We use either a box or a capsule shape for all of the bones
	if (type == SHAPE_BOX)
		shape->SetBox(size, position, rotation);
	else
		shape->SetCapsule(size.x_, size.y_, position, rotation);
}

void Ragdoll::CreateRagdollConstraint(const String& boneName, const String& parentName, ConstraintType type,
	const Vector3& axis, const Vector3& parentAxis, const Vector2& highLimit, const Vector2& lowLimit,
	bool disableCollision)
{
	Node* boneNode = node_->GetChild(boneName, true);
	Node* parentNode = node_->GetChild(parentName, true);
	if (!boneNode)
	{
		URHO3D_LOGWARNING("Could not find bone " + boneName + " for creating ragdoll constraint");
		return;
	}
	if (!parentNode)
	{
		URHO3D_LOGWARNING("Could not find bone " + parentName + " for creating ragdoll constraint");
		return;
	}

	Constraint* constraint = boneNode->CreateComponent<Constraint>();
	constraint->SetConstraintType(type);
	// Most of the constraints in the ragdoll will work better when the connected bodies don't collide against each other
	constraint->SetDisableCollision(disableCollision);
	// The connected body must be specified before setting the world position
	constraint->SetOtherBody(parentNode->GetComponent<RigidBody>());
	// Position the constraint at the child bone we are connecting
	constraint->SetWorldPosition(boneNode->GetWorldPosition());
	// Configure axes and limits
	constraint->SetAxis(axis);
	constraint->SetOtherAxis(parentAxis);
	constraint->SetHighLimit(highLimit);
	constraint->SetLowLimit(lowLimit);
}