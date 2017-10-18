#pragma once
#include "Urho3D/Urho3DAll.h"
#include <vector>

using namespace Urho3D;

class Snowman : public Urho3D::Object
{
private:
	/**
	 * Checkpoint positions
	 */
	std::vector<SharedPtr<Node>> _snowmans;

	SharedPtr<Scene> _scene;

	SharedPtr<Terrain> _terrain;

	float _scale;

public:
	Snowman(Context* context);
	~Snowman();

	static void RegisterObject(Context* context);

	void setScene(Scene* scene);

	void setTerrain(Terrain* terrain);

	/**
	 * Add new checkpoint to the map
	 */
	void add(Vector3 pos);

	URHO3D_OBJECT(Snowman, Urho3D::Object);
};
