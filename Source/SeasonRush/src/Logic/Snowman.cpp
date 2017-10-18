#include <Urho3D/Urho3DAll.h>
#include "Logic/Snowman.h"

using namespace Urho3D;

static const int GAME_TIME = 300;//in seconds

Snowman::Snowman(Context* context) :
Urho3D::Object(context),
_scale(0.1)
{

}


Snowman::~Snowman()
{
}


void Snowman::RegisterObject(Context* context)
{
	context->RegisterFactory<Snowman>();
}

void Snowman::setScene(Scene* scene)
{
	_scene = scene;
}

void Snowman::setTerrain(Terrain* terrain)
{
	_terrain = terrain;
}

void Snowman::add(Vector3 pos)
{
	ResourceCache* cache = GetSubsystem<ResourceCache>();

	Node* node = _scene->CreateChild();
	pos.y_ = _terrain->GetHeight(pos);
	pos = _terrain->GetNode()->GetWorldRotation() * pos;
	node->SetWorldPosition(pos);
	StaticModel* hullObject = node->CreateComponent<StaticModel>();
	Model* model = cache->GetResource<Model>("Models/christmas/snowman.mdl");
	hullObject->SetModel(model);
	node->SetScale(Vector3(0.1f + Random(1.0f), 0.1f + Random(1.0f), 0.1f + Random(1.0f)));
	/*hullObject->SetMaterial(0, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(1, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(2, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(3, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(4, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(5, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(6, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(7, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(8, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(9, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(10, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(11, cache->GetResource<Material>("Materials/Snow.xml"));
	hullObject->SetMaterial(12, cache->GetResource<Material>("Materials/Snow.xml"));*/
	node->SetScale(Vector3(4, 4, 4));

	RigidBody* _rigidBody = node->CreateComponent<RigidBody>(LOCAL);
	CollisionShape* hullColShape = node->CreateComponent<CollisionShape>(LOCAL);

	hullColShape->SetConvexHull(hullObject->GetModel());
	node->SetScale(Vector3(1, 1, 1) * _scale);

	_rigidBody->SetMass(0);
	_rigidBody->SetRestitution(0);
	_rigidBody->SetFriction(1.0);
}
