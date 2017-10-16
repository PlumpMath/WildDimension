void FollowCharacter(Node@ camNode, Node@ characterNode, float timestep)
{
    Vector3 characterPosition = characterNode.position;
    Vector3 cameraPosition = camNode.position;
    int diff = characterPosition.x - cameraPosition.x;
    if (Abs(diff) > 2) {
        cameraPosition.x += diff * timestep;
        camNode.position = cameraPosition;
    }
}