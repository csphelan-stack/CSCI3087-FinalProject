audio_stop_sound(snd_game_music);
audio_stop_sound(snd_menu_music);
audio_stop_sound(snd_death_music);
if (!audio_is_playing(Boss_Music)) {
    audio_play_sound(Boss_Music, 10, true);
}