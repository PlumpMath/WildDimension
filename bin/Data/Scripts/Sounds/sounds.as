namespace GameSounds {
    const String HIT_SNAKE = "Sounds/PlayerFistHit.wav";
    const String HIT_PACMAN = "Sounds/PlayerFistHit.wav";
    const String HIT_TREE = "Sounds/PlayerLand.wav";
    const String PICKUP_TOOL = "Sounds/Powerup.wav";
    const String HIT_FOOD = "Sounds/NutThrow.wav";

    void Play(String soundName)
    {
        // Get the sound resource
        Sound@ sound = cache.GetResource("Sound", soundName);

        if (sound !is null)
        {
            // Create a SoundSource component for playing the sound. The SoundSource component plays
            // non-positional audio, so its 3D position in the scene does not matter. For positional sounds the
            // SoundSource3D component would be used instead
            SoundSource@ soundSource = cameraNode.CreateComponent("SoundSource");
            soundSource.autoRemoveMode = REMOVE_COMPONENT;
            soundSource.Play(sound);
            // In case we also play music, set the sound volume below maximum so that we don't clip the output
            soundSource.gain = 0.7f;
        }
    }
}