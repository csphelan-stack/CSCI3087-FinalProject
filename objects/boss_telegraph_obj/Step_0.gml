// ============================================================
// BOSS TELEGRAPH - STEP
// ============================================================

// Do nothing while the game is paused.
if (global.gameIsPaused)
{
    exit;
}

timer++;

// It goes away if the boss is gone or is no longer attacking.
if (!instance_exists(caster))
{
    instance_destroy();
    exit;
}

if (caster.state != ENEMY_STATE.ATTACK)
{
    instance_destroy();
    exit;
}

// Follow the boss and its aim.
x = caster.x;
y = caster.y;
dir = caster.boss_dir;
