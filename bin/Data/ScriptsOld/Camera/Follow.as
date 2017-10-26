void FollowCharacter(Node@ camNode, Node@ characterNode, float timestep)
{
    Vector3 characterPosition = characterNode.position;
    Vector3 cameraPosition = camNode.position;
    int diffX = characterPosition.x - cameraPosition.x;
    // if (Abs(diffX) > 2) {
        // float moveX = diffX;// * timestep * 10;
        // if (Abs(moveX) > Abs(diffX)) {
        //     moveX = diffX;
        // }
        // cameraPosition.x += moveX;
        camNode.position = characterPosition;
    // }

    // int diffY = characterPosition.y - cameraPosition.y;
    // if (Abs(diffY) > 1) {
    //     float moveY = diffY;// * timestep * 10;
    //     if (Abs(moveY) > Abs(diffY)) {
    //         moveY = diffY;
    //     }
    //     cameraPosition.y += moveY;
    //     camNode.position = characterPosition;
    // }
    
}