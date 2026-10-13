if (hp<=0){ 
	 game_restart();
	}
	
	
if(attack_cooldown >0){
attack_cooldown-=1;	
}
	
if(dash_cooldown>0){
dash_cooldown-=1;	
}

if(invuln > 0){
invuln -= 1;
}

if(parry_cooldown>0){
parry_cooldown-=1;	
}
	
switch (state){
	
	case PlayerState.NORMAL:
		applyMovement();
		break;
	case PlayerState.ATTACK:
		attackStatePlayer();
		break;
	case PlayerState.DASH:
		dashStateMC();
		break;
	case PlayerState.PARRY:
		parryStateMC();
		break;
}