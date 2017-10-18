#pragma once
#include "Urho3D/Urho3DAll.h"
#include <vector>

using namespace Urho3D;

class Trees : public Urho3D::Component
{
private:
	Vector<SharedPtr<Node>> _trees;

	SharedPtr<Scene> _scene;

	SharedPtr<Terrain> _terrain;

	float _scale;

    void setCollision(Node* node, bool enabled);
public:
	Trees(Context* context);
	~Trees();

	static void RegisterObject(Context* context);

	void setScene(Scene* scene);

	void setTerrain(Terrain* terrain);

	void add(Vector3 pos, bool enableCollision = false);


    void HandleTreeColissionChange(StringHash eventType, VariantMap& eventData);

	URHO3D_OBJECT(Trees, Urho3D::Component);
};
