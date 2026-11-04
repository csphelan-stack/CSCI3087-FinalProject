// ============================================================
// ENEMY BOSS
// ============================================================
// everything a boss needs on top of a normal enemy.
// a boss is a child of enemy_boss_base_obj, which is a child of
// Enemy_base_obj, so it still uses the normal state machine
// (idle, chase, attack, hurt, dead). the only differences:
//
//   - in CHASE, instead of walking up and swinging, the boss picks one
//     of four attacks (enemy_boss_choose)
//   - the ATTACK state runs enemy_boss_attack_step instead of the
//     normal attack code
//   - SUPER ARMOR: normal hits (sword, spin) do not stun the boss, they
//     only make it flash white. a PERFECT PARRY still staggers it.
//
// THE FOUR ATTACKS (every boss has all four)
//   MELEE   - the normal attack, used when the player is close
//   MAGIC   - the normal magic: a few small magic circles
//   AREA    - the big magic: one huge magic circle (large area)
//   SPECIAL - the attack the player has to dodge or parry
//             "charge" (orc), "wave" (skeleton), "skulls" (cultist)
//
// HOW A BOSS IS SET UP
//   see enemy_boss_orc_obj Create. each boss fills in boss_cfg, one entry
//   per attack, with its timing and its animation settings.
//
// HOW THE PARRY STAGGER WORKS
//   when the player perfectly parries, parrySuccess() sets state_timer on
//   the enemy that attacked. while a boss attacks, it keeps state_timer at
//   a fixed number (BOSS_SENTINEL). if it ever changes, the boss knows it
//   was parried and staggers.
// ============================================================

// the boss's four attacks
enum BOSS_ATTACK
{
    NONE,
    MELEE,
    MAGIC,
    AREA,
    SPECIAL
}

// state_timer is kept at this while a boss attacks (see above)
#macro BOSS_SENTINEL -999


// ============================================================
// EVERY FRAME
// ============================================================
// called from the enemy Step event, only for bosses.
// ============================================================

function enemy_boss_tick()
{
    // Count every attack's cooldown down.
    for (var _i = 0; _i < array_length(boss_cd); _i++)
    {
        if (boss_cd[_i] > 0)
        {
            boss_cd[_i]--;
        }
    }

    // The white hit-flash fades out.
    if (boss_flash > 0)
    {
        boss_flash--;
    }

    // Time used by the aura and the orbiting orbs.
    boss_aura_t++;

    // At half health the boss becomes enraged:
    // it attacks more often and moves faster.
    if (!boss_enraged && hp <= total_hp * 0.5)
    {
        boss_enraged = true;
        boss_cd_scale = 0.7;
        movespd *= 1.25;
        boss_flash = 24;
    }
}


// ============================================================
// RANGE RULE
// ============================================================
// like the normal casters, a boss never uses an attack from
// farther away than it can see the player (sight_range).
// ============================================================

function enemy_boss_range(_range)
{
    return min(_range, sight_range);
}


// ============================================================
// PICK AN ATTACK
// ============================================================
// called every frame in CHASE. returns the attack to use now,
// or BOSS_ATTACK.NONE if nothing is ready (then the boss keeps walking).
// ============================================================

function enemy_boss_choose()
{
    // A short breather between attacks.
    if (attack_cooldown > 0)
    {
        return BOSS_ATTACK.NONE;
    }

    var _dist = point_distance(x, y, target.x, target.y);

    // Can the boss really see the player from here?
    var _sees = enemy_can_see_player(sight_range, false);

    var _options = [];

    // Close enough for the normal attack. It is listed twice so it is
    // the usual choice when the player is right next to the boss.
    if (_dist <= attack_range && boss_cd[BOSS_ATTACK.MELEE] <= 0)
    {
        array_push(_options, BOSS_ATTACK.MELEE);
        array_push(_options, BOSS_ATTACK.MELEE);
    }

    // The ranged attacks need line of sight and the right distance.
    if (_sees)
    {
        for (var _k = BOSS_ATTACK.MAGIC; _k <= BOSS_ATTACK.SPECIAL; _k++)
        {
            var _c = boss_cfg[_k];

            if (boss_cd[_k] <= 0 && _dist >= _c.range_min && _dist <= enemy_boss_range(_c.range_max))
            {
                array_push(_options, _k);
            }
        }
    }

    if (array_length(_options) == 0)
    {
        return BOSS_ATTACK.NONE;
    }

    // Pick one of the ready attacks at random.
    return _options[irandom(array_length(_options) - 1)];
}


