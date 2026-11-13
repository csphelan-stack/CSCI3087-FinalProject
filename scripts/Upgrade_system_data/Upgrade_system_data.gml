// Upgrade_system_data: Upgrade_system_data() fills global.Character_Upgrades with every
// upgrade card. upgradeCheckPossible() and applyUpgrade(upgrade) are used by the upgrade
// dealer to pick cards and apply the chosen card's effects to the player.
function Upgrade_system_data(){



	global.Character_Upgrades = {
		Damage_upgrade:
		{

			name: "Blade Honing",
			special: false,
			desc: "The blade is an extension of one's own body: This upgrade allows the adventurer to hone his skills and sharpen his blade",
			effects: [
				{ stat: "player_damage", op: "mult"   , value: 2},
				{stat: "tsunami_damage",op:"mult", value: 2}
			],
			spriteF: card_fantasy_sword_spr,
			indexF: 0,
			spriteB: card_fantasy_back_spr,
			indexB: 3,
			upgrades_possible: 4
		}
	,
		health_upgrade:
		{

			name: "Healing Orbs",
			special: false,
			desc: "The collection of orbs is a mystical art passed down through generations: This upgrade allows the user to increase their natural health",
			effects: [
				{ stat: "total_hp", op: "mult"   ,    value: 1.2 },
			],
			spriteF: card_space_star_spr,
			indexF: 0,
			spriteB: card_space_back_spr,
			indexB: 8,
			upgrades_possible: 3

		}
	,
		dash_unlock:
		{

			name: "Shadows of a Promise",
			special: false,
			desc: $"The flooding of the world allowed the formation of a promise in the sky: Using the essence of a rainbow allows a user to teleport instantaneously leaving only a couple of fleeting shadows in their wake (Hit {global.dash_button} to dash)",
			upgrades_possible: 1,
			spriteF: card_deco_feather_spr,
			indexF: 0,
			spriteB: card_deco_back_spr,
			indexB: 6,
			effects: [
				{ stat: "dash_unlock", op: "set"   ,    value: true },
			]

		}
		,
		dash_upgrade:
		{

			name: "Luminescent Silhouette",
			special: false,
			desc: "All things have a limit and all things hold a cost. This upgrade allows the user to dash further but less often",
			    effects: [
		{ stat: "dash_length",   op: "mult"   ,  value: 1.8 },
		{ stat: "dash_cooldown_t",op: "add"   , value: 60 },
		{stat: "dash_ghost_count", op: "add", value:2}
		],
			spriteF: card_deco_feather_spr,
			//use 12 and 13 for any other dash upgrades
			indexF: 10,
			spriteB:  card_deco_back_spr,
			indexB: 3,
			upgrades_possible: 1
		}

,
				dash_upgrade_double:
		{

			name: "Double Rainbow",
			special: false,
			desc: "Double rainbows are a sign of good fortune in many cultures: allows a second dash shortly following the first.",
			    effects: [
		{ stat: "dash_double_unlock",   op: "set"   ,  value: true },
		{stat: "dash_ghost_count", op: "add", value:3}
		],
			spriteF: card_deco_feather_spr,
			//use 12 and 13 for any other dash upgrades
			indexF: 11,
			spriteB:  card_deco_back_spr,
			indexB: 4,
			upgrades_possible: 1
		}


				,
		perfect_parry_unlock:
		{

			name: "Perfect Parry",
			special: false,
			desc: "To master an opponent one must first master themselves: This upgrade allows a quick attack after a successful 'perfect parry' is acheived",
			effects: [
				{ stat: "perfect_p_unlocked", op: "set"   ,    value: true },
			],
			spriteF: card_fantasy_shield_spr,
			indexF: 0,
			spriteB: card_fantasy_back_spr,
			indexB: 5,
			upgrades_possible: 1

		}
		,
			parry_upgrade:
		{

			name: "Protective Parry",
			special: false,
			desc: "True strength is used to protect: This upgrade allows a longer amount of 'parry time' and a greater amount of defense",

			effects: [
			//greater defense: blocked hits drain 20% less of the guard meter
			{ stat: "parry_hit_cost",     op: "mult"   , value: 0.8 },
			//longer parry time: the guard meter is 20% bigger, so the guard can be held longer
			{ stat: "parry_exhaust_time", op: "mult"   , value: 1.2 },
			],
			spriteF: card_fantasy_shield_spr,
			indexF: 10,
			spriteB: card_fantasy_back_spr,
			indexB: 4,
			upgrades_possible : 3

		}

		//this should allow the unlocking of a string of combo attacks: once this is unlocked the chance of getting the othert attacks is higher.
,

			combo_attack:
		{

			name: "Foundational Swordplay",
			special: false,
			desc: "Letting a sword swing is one thing, but swinging your sword is another: This card unlocks the ability to combo attack, increases the attack speed of the player, and reduces player knockback significantly.",
			
			effects: [
			{ stat: "foundational_swordplay_unlocked",     op: "set"   , value: true},
			{stat: "normal_attack_speed", op: "add", value:.3},
			{stat: "attack_recoil", op: "set", value:1},			
			],
			spriteF: card_fantasy_sword_spr,
			indexF: 12,
			spriteB: card_fantasy_back_spr,
			indexB: 0,
			upgrades_possible : 1

		}


		// these next upgrades all have to do with changing the attacks the the player does:
		,

			house_of_cards_attack:
		{

			name: "Sword art 1st form: House of Cards",
			special: false,
			desc: "When the bottom falls they all do: this sword ability activates after every 5 kills, and effects all enemies in a certain radius damaging and stunning all of them. Turn on this sword art by clicking 1.",
			
			effects: [
			{ stat: "house_of_cards_unlock",     op: "set"   , value: true },
			],
			spriteF: card_deco_building_spr,
			indexF: 12,
			spriteB: card_deco_back_spr,
			indexB: 9,
			upgrades_possible : 1

		}

		,
					life_steal_attack:
		{
			
			name: "Sword art 2nd form: Live Offering",
			special: false,
			desc: "The essence of another taken and given to you: clicking shift allows a user to change weapons to a set of throwing knives; these knives heal you and damage the enemy.Turn on this sword art by clicking 2.",
			
			effects: [
			//greater defense: blocked hits drain 20% less of the guard meter
			{ stat: "health_steal_knives_unlocked",     op: "set"   , value: true },
			],
			spriteF: vtk_card_spr,
			indexF: 0,
			spriteB: card_fire_back_spr,
			indexB: 1,
			upgrades_possible : 1

		}


		,
					flood_attack:
		{

			name: "Sword art 3rd Form: Flash Flood",
			special: false,
			desc: "The ebs and flows of swordsmanship combined with the waves of the sea: this sword art allows the user to flood his surroundings on every 3rd attack stunning enemies and grouping them together.Turn on this sword art by clicking 3.",
			
			effects: [
			//greater defense: blocked hits drain 20% less of the guard meter
			{ stat: "flood_formation_unlock",     op: "set"   , value: true },
			],
			spriteF: card_nautical_anchor_spr,
			indexF: 11,
			spriteB: card_nautical_back_spr,
			indexB: 9,
			upgrades_possible : 1

		}



		//These next couple are the specials abilities
		//Only one can be used at a time and maybe we should make them all appear at once with only one being allowed to be picked
		//I also want these attacks to start off alright and then get increasingly better

				,
			Special_attack_tsunami:
		{

			name: "Bladed Tsunami",
			special: true,
			desc: $"Usually spinning in a circle extremely fast makes one sick and with the addition of a sword things get hairy, but this special ability allows one to SPIN SPIN SPIN with all the grace of a trained proffessional: ability allows a user to spin attack for a certain amount of time with the added effect of pulling enemies closer (Hold {global.special_button} to activate attack)",
			effects: [
				{ stat: "special_equipped", op: "set"   ,     value: SpecialState.TSUNAMI},
			],
			spriteF: card_nautical_joker_spr,
			indexF: 2,
			spriteB: card_nautical_back_spr,
			indexB: 6,
			upgrades_possible : 1

		}
		,
					special_dance_of_dragons_unlock:
		{ //This attack should do the following: slow down time and the player should dash to each enemy
			//one by one giving us a second to click attack then to the next
			//once it has hit up to n enemies we will stop and all the attacks will register

			name: "The Dance of Dragons",
			special: true,
			desc: $"It is considered a great honor to be able to dance with a dragon as the power it gives is monumentous: the user is allowed to 'dance' around to enemies and is given a second to attack each one until the final slam. After each attack the breath of a dragon lingers on each enemy (Hold {global.special_button} to activate attack).",
			
			effects: [
			//greater defense: blocked hits drain 20% less of the guard meter
			{ stat: "dance_of_dragons_unlock", op:"set",value: true}
			],
			spriteF: card_fantasy_sword_spr,
			indexF: 12,
			spriteB: card_fantasy_back_spr,
			indexB: 3,
			upgrades_possible : 1

		}

				,
					Special_attack_butterfly:
		{

			name: "The Butterfly Effect",
			special: true,
			desc: $"One small change compounds over time: once activated the player can 'tag' enemies once it rewinds the player can send butterflies to specified tagged enemies doing massive damage (Hold {global.special_button} to activate attack)",
			
			effects: [
				{ stat: "special_attack_butterfly_unlock", op: "set",  value: true},
			],
			spriteF: card_forest_joker_spr,
			indexF: 1,
			spriteB: card_forest_back_spr,
			indexB: 3,
			upgrades_possible : 1,



		}


	}

}
//check if an upgrade can even happen
//if so it should be in the shuffle mix.

