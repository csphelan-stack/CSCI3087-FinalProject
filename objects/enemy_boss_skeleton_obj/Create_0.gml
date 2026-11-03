// ============================================================
// SKELETON FROST KING - CREATE
// ============================================================
// the skeleton boss. cold and precise. uses ICE magic.
//   normal attack : a scythe swing
//   normal magic  : "Frost Trail"    - a line of circles racing toward the player
//   area magic    : "Frost Field"    - a huge circle around the king himself
//   dodge / parry : "Crescent Wave"  - a lane shows his aim, then a frost wave flies
// ============================================================

sprite_index = boss_skeleton_idle_forward_spr;

event_inherited();

boss_name    = "Skeleton Frost King";
boss_accent  = make_colour_rgb(110, 205, 255);
boss_element = MAGIC_ELEMENT.ICE;

// ---------- stats ----------
total_hp        = 200;
hp              = total_hp;
movespd         = 1.0;
attack_damage   = 6;       // the normal swing. the other attacks are multiples of this
attack_range    = 84;      // how close the player has to be for the normal swing

// ---------- sprites ----------
spr_idle = [
    boss_skeleton_idle_right_spr,
    boss_skeleton_idle_backward_spr,
    boss_skeleton_idle_left_spr,
    boss_skeleton_idle_forward_spr
];

spr_run = [
    boss_skeleton_walk_right_spr,
    boss_skeleton_walk_backward_spr,
    boss_skeleton_walk_left_spr,
    boss_skeleton_walk_forward_spr
];

spr_attack = [
    boss_skeleton_attack_right_spr,
    boss_skeleton_attack_backward_spr,
    boss_skeleton_attack_left_spr,
    boss_skeleton_attack_forward_spr
];

spr_hurt = [
    boss_skeleton_hurt_right_spr,
    boss_skeleton_hurt_backward_spr,
    boss_skeleton_hurt_left_spr,
    boss_skeleton_hurt_forward_spr
];

spr_death = [
    boss_skeleton_death_right_spr,
    boss_skeleton_death_backward_spr,
    boss_skeleton_death_left_spr,
    boss_skeleton_death_forward_spr
];

// (only the orc charges, so this is just a safe default)
spr_special = [
    boss_skeleton_attack_right_spr,
    boss_skeleton_attack_backward_spr,
    boss_skeleton_attack_left_spr,
    boss_skeleton_attack_forward_spr
];

// ---------- attacks (see the orc boss for what each setting means) ----------

// the normal attack: a scythe swing
boss_cfg[BOSS_ATTACK.MELEE] = {
    windup: 28, total: 62, cd: 36,
    hold: -1, strike: 3, delay: 0, spr: spr_attack,
    range_min: 0, range_max: 0
};

// the normal magic: a trail of frost circles from the king to the player
boss_cfg[BOSS_ATTACK.MAGIC] = {
    windup: 54, total: 104, cd: 140,
    hold: 2, strike: 3, delay: 6, spr: spr_attack,
    range_min: 0, range_max: 260,
    count: 3, gap: 14, pattern: "line"
};

// the big magic: Frost Field, a huge circle around the king (run away from him!)
boss_cfg[BOSS_ATTACK.AREA] = {
    windup: 96, total: 170, cd: 600,
    hold: 2, strike: 3, delay: 6, spr: spr_attack,
    range_min: 0, range_max: 160,
    centre: "boss", radius: 122, burst_count: 18, burst_spread: 30,
    hit_delay: 12, ticks: 1, tick_gap: 30
};

// dodge or parry: Crescent Wave
boss_cfg[BOSS_ATTACK.SPECIAL] = {
    windup: 52, total: 100, cd: 330,
    hold: 2, strike: 3, delay: 0, spr: spr_attack,
    range_min: 40, range_max: 320,
    type: "wave", speed: 4.6, mult: 2.2, life: 95,
    tele_length: 360, tele_width: 64
};

// Start the fight (full health, opening cooldowns, chasing the player).
enemy_boss_start();
