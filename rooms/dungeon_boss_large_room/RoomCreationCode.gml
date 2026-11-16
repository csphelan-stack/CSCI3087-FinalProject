audio_stop_sound(snd_game_music);
audio_stop_sound(snd_menu_music);
audio_stop_sound(snd_death_music);
if (!audio_is_playing(snd_boss_music)) {
    audio_play_sound(snd_boss_music, 10, true);
}