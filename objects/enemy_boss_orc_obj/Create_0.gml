// ============================================================
// ORC WARCHIEF - CREATE
// ============================================================
// the orc boss. big, slow and brutal. uses BLOOD magic.
//   normal attack : a heavy sword swing
//   normal magic  : "Blood Thorns"  - three circles around the player (a pincer)
//   area magic    : "Blood Moon"    - a huge circle on the player, thorns everywhere
//   dodge / parry : "Bloodcharge"   - a red lane fills up, then he charges down it
// ============================================================

sprite_index = boss_orc_idle_forward_spr;

event_inherited();

boss_name    = "Orc Warchief";
boss_accent  = make_colour_rgb(225, 40, 52);
boss_element = MAGIC_ELEMENT.BLOOD;

// ---------- stats ----------
total_hp        = 220;
hp              = total_hp;
movespd         = 1.15;
attack_damage   = 7;       // the normal swing. the other attacks are multiples of this
attack_range    = 78;      // how close the player has to be for the normal swing

// ---------- sprites ----------
spr_idle = [
    boss_orc_idle_right_spr,
    boss_orc_idle_backward_spr,
    boss_orc_idle_left_spr,
    boss_orc_idle_forward_spr
];

spr_run = [
    boss_orc_walk_right_spr,
    boss_orc_walk_backward_spr,
    boss_orc_walk_left_spr,
    boss_orc_walk_forward_spr
];

spr_attack = [
    boss_orc_attack_right_spr,
    boss_orc_attack_backward_spr,
    boss_orc_attack_left_spr,
    boss_orc_attack_forward_spr
];

spr_hurt = [
    boss_orc_hurt_right_spr,
    boss_orc_hurt_backward_spr,
    boss_orc_hurt_left_spr,
    boss_orc_hurt_forward_spr
];

spr_death = [
    boss_orc_death_right_spr,
    boss_orc_death_backward_spr,
    boss_orc_death_left_spr,
    boss_orc_death_forward_spr
];

// used while charging
spr_special = [
    boss_orc_run_right_spr,
    boss_orc_run_backward_spr,
    boss_orc_run_left_spr,
    boss_orc_run_forward_spr
];

// ---------- attacks ----------
// windup = frames until it goes off      total = frames the whole attack lasts
// cd     = frames before it can be used again
// hold / strike / delay = animation settings (see enemy_boss_anim_frame)
// range_min / range_max = how far away the player can be for the boss to use it

// the normal attack: a heavy swing
boss_cfg[BOSS_ATTACK.MELEE] = {
    windup: 26, total: 58, cd: 36,
    hold: -1, strike: 3, delay: 0, spr: spr_attack,
    range_min: 0, range_max: 0
};

// the normal magic: blood thorns in a pincer around the player
boss_cfg[BOSS_ATTACK.MAGIC] = {
    windup: 56, total: 108, cd: 150,
    hold: 1, strike: 3, delay: 8, spr: spr_attack,
    range_min: 0, range_max: 260,
    count: 3, gap: 16, pattern: "triangle"
};

// the big magic: Blood Moon, a huge circle on the player
boss_cfg[BOSS_ATTACK.AREA] = {
    windup: 92, total: 168, cd: 560,
    hold: 1, strike: 3, delay: 8, spr: spr_attack,
    range_min: 0, range_max: 240,
    centre: "player", radius: 122, burst_count: 18, burst_spread: 30,
    hit_delay: 12, ticks: 1, tick_gap: 30
};

// dodge or parry: Bloodcharge. the red lane fills, then he rushes down it
boss_cfg[BOSS_ATTACK.SPECIAL] = {
    windup: 58, total: 128, cd: 420,
    hold: 1, strike: 3, delay: 0, spr: spr_attack,
    range_min: 40, range_max: 300,
    type: "charge", speed: 9.2, charge_time: 26, mult: 2.6, hit_radius: 34,
    tele_length: 270, tele_width: 68
};

// Start the fight (full health, opening cooldowns, chasing the player).
enemy_boss_start();
