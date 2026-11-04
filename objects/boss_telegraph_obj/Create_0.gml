// ============================================================
// BOSS TELEGRAPH - CREATE
// ============================================================
// the warning lane on the ground for the orc's charge and the
// skeleton's wave. it shows where the attack is aimed and fills up
// until it goes off. made by the enemy_boss script, which hands it:
//   caster, colour, length, width, windup
// ============================================================

if (!variable_instance_exists(id, "caster"))  caster  = noone;
if (!variable_instance_exists(id, "colour"))  colour  = c_red;
if (!variable_instance_exists(id, "length"))  length  = 300;
if (!variable_instance_exists(id, "width"))   width   = 60;
if (!variable_instance_exists(id, "windup"))  windup  = 55;

// frames since it was created
timer = 0;

// the direction it points (it follows the boss's aim)
dir = 0;
