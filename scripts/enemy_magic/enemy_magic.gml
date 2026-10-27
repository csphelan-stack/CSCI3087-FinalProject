// ============================================================
// ENEMY MAGIC
// ============================================================
// everything a magic-using enemy needs to cast a spell.
//
// HOW A CAST WORKS
//   1. enemy_state_logic (chase): when the player is inside the
//      enemy's magic range, the enemy stops, faces the player and
//      enters the ATTACK state.
//   2. enemy_state_machine (entering ATTACK): calls enemy_magic_begin()
//        - a colored orb grows on the enemy's body
//        - a magic circle with a star appears on the ground where the
//          enemy last saw the player (the spot is locked, so the
//          player can dodge it)
//   3. enemy_state_logic (attack, on the hit frame): calls
//      enemy_magic_release(). the circle erupts and the spell
//      (lightning / fire / earth / light / dark) comes out of it.
//      if the player is still inside the circle, they are hurt.
//   if the enemy is hurt or killed BEFORE the release, the spell
//   fizzles out and nothing happens.
//
// RANGE RULE
//   an enemy can never cast farther than it can see the player:
//   enemy_magic_range() is the smaller of magic_range and sight_range.
//
// TO MAKE AN ENEMY A CASTER
//   add this to the END of its Create event (after event_inherited):
//     magic_enabled  = true;
//     magic_elements = [MAGIC_ELEMENT.FIRE];  // one or more
//     magic_range    = 120;                   // never more than sight_range
//     attack_windup  = 45;                    // frames the orb/circle charge
//     attack_duration = 70;                   // whole cast, must be longer than the windup
// ============================================================


// ============================================================
// THE KINDS OF MAGIC
// ============================================================

enum MAGIC_ELEMENT
{
    LIGHTNING,
    FIRE,
    EARTH,
    LIGHT,
    DARK
}


// ============================================================
// SPELL INFO
// ============================================================
// the look and timing of each element, all in one place.
//   colour     - color of the orb, the circle and the glow
//   effect     - the sprite that comes out of the circle
//   hit_delay  - frames after the release until the player is hurt
//   frame_time - game frames each frame of the effect is shown for
// ============================================================

function enemy_magic_info(_element)
{
    switch (_element)
    {
        case MAGIC_ELEMENT.LIGHTNING:
            return { colour: make_colour_rgb(80, 160, 255), effect: magic_lightning_spr, hit_delay: 4, frame_time: 3 };

        case MAGIC_ELEMENT.FIRE:
            return { colour: make_colour_rgb(255, 130, 30), effect: magic_fire_spr, hit_delay: 8, frame_time: 4 };

        case MAGIC_ELEMENT.EARTH:
            return { colour: make_colour_rgb(200, 148, 72), effect: magic_earth_spr, hit_delay: 8, frame_time: 4 };

        case MAGIC_ELEMENT.LIGHT:
            return { colour: make_colour_rgb(255, 225, 90), effect: magic_light_spr, hit_delay: 8, frame_time: 4 };

        case MAGIC_ELEMENT.DARK:
            return { colour: make_colour_rgb(165, 85, 255), effect: magic_dark_spr, hit_delay: 10, frame_time: 4 };
    }

    // unknown element: use fire so nothing breaks
    return { colour: make_colour_rgb(255, 130, 30), effect: magic_fire_spr, hit_delay: 8, frame_time: 4 };
}


// ============================================================
// MAGIC RANGE
// ============================================================
// how far away this enemy can cast.
// it is never more than the enemy's awareness of the player
// (sight_range), even if magic_range is set higher.
// ============================================================

function enemy_magic_range()
{
    return min(magic_range, sight_range);
}


// ============================================================
// CAN THE ENEMY CAST RIGHT NOW?
// ============================================================
// true only if the enemy can actually see the player
// from where it is standing, inside its magic range.
// ============================================================

function enemy_magic_can_cast()
{
    return enemy_can_see_player(enemy_magic_range(), false);
}


// ============================================================
// BEGIN A CAST
// ============================================================
// called once, when the enemy enters the ATTACK state.
// creates the orb on the enemy and the circle on the ground.
// ============================================================

function enemy_magic_begin()
{
    // Pick the element for this cast (random if the enemy knows several).
    magic_element = magic_elements[irandom(array_length(magic_elements) - 1)];

    // Look up its color, effect sprite and timing.
    var _info = enemy_magic_info(magic_element);

    // The spell lands where the enemy last saw the player.
    // (the chase state updates last_x / last_y every frame it sees the player)
    var _spot_x = last_x;
    var _spot_y = last_y;

    // The middle of the enemy's body, where the orb appears.
    var _body_x = (bbox_left + bbox_right) / 2;
    var _body_y = (bbox_top + bbox_bottom) / 2;

    // The orb on the enemy (drawn in front of the enemy).
    magic_orb = instance_create_depth(_body_x, _body_y, depth - 20, magic_fx_obj, {
        kind:      "orb",
        caster:    id,
        colour:    _info.colour,
        grow_time: attack_windup,
        orb_scale: clamp(sprite_width / 48, 0.65, 1.5)
    });

    // The magic circle with the star (drawn on the ground, behind everyone).
    magic_circle = instance_create_depth(_spot_x, _spot_y, depth + 20, magic_circle_obj, {
        caster:        id,
        element:       magic_element,
        colour:        _info.colour,
        effect_sprite: _info.effect,
        frame_time:    _info.frame_time,
        hit_delay:     _info.hit_delay,
        damage:        attack_damage,
        hit_radius:    magic_radius,
        charge_time:   attack_windup
    });
}


// ============================================================
// RELEASE THE SPELL
// ============================================================
// called on the attack's hit frame (the end of the windup).
// tells the circle to erupt.
// ============================================================

function enemy_magic_release()
{
    // Only do this if the circle is still there.
    if (instance_exists(magic_circle))
    {
        magic_circle.released = true;
    }
}
