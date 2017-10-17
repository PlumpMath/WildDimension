void FollowCharacter(Node@ camNode, Node@ characterNode, float timestep)
{
    Vector3 characterPosition = characterNode.position;
    Vector3 cameraPosition = camNode.position;
    int diffX = characterPosition.x - cameraPosition.x;
    if (Abs(diffX) > 2) {
        cameraPosition.x += diffX * timestep;
        camNode.position = cameraPosition;
    }

    int diffY = characterPosition.y - cameraPosition.y;
    if (Abs(diffY) > 1) {
        cameraPosition.y += diffY * timestep;
        camNode.position = cameraPosition;
    }
    
}