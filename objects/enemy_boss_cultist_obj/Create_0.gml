// ============================================================
// CULTIST HIGH PRIEST - CREATE
// ============================================================
// the cultist boss. a tall hooded priest. uses POISON magic.
//   normal attack : "Soul Burst"    - a point-blank burst around himself
//   normal magic  : "Toxic Scatter" - circles scattered around the player
//   area magic    : "Plague Cloud"  - a huge circle on the player that hurts twice
//   dodge / parry : "Soul Skulls"   - skulls circle him, then fly at the player
// ============================================================

sprite_index = boss_cultist_idle_forward_spr;

event_inherited();

boss_name    = "Cultist High Priest";
boss_accent  = make_colour_rgb(120, 235, 70);
boss_element = MAGIC_ELEMENT.POISON;

// ---------- stats ----------
total_hp        = 170;
hp              = total_hp;
movespd         = 0.95;
attack_damage   = global.enemy_stats.boss_cultist.attack_damage;       // the normal attack. the other attacks are multiples of this
attack_range    = 80;      // how close the player has to be for the soul burst

// ---------- sprites ----------
spr_idle = [
    boss_cultist_idle_right_spr,
    boss_cultist_idle_backward_spr,
    boss_cultist_idle_left_spr,
    boss_cultist_idle_forward_spr
];

spr_run = [
    boss_cultist_walk_right_spr,
    boss_cultist_walk_backward_spr,
    boss_cultist_walk_left_spr,
    boss_cultist_walk_forward_spr
];

spr_attack = [
    boss_cultist_attack_right_spr,
    boss_cultist_attack_backward_spr,
    boss_cultist_attack_left_spr,
    boss_cultist_attack_forward_spr
];

spr_hurt = [
    boss_cultist_hurt_right_spr,
    boss_cultist_hurt_backward_spr,
    boss_cultist_hurt_left_spr,
    boss_cultist_hurt_forward_spr
];

spr_death = [
    boss_cultist_death_right_spr,
    boss_cultist_death_backward_spr,
    boss_cultist_death_left_spr,
    boss_cultist_death_forward_spr
];

// (only the orc charges, so this is just a safe default)
spr_special = [
    boss_cultist_attack_right_spr,
    boss_cultist_attack_backward_spr,
    boss_cultist_attack_left_spr,
    boss_cultist_attack_forward_spr
];

// ---------- attacks (see the orc boss for what each setting means) ----------

// the normal attack: a burst of energy around the priest (the starburst frame)
boss_cfg[BOSS_ATTACK.MELEE] = {
    windup: 30, total: 70, cd: 45,
    hold: 4, strike: 8, delay: 12, spr: spr_attack,
    range_min: 0, range_max: 0
};

// the normal magic: toxic circles scattered around the player
boss_cfg[BOSS_ATTACK.MAGIC] = {
    windup: 52, total: 108, cd: 140,
    hold: 4, strike: 8, delay: 12, spr: spr_attack,
    range_min: 0, range_max: 260,
    count: 4, gap: 12, pattern: "scatter"
};

// the big magic: Plague Cloud, a huge circle that hurts twice (it lingers)
boss_cfg[BOSS_ATTACK.AREA] = {
    windup: 92, total: 176, cd: 560,
    hold: 4, strike: 8, delay: 12, spr: spr_attack,
    range_min: 0, range_max: 240,
    centre: "player", radius: 122, burst_count: 16, burst_spread: 60,
    hit_delay: 12, ticks: 2, tick_gap: 40
};

// dodge or parry: Soul Skulls
boss_cfg[BOSS_ATTACK.SPECIAL] = {
    windup: 58, total: 150, cd: 380,
    hold: 4, strike: 8, delay: 12, spr: spr_attack,
    range_min: 40, range_max: 320,
    type: "skulls", count: 5, gap: 15, speed: 3.4, mult: 1.9, orbit_r: 56
};

// Start the fight (full health, opening cooldowns, chasing the player).
enemy_boss_start();
