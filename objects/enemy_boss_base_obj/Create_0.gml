// ============================================================
// BOSS BASE - CREATE
// ============================================================
// every boss is a child of this object. it sets up everything a boss
// shares. each boss (orc, skeleton, cultist) then fills in its own
// name, stats, sprites and attacks. see the enemy_boss script.
// ============================================================

// Do everything a normal enemy does first.
event_inherited();

// This enemy is a boss (turns on the boss code in the enemy scripts).
boss_enabled = true;

// ---------- identity (each boss sets these) ----------
boss_name      = "Boss";                    // shown on the health bar
boss_accent    = c_white;                   // the boss's color (bar, aura, warning lane)
boss_element   = MAGIC_ELEMENT.FIRE;        // the magic this boss uses
boss_orb_scale = 2.2;                       // size of the orb that grows on the boss

// ---------- the attack in progress ----------
boss_attack   = BOSS_ATTACK.NONE;   // which attack is happening
boss_cur      = undefined;          // that attack's settings (from boss_cfg)
boss_t        = 0;                  // frames since the attack started
boss_dir      = 0;                  // the direction the attack is aimed
boss_img      = 0;                  // animation frame picked by hand during an attack
boss_charging = false;              // true while the orc is rushing forward
boss_hit_done = false;              // so a charge / swing only hurts once
boss_circles  = [];                 // magic circles made by this attack
boss_tele     = noone;              // the warning lane on the ground

// ---------- cooldowns ----------
// one cooldown per attack (indexed by BOSS_ATTACK). the enraged boss uses them faster.
boss_cd       = [0, 0, 0, 0, 0];
boss_cd_scale = 1;
boss_gap      = 36;                 // pause between two attacks (frames)
boss_enraged  = false;

// ---------- fatigue ----------
// every attack, whatever it is, adds the same amount of fatigue. when the bar is
// full the boss is worn out: it stands still for a while, then the bar starts over.
boss_fatigue_max        = 100;   // a full bar
boss_fatigue_per_attack = 20;    // added by EVERY attack (100 / 20 = worn out after 5 attacks)
boss_exhaust_time       = 180;   // how long it stays worn out, in frames (180 = 3 seconds)
boss_fatigue            = 0;     // the real amount
boss_fatigue_shown      = 0;     // the amount drawn on screen (it slides toward the real one)

// ---------- looks ----------
boss_flash       = 0;               // white flash when hit
boss_force_hurt  = false;           // only true for the moment a parry staggers the boss
boss_aura_t      = random(360);     // time used by the orbiting orbs

// ---------- the settings of each attack (each boss fills these in) ----------
// boss_cfg[BOSS_ATTACK.MELEE], [MAGIC], [AREA], [SPECIAL]
boss_cfg = array_create(5, undefined);

// ---------- tougher than a normal enemy ----------
knockback_power = 0;
view_angle = 360;
sight_range = 340;                  // how far the boss can see the player
lose_range  = 700;                  // how far the player has to run to lose the boss

// Bosses are drawn at their real size.
image_xscale = 1;
image_yscale = 1;
