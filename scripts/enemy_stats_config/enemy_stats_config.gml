// enemy_stats_config: hit points and damage for every enemy, boss and enemy attack.
// Each enemy's Create event reads its values from global.enemy_stats, so balance
// enemies here. Runs once when the game starts; takes nothing in.
global.enemy_stats = {
    boss_cultist: { attack_damage: 6 },
    boss_orc: { attack_damage: 7 },
    boss_projectile: { damage: 1 },
    boss_skeleton: { attack_damage: 6 },
    enemy_base: { attack_damage: 3 },
    lucifer_ancient_skeleton: { hp: 80, attack_damage: 10 },
    lucifer_cultist: { hp: 10, attack_damage: 3 },
    lucifer_necromancer: { hp: 10, attack_damage: 4 },
    lucifer_skeleton_king: { hp: 40, attack_damage: 6 },
    lucifer_warrior: { hp: 14, attack_damage: 4 },
    magic_circle: { damage: 1 },
    orc_beserker: { attack_damage: 4 },
    orc_grunt: { attack_damage: 3 },
    orc_warlord: { attack_damage: 7 },
    skeleton_cultist: { attack_damage: 3 },
    skeleton_king: { attack_damage: 3 },
    skeleton_minion: { attack_damage: 3 },
    skeleton_soldier: { attack_damage: 3 }
};
