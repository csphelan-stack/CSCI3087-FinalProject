// ============================================================
// INITIAL SPRITE
// ============================================================

// Give the object a valid sprite before the parent Create event runs.
sprite_index = orc_berserker_idle_forward_spr;


// ============================================================
// PARENT INITIALIZATION
// ============================================================

// Run Enemy_base_obj's Create event.
event_inherited();


// ============================================================
// BERSERKER STATS
// ============================================================

// Give the Berserker 10 HP.
hp = 10;

// Give the Berserker a chase speed of 1.6.
movespd = 1.6;

// Give the Berserker 4 attack damage.
attack_damage = 4;

// Allow the Berserker to attack from 24 pixels away.
attack_range = 24;

// Make the Berserker wait 40 frames between attacks.
attack_cooldown_max = 40;

// Make the attack connect after 10 frames.
attack_windup = 10;

// Make the entire attack last 26 frames.
attack_duration = 26;

// Give the Berserker relatively strong knockback.
knockback_power = 5;


// ============================================================
// IDLE SPRITES
// ============================================================

// Direction order:
// right, backward, left, forward.
spr_idle =
[
    orc_berserker_idle_right_spr,
    orc_berserker_idle_backward_spr,
    orc_berserker_idle_left_spr,
    orc_berserker_idle_forward_spr
];


// ============================================================
// RUN SPRITES
// ============================================================

spr_run =
[
    orc_berserker_run_right_spr,
    orc_berserker_run_backward_spr,
    orc_berserker_run_left_spr,
    orc_berserker_run_forward_spr
];


// ============================================================
// ATTACK SPRITES
// ============================================================

spr_attack =
[
    orc_berserker_attack_right_spr,
    orc_berserker_attack_backward_spr,
    orc_berserker_attack_left_spr,
    orc_berserker_attack_forward_spr
];


// ============================================================
// HURT SPRITES
// ============================================================

spr_hurt =
[
    orc_berserker_hurt_right_spr,
    orc_berserker_hurt_backward_spr,
    orc_berserker_hurt_left_spr,
    orc_berserker_hurt_forward_spr
];


// ============================================================
// DEATH SPRITES
// ============================================================

spr_death =
[
    orc_berserker_death_right_spr,
    orc_berserker_death_backward_spr,
    orc_berserker_death_left_spr,
    orc_berserker_death_forward_spr
];