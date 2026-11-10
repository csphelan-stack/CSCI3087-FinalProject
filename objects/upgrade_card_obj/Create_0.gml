

was_owas_over = false;   //true once the mouse is already on this card, so the hover sound only plays on entryver = false;


upg = undefined;

card_x = 0;
card_y = 0;
card_w = 92;
card_h = 140;

//this is what determines whether or not the card is face down or up 0 = down
flip = 0;

flip_spd = 0.08;
revealed = false;
hovered = false;

//where the card sits in the row (the dealer sets these, so "No" can put it back)
home_x = 0;
home_y = 0;
home_w = 92;
home_h = 140;

card_alpha = 0.9;   //see-through amount (the dealer fades the cards it didn't pick)

//burning: 0 = whole card, about 1.3 = all gone
burning = false;
burn = 0;
//each pixel column burns a bit ahead or behind the others so the edge looks ragged
burn_offset = array_create(23);
for (var i = 0; i < 23; i++) {
	burn_offset[i] = random(0.3);
}