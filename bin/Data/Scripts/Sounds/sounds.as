namespace GameSounds {
    const String HIT_SNAKE = "Sounds/PlayerFistHit.wav";
    const String HIT_PACMAN = "Sounds/PlayerFistHit.wav";
    const String HIT_TREE = "Sounds/PlayerLand.wav";
    const String PICKUP_TOOL = "Sounds/Powerup.wav";
    const String HIT_FOOD = "Sounds/NutThrow.wav";
    const String AMBIENT_SOUND = "Sounds/outside.wav";
    const String ACHIEVEMENT_UNLOCKED = "Sounds/achievement.wav";
    const String WALK = "Sounds/walk.wav";
    const String JUMP = "Sounds/jump.wav";
    const String MISSION_COMPLETE = "Sounds/mission_complete.wav";
    const String SNAKE = "Sounds/snake.wav";
    const String PACMAN = "Sounds/pacman.wav";

    void Play(String soundName)
    {
        // Get the sound resource
        Sound@ sound = cache.GetResource("Sound", soundName);

        if (sound !is null) {
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

    void PlayAmbient(String soundName)
    {
        Sound@ sound = cache.GetResource("Sound", soundName);

        if (sound !is null) {
            sound.looped = true;
            // Create a SoundSource component for playing the sound. The SoundSource component plays
            // non-positional audio, so its 3D position in the scene does not matter. For positional sounds the
            // SoundSource3D component would be used instead
            SoundSource@ soundSource = cameraNode.CreateComponent("SoundSource");
            soundSource.autoRemoveMode = REMOVE_COMPONENT;
            soundSource.Play(sound);
            soundSource.soundType = SOUND_MUSIC;
            // In case we also play music, set the sound volume below maximum so that we don't clip the output
            soundSource.gain = 0.7f;
        }
    }

    void AddLoopedSoundToNode(Node@ node, String soundName)
    {
        Sound@ sound = cache.GetResource("Sound", soundName);

        if (sound !is null) {
            sound.looped = true;
            // Create a SoundSource component for playing the sound. The SoundSource component plays
            // non-positional audio, so its 3D position in the scene does not matter. For positional sounds the
            // SoundSource3D component would be used instead
            SoundSource3D@ soundSource = node.CreateComponent("SoundSource3D");
            //soundSource.autoRemoveMode = REMOVE_COMPONENT;
            soundSource.Play(sound);
            //soundSource.SetDistanceAttenuation(1, 100, 0.1);
            soundSource.SetDistanceAttenuation(1.0f, 50.0f, 5.0f);
            //soundSource.soundType = SOUND_MUSIC;
            // In case we also play music, set the sound volume below maximum so that we don't clip the output
            soundSource.gain = 0.7f;
        }
    }
}