// ============================================================
// BEGIN AN ATTACK
// ============================================================
// called once when the boss enters the ATTACK state.
// boss_attack has already been set by the chase state.
// ============================================================

function enemy_boss_begin()
{
    boss_cur = boss_cfg[boss_attack];
    boss_t = 0;
    boss_img = 0;
    boss_charging = false;
    boss_hit_done = false;
    boss_circles = [];
    attack_hit_done = false;

    // Used to notice a parry (see the top of this script).
    state_timer = BOSS_SENTINEL;

    // Aim at the last place the boss saw the player.
    boss_dir = point_direction(x, y, last_x, last_y);
    facing = boss_dir;

    switch (boss_attack)
    {
        case BOSS_ATTACK.MAGIC:
            enemy_boss_begin_magic();
        break;

        case BOSS_ATTACK.AREA:
            enemy_boss_begin_area();
        break;

        case BOSS_ATTACK.SPECIAL:
            enemy_boss_begin_special();
        break;
    }
}


// the colored orb that grows on the boss while it charges a spell
function enemy_boss_make_orb(_colour, _grow_time)
{
    magic_orb = instance_create_depth((bbox_left + bbox_right) / 2, (bbox_top + bbox_bottom) / 2, depth - 20, magic_fx_obj, {
        kind:      "orb",
        caster:    id,
        colour:    _colour,
        grow_time: _grow_time,
        orb_scale: boss_orb_scale
    });
}


// ------------------------------------------------------------
// MAGIC: a few small magic circles
// ------------------------------------------------------------
function enemy_boss_begin_magic()
{
    var _c = boss_cur;
    var _info = enemy_magic_info(boss_element);

    // Where the player is right now.
    var _px = last_x;
    var _py = last_y;

    enemy_boss_make_orb(_info.colour, _c.windup);

    // Work out where every circle goes. Each boss uses its own pattern.
    var _spots = [];

    switch (_c.pattern)
    {
        // one on the player and one on each side of them (a pincer)
        case "triangle":
            array_push(_spots, [_px, _py]);
            array_push(_spots, [_px + lengthdir_x(66, boss_dir + 90), _py + lengthdir_y(66, boss_dir + 90)]);
            array_push(_spots, [_px + lengthdir_x(66, boss_dir - 90), _py + lengthdir_y(66, boss_dir - 90)]);
        break;

        // a trail of circles from the boss to the player
        case "line":
            for (var _i = 1; _i <= _c.count; _i++)
            {
                var _t = _i / _c.count;
                array_push(_spots, [lerp(x, _px, _t), lerp(y, _py, _t)]);
            }
        break;

        // one on the player and the rest scattered around them
        case "scatter":
            array_push(_spots, [_px, _py]);

            for (var _i = 1; _i < _c.count; _i++)
            {
                var _a = random(360);
                var _r = random_range(48, 88);
                array_push(_spots, [_px + lengthdir_x(_r, _a), _py + lengthdir_y(_r, _a)]);
            }
        break;
    }

    // Make the circles. Each one is released a little after the one before.
    for (var _i = 0; _i < array_length(_spots); _i++)
    {
        var _circle = instance_create_depth(_spots[_i][0], _spots[_i][1], depth + 20, magic_circle_obj, {
            caster:        id,
            element:       boss_element,
            colour:        _info.colour,
            effect_sprite: _info.effect,
            frame_time:    _info.frame_time,
            hit_delay:     _info.hit_delay,
            damage:        round(attack_damage * 0.9),
            hit_radius:    magic_radius,
            charge_time:   _c.windup + _i * _c.gap
        });

        array_push(boss_circles, _circle);
    }
}