function upgradeCheckPossible(){




	var _available = [];
	var _keys = struct_get_names(global.Character_Upgrades);

	for (var i = 0; i < array_length(_keys); i++) {
		var _upg = global.Character_Upgrades[$ _keys[i]];
		if (_upg.upgrades_possible >= 1 && _upg.special == false) {
			array_push(_available, _upg);
		}
	}
	return _available;


}

function applyUpgrade(_upg){

	var _inst = instance_find(main_character_Obj,0);
	if (_inst == noone) return;   // no player to upgrade

	for (var i = 0; i < array_length(_upg.effects); i++) {
		var _eff = _upg.effects[i];

		// skip stats the player doesn't have yet (reading a missing variable would crash)
		if (!variable_instance_exists(_inst, _eff.stat)) {
			continue;
		}

		var _current = variable_instance_get(_inst, _eff.stat);
		var _new = _current;

		switch (_eff.op) {
			case "mult": _new = _current * _eff.value; break;
			case "add":  _new = _current + _eff.value; break;
			case "sub":  _new = _current - _eff.value; break;
			case "set":  _new = _eff.value;            break;
			default:
				break;   // unknown op: leave the stat unchanged
		}

		variable_instance_set(_inst, _eff.stat, _new);

		// max health went up: give the player the extra health too, so the health bar stays full
		if (_eff.stat == "total_hp") {
			_inst.hp += _new - _current;
		}
	}

	// counter damage is worked out from player_damage (same as in the player's Create), so redo it
	_inst.counter_damage = round(_inst.player_damage * 1.5);

	_upg.upgrades_possible -= 1;


}





