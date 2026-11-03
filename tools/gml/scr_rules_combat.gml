/// scr_rules_combat
/// Combat rules as plain functions: health, cooldowns, melee attacks and dash
/// i-frames. Objects call these instead of doing the maths inline, so the
/// rules can be tested without a room.
///
/// A "unit" is any struct or instance with hp, max_hp and is_dead variables,
/// so obj_player can pass itself: health_apply_damage(id, amount).
/// Stat values (damage, cooldown lengths, i-frames) are passed in from the
/// JSON data; nothing here hardcodes a stat.

// ---------------------------------------------------------------------------
// Shared checks
// ---------------------------------------------------------------------------

/// @function rules_is_amount(value)
/// True for a finite number above 0. Damage or healing that fails this is ignored.
function rules_is_amount(_value) {
    return is_numeric(_value) && !is_bool(_value) && !is_nan(_value) && !is_infinity(_value) && _value > 0;
}

/// @function rules_frames(value)
/// A frame count from data: whole numbers of 0 or more. Anything else counts as 0.
function rules_frames(_value) {
    if (!is_numeric(_value) || is_bool(_value) || is_nan(_value) || is_infinity(_value)) {
        return 0;
    }
    return max(0, floor(_value));
}

// ---------------------------------------------------------------------------
// Health
// ---------------------------------------------------------------------------

/// @function health_create(max_hp)
/// A unit at full health. A max_hp that is not a finite number of at least 1
/// becomes 1, so bad data cannot make a unit that starts dead or cannot die.
function health_create(_max_hp) {
    var _max = rules_is_amount(_max_hp) ? max(1, floor(_max_hp)) : 1;
    return { hp: _max, max_hp: _max, is_dead: false };
}

/// @function health_apply_damage(unit, amount)
/// Lowers hp, never below 0. Invalid amounts (0, negative, NaN, infinity,
/// not a number) are ignored, and a dead unit takes no more damage.
/// Returns true only on the hit that kills the unit, so a unit dies exactly
/// once even when two hits land on the same frame.
function health_apply_damage(_unit, _amount) {
    if (_unit.is_dead || !rules_is_amount(_amount)) {
        return false;
    }
    _unit.hp = max(0, _unit.hp - _amount);
    if (_unit.hp <= 0) {
        _unit.is_dead = true;
        return true;
    }
    return false;
}

/// @function health_apply_heal(unit, amount)
/// Raises hp, never above max_hp. Invalid amounts are ignored and a dead unit
/// stays dead. Returns how much hp was actually restored.
function health_apply_heal(_unit, _amount) {
    if (_unit.is_dead || !rules_is_amount(_amount)) {
        return 0;
    }
    var _before = _unit.hp;
    _unit.hp = min(_unit.max_hp, _unit.hp + _amount);
    return _unit.hp - _before;
}

/// @function health_try_potion(unit, amount)
/// Drinks a potion only if it would restore something. Returns true if used,
/// so a potion is never wasted at full health.
function health_try_potion(_unit, _amount) {
    return health_apply_heal(_unit, _amount) > 0;
}

/// @function health_fraction(unit)
/// How full the health bar is, from 0 to 1. Returns 0 when max_hp is 0 or
/// less, instead of dividing by zero.
function health_fraction(_unit) {
    if (!is_numeric(_unit.max_hp) || _unit.max_hp <= 0) {
        return 0;
    }
    return clamp(_unit.hp / _unit.max_hp, 0, 1);
}

// ---------------------------------------------------------------------------
// Cooldowns (counted in frames, never in real time)
// ---------------------------------------------------------------------------

/// @function cooldown_create(length_frames)
/// A cooldown that starts ready. Invalid lengths count as 0 (always ready).
function cooldown_create(_length_frames) {
    return { length_frames: rules_frames(_length_frames), remaining: 0 };
}

/// @function cooldown_ready(cooldown)
function cooldown_ready(_cooldown) {
    return _cooldown.remaining <= 0;
}

/// @function cooldown_try_use(cooldown)
/// If ready, starts the cooldown and returns true. If not, returns false and
/// changes nothing, so spamming the button cannot restart or shorten it.
function cooldown_try_use(_cooldown) {
    if (!cooldown_ready(_cooldown)) {
        return false;
    }
    _cooldown.remaining = _cooldown.length_frames;
    return true;
}

/// @function cooldown_tick(cooldown)
/// Call once per frame. Counts down and stops at 0.
function cooldown_tick(_cooldown) {
    _cooldown.remaining = max(0, _cooldown.remaining - 1);
}

/// @function cooldown_fraction(cooldown)
/// How full the cooldown bar is: 0 right after use, 1 when ready.
function cooldown_fraction(_cooldown) {
    if (_cooldown.length_frames <= 0) {
        return 1;
    }
    return 1 - (_cooldown.remaining / _cooldown.length_frames);
}

// ---------------------------------------------------------------------------
// Melee attack
// ---------------------------------------------------------------------------

/// @function attack_create(damage, cooldown_frames)
function attack_create(_damage, _cooldown_frames) {
    return { damage: _damage, cooldown: cooldown_create(_cooldown_frames), swinging: false, hit_targets: [] };
}

/// @function attack_try_start(attack)
/// Starts a swing if the cooldown allows. Each swing gets an empty list of
/// targets it has hit.
function attack_try_start(_attack) {
    if (!cooldown_try_use(_attack.cooldown)) {
        return false;
    }
    _attack.swinging = true;
    _attack.hit_targets = [];
    return true;
}

/// @function attack_end(attack)
/// Call when the swing animation finishes.
function attack_end(_attack) {
    _attack.swinging = false;
}

/// @function attack_try_hit(attack, target)
/// Damages target with the current swing, unless this swing already hit it.
/// Returns true if damage was applied.
function attack_try_hit(_attack, _target) {
    if (!_attack.swinging) {
        return false;
    }
    for (var _i = 0; _i < array_length(_attack.hit_targets); _i++) {
        if (_attack.hit_targets[_i] == _target) {
            return false;
        }
    }
    array_push(_attack.hit_targets, _target);
    health_apply_damage(_target, _attack.damage);
    return true;
}

// ---------------------------------------------------------------------------
// Dash and i-frames
// ---------------------------------------------------------------------------

/// @function dash_create(iframe_frames, cooldown_frames)
function dash_create(_iframe_frames, _cooldown_frames) {
    return { iframe_length: rules_frames(_iframe_frames), iframes_left: 0, cooldown: cooldown_create(_cooldown_frames) };
}

/// @function dash_try_start(dash)
/// Starts a dash if the cooldown allows. The player is invulnerable for
/// iframe_length frames, counting the frame the dash starts.
function dash_try_start(_dash) {
    if (!cooldown_try_use(_dash.cooldown)) {
        return false;
    }
    _dash.iframes_left = _dash.iframe_length;
    return true;
}

/// @function dash_is_invulnerable(dash)
function dash_is_invulnerable(_dash) {
    return _dash.iframes_left > 0;
}

/// @function dash_tick(dash)
/// Call once per frame, after that frame's hits have been checked.
function dash_tick(_dash) {
    _dash.iframes_left = max(0, _dash.iframes_left - 1);
    cooldown_tick(_dash.cooldown);
}

/// @function player_take_hit(unit, dash, amount)
/// Damage to the player, ignored while dash i-frames are active.
/// Returns true if this hit killed the player.
function player_take_hit(_unit, _dash, _amount) {
    if (dash_is_invulnerable(_dash)) {
        return false;
    }
    return health_apply_damage(_unit, _amount);
}