// ------------------------------------------------------------
// AREA: one huge magic circle
// ------------------------------------------------------------
function enemy_boss_begin_area()
{
    var _c = boss_cur;
    var _info = enemy_magic_info(boss_element);

    // The circle is centered on the player or on the boss itself.
    var _cx = last_x;
    var _cy = last_y;

    if (_c.centre == "boss")
    {
        _cx = x;
        _cy = y;
    }

    enemy_boss_make_orb(_info.colour, _c.windup);

    var _circle = instance_create_depth(_cx, _cy, depth + 20, magic_circle_obj, {
        caster:             id,
        element:            boss_element,
        colour:             _info.colour,
        effect_sprite:      _info.effect,
        frame_time:         _info.frame_time,
        hit_delay:          _c.hit_delay,
        damage:             round(attack_damage * 1.3),
        hit_radius:         _c.radius,
        charge_time:        _c.windup,
        circle_sprite:      magic_bigcircle_spr,
        circle_base_radius: 125,
        burst_count:        _c.burst_count,
        burst_spread:       _c.burst_spread,
        hit_ticks:          _c.ticks,
        tick_gap:           _c.tick_gap
    });

    array_push(boss_circles, _circle);
}


// ------------------------------------------------------------
// SPECIAL: the attack the player must dodge or parry
// ------------------------------------------------------------
function enemy_boss_begin_special()
{
    var _c = boss_cur;

    switch (_c.type)
    {
        // a warning lane on the ground shows where the boss will go / shoot
        case "charge":
        case "wave":
            boss_tele = instance_create_depth(x, y, depth + 15, boss_telegraph_obj, {
                caster: id,
                colour: boss_accent,
                length: _c.tele_length,
                width:  _c.tele_width,
                windup: _c.windup
            });
        break;

        // skulls appear around the boss, then launch one after another
        case "skulls":
            for (var _i = 0; _i < _c.count; _i++)
            {
                instance_create_depth(x, y, depth - 10, boss_projectile_obj, {
                    kind:       "skull",
                    caster:     id,
                    damage:     round(attack_damage * _c.mult),
                    spd:        _c.speed,
                    hit_radius: 11,
                    orbit_ang:  _i * (360 / _c.count),
                    orbit_r:    _c.orbit_r,
                    launch_at:  _c.windup + _i * _c.gap
                });
            }
        break;
    }
}


// ============================================================
// RUN THE ATTACK
// ============================================================
// called every frame from the ATTACK state (instead of the normal
// attack code) while the boss is attacking.
// ============================================================

function enemy_boss_attack_step()
{
    // A PERFECT PARRY changed state_timer: the boss is staggered.
    if (state_timer != BOSS_SENTINEL)
    {
        enemy_boss_stagger(state_timer);
        return;
    }

    var _c = boss_cur;

    // Frames since this attack started.
    boss_t++;

    // Keep turning to face the player. A charge or a wave stops turning a
    // moment before it goes off, so the player can dodge sideways.
    var _lock = 0;

    if (boss_attack == BOSS_ATTACK.SPECIAL && (_c.type == "charge" || _c.type == "wave"))
    {
        _lock = 16;
    }

    if (!boss_charging && boss_t < _c.windup - _lock && target != noone && instance_exists(target))
    {
        boss_dir = point_direction(x, y, target.x, target.y);
    }

    if (!boss_charging)
    {
        facing = boss_dir;
    }

    // What happens in each attack.
    switch (boss_attack)
    {
        // ---------------- MELEE ----------------
        case BOSS_ATTACK.MELEE:

            // The swing connects (this is the same hit check normal enemies use).
            if (!boss_hit_done && boss_t >= _c.windup + _c.delay)
            {
                boss_hit_done = true;
                attack_hit_done = true;
                enemy_attack_hit();
            }

        break;

        // ---------------- MAGIC ----------------
        case BOSS_ATTACK.MAGIC:

            // Release the circles one after another.
            for (var _i = 0; _i < array_length(boss_circles); _i++)
            {
                if (boss_t == _c.windup + _i * _c.gap && instance_exists(boss_circles[_i]))
                {
                    boss_circles[_i].released = true;
                }
            }

            // The orb flares out when the first circle goes off.
            if (boss_t >= _c.windup)
            {
                attack_hit_done = true;
            }

        break;

        // ---------------- AREA ----------------
        case BOSS_ATTACK.AREA:

            if (boss_t == _c.windup)
            {
                attack_hit_done = true;

                if (instance_exists(boss_circles[0]))
                {
                    boss_circles[0].released = true;
                }
            }

        break;

        // ---------------- SPECIAL ----------------
        case BOSS_ATTACK.SPECIAL:
            enemy_boss_special_step();
        break;
    }

    // Pick the animation frame for this moment of the attack.
    boss_img = enemy_boss_anim_frame();

    // A parry can also happen during the hit above, so check again.
    if (state_timer != BOSS_SENTINEL)
    {
        enemy_boss_stagger(state_timer);
        return;
    }

    // The attack is over.
    if (boss_t >= _c.total)
    {
        enemy_boss_end();
    }
}


// the part of the attack that is different for each special attack
function enemy_boss_special_step()
{
    var _c = boss_cur;

    switch (_c.type)
    {
        // ---------------- CHARGE (orc) ----------------
        case "charge":

            // The warning lane is done: the boss rushes forward.
            if (boss_t == _c.windup)
            {
                boss_charging = true;
                attack_hit_done = true;
                enemy_boss_remove_tele();
            }

            if (boss_charging)
            {
                // Run in a straight line (walls still stop the boss).
                move_spd = _c.speed;
                move_dir = boss_dir;

                // The player is hurt (once) if they are inside the warning lane,
                // which is exactly as wide as the circle of hit_radius around the boss.
                if (!boss_hit_done && collision_circle(x, y - 10, _c.hit_radius, main_character_Obj, false, true) != noone)
                {
                    boss_hit_done = true;

                    with (main_character_Obj)
                    {
                        Enemy_damage_applying(round(other.attack_damage * other.boss_cur.mult), other.id);
                    }
                }

                // The rush ends after a fixed time.
                if (boss_t >= _c.windup + _c.charge_time)
                {
                    boss_charging = false;
                }
            }

        break;

        // ---------------- WAVE (skeleton) ----------------
        case "wave":

            if (boss_t == _c.windup)
            {
                attack_hit_done = true;
                enemy_boss_remove_tele();

                // One wave, or three in a fan once the boss is enraged.
                var _n = 1;

                if (boss_enraged)
                {
                    _n = 3;
                }

                for (var _i = 0; _i < _n; _i++)
                {
                    var _a = boss_dir + (_i - (_n - 1) / 2) * 30;

                    instance_create_depth(x + lengthdir_x(36, _a), y + lengthdir_y(36, _a), depth - 10, boss_projectile_obj, {
                        kind:       "wave",
                        caster:     id,
                        dir:        _a,
                        spd:        _c.speed,
                        damage:     round(attack_damage * _c.mult),
                        hit_radius: 30,
                        life:       _c.life
                    });
                }
            }

        break;

        // ---------------- SKULLS (cultist) ----------------
        case "skulls":

            // The skulls fly by themselves. The boss just holds the pose.
            if (boss_t >= _c.windup)
            {
                attack_hit_done = true;
            }

        break;
    }
}


// ============================================================
// ANIMATION
// ============================================================
// the attack animation is driven by hand so the strike frame lands exactly
// when the attack happens. each attack has a few settings:
//   hold   - frame to freeze on while charging (-1 = no hold)
//   strike - frame at the moment the attack goes off
//   delay  - frames between the release and the strike frame
// ============================================================

