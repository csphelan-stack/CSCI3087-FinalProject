audio_stop_sound(snd_game_music);
audio_stop_sound(snd_menu_music);
audio_stop_sound(snd_death_music);
audio_stop_sound(snd_new_room_music);
audio_stop_sound(snd_small_boss_music);
if (!audio_is_playing(snd_boss_music)) {
    audio_play_sound(snd_boss_music, 10, true);
}