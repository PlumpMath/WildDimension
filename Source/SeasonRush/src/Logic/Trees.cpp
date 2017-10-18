#include <Urho3D/Urho3DAll.h>
#include "Logic/Trees.h"
#include "Events.h"

using namespace Urho3D;

static const int GAME_TIME = 300;//in seconds

Trees::Trees(Context* context) :
Urho3D::Component(context),
_scale(0.5f)
{
    SubscribeToEvent(E_AI_TOGGLE_TREE_COLLISION, URHO3D_HANDLER(Trees, HandleTreeColissionChange));
}


Trees::~Trees()
{
}


void Trees::RegisterObject(Context* context)
{
	context->RegisterFactory<Trees>();
}

void Trees::setScene(Scene* scene)
{
	_scene = scene;
}

void Trees::setTerrain(Terrain* terrain)
{
	_terrain = terrain;
}

void Trees::add(Vector3 pos, bool enableCollision)
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();

	Node* node = _scene->CreateChild();
    
    NetworkPriority* np = node->CreateComponent<NetworkPriority>();
    np->SetDistanceFactor(1.0f);
    np->SetBasePriority(50);

	pos.y_ = _terrain->GetHeight(pos);
    //_terrain->GetNode()->GetWorldRotation().EulerAngles();
	pos = _terrain->GetNode()->GetWorldRotation() * pos;
    //pos.y_ -= 0.5f;
	node->SetPosition(pos);
    //node->SetWorldRotation(_terrain->GetNode()->GetWorldRotation());
	StaticModel* hullObject = node->CreateComponent<StaticModel>();
	Model* model = cache->GetResource<Model>("Models/christmas/tree.mdl");
	hullObject->SetModel(model);
    hullObject->SetCastShadows(true);
	hullObject->SetMaterial(0, cache->GetResource<Material>("Materials/Tree.xml"));
	hullObject->SetMaterial(1, cache->GetResource<Material>("Materials/TreeBottom.xml"));

	hullObject->SetDrawDistance(1500.0f);

	node->SetScale(Vector3(1, 1, 1) * _scale * Random(0.5f, 1.5f));

    setCollision(node, enableCollision);

    _trees.Push(SharedPtr<Node>(node));
}

void Trees::setCollision(Node* node, bool enabled)
{
    if (enabled) {
        if (!node->HasComponent<RigidBody>()) {
            RigidBody* _rigidBody = node->CreateComponent<RigidBody>(LOCAL);
            CollisionShape* hullColShape = node->CreateComponent<CollisionShape>(LOCAL);

            hullColShape->SetCylinder(2.2, 14);
            hullColShape->SetPosition(Vector3(0, 7, 0));

            _rigidBody->SetMass(0);
            _rigidBody->SetRestitution(0);
            _rigidBody->SetFriction(1.0);
        }
    }
    else {
        if (node->HasComponent<RigidBody>()) {
            node->RemoveComponent<RigidBody>();
        }
        if (node->HasComponent<CollisionShape>()) {
            node->RemoveComponent<CollisionShape>();
        }
    }
}

void Trees::HandleTreeColissionChange(StringHash eventType, VariantMap& eventData)
{
    URHO3D_LOGRAW("Changing tree collisions");
    bool collisionEnabled = false;
    if (eventData.Contains(P_VALUE)) {
        collisionEnabled = eventData[P_VALUE].GetBool();
    }

    for (auto it = _trees.Begin(); it != _trees.End(); ++it) {
        Node* tree = (*it);
        setCollision(tree, collisionEnabled);
    }
}