function enemy_boss_anim_frame()
{
    var _c = boss_cur;

    var _spr = _c.spr;

    if (boss_charging)
    {
        _spr = spr_special;
    }

    var _n = sprite_get_number(_spr[enemy_dir4()]);

    // Charging: the run animation just loops.
    if (boss_charging)
    {
        return (boss_t * 0.3) mod _n;
    }

    var _f = 0;

    if (_c.hold >= 0)
    {
        // Raise the weapon / arms, then freeze there until the release.
        var _raise = _c.windup * 0.45;

        if (boss_t < _raise)
        {
            _f = lerp(0, _c.hold, boss_t / max(_raise, 1));
        }
        else if (boss_t < _c.windup)
        {
            _f = _c.hold;
        }
        else if (boss_t < _c.windup + _c.delay)
        {
            _f = lerp(_c.hold, _c.strike, (boss_t - _c.windup) / max(_c.delay, 1));
        }
        else
        {
            _f = lerp(_c.strike, _n - 1, clamp((boss_t - _c.windup - _c.delay) / max(_c.total - _c.windup - _c.delay, 1), 0, 1));
        }
    }
    else
    {
        // No hold: play straight to the strike frame, then finish the swing.
        if (boss_t < _c.windup + _c.delay)
        {
            _f = lerp(0, _c.strike, boss_t / max(_c.windup + _c.delay, 1));
        }
        else
        {
            _f = lerp(_c.strike, _n - 1, clamp((boss_t - _c.windup - _c.delay) / max(_c.total - _c.windup - _c.delay, 1), 0, 1));
        }
    }

    return clamp(_f, 0, _n - 0.01);
}


// called from enemy_update_animation while a boss is in the ATTACK state
function enemy_boss_animate(_d)
{
    // Safety: no attack data yet, so use the normal attack sprite.
    if (!is_struct(boss_cur))
    {
        sprite_index = spr_attack[_d];
        image_speed = attack_anim_spd;
        return;
    }

    var _spr = boss_cur.spr;

    // The orc's charge uses its running sprite.
    if (boss_charging)
    {
        _spr = spr_special;
    }

    sprite_index = _spr[_d];

    // The frame is picked by hand (enemy_boss_anim_frame).
    image_speed = 0;
    image_index = boss_img;
}


// ============================================================
// ENDING AN ATTACK
// ============================================================

// get rid of the warning lane
function enemy_boss_remove_tele()
{
    if (instance_exists(boss_tele))
    {
        instance_destroy(boss_tele);
    }

    boss_tele = noone;
}

// anything the boss made that should not outlive its attack
function enemy_boss_cleanup()
{
    enemy_boss_remove_tele();
    boss_charging = false;
}

// the attack finished normally
function enemy_boss_end()
{
    // This attack goes on cooldown.
    boss_cd[boss_attack] = round(boss_cur.cd * boss_cd_scale);

    // A short pause before the next attack: the player's chance to hit back.
    attack_cooldown = boss_gap;

    enemy_boss_cleanup();
    move_spd = 0;
    boss_attack = BOSS_ATTACK.NONE;

    enemy_change_state(ENEMY_STATE.CHASE);
}

// the boss was perfectly parried: it staggers (the parry sets how long)
function enemy_boss_stagger(_stun_time)
{
    // This attack goes on a half cooldown so it is not instantly repeated.
    if (boss_attack != BOSS_ATTACK.NONE)
    {
        boss_cd[boss_attack] = round(boss_cur.cd * boss_cd_scale * 0.5);
    }

    enemy_boss_cleanup();
    boss_attack = BOSS_ATTACK.NONE;
    attack_cooldown = boss_gap;

    // Bosses normally ignore being hurt, so allow it just this once.
    boss_force_hurt = true;
    enemy_change_state(ENEMY_STATE.HURT);
    boss_force_hurt = false;

    // Stunned for as long as the parry says.
    state_timer = _stun_time;
    boss_flash = 12;
}


// ============================================================
// START THE FIGHT
// ============================================================
// each boss calls this at the very end of its Create event.
// ============================================================

function enemy_boss_start()
{
    // The health bar needs to know the full health.
    total_hp = hp;
    hp_initialized = true;

    // The boss does not open with its biggest attacks.
    boss_cd[BOSS_ATTACK.MAGIC]   = 60;
    boss_cd[BOSS_ATTACK.SPECIAL] = 150;
    boss_cd[BOSS_ATTACK.AREA]    = 240;

    // Bosses always know where the player is: start the fight chasing.
    target = instance_nearest(x, y, main_character_Obj);

    if (target != noone)
    {
        last_x = target.x;
        last_y = target.y;
        state = ENEMY_STATE.CHASE;
    }
}
