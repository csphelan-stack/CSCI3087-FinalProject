// healing font object

heal_radius   = 12;        // how close the player must be (gap between hitboxes, in room pixels)
heal_amount   = 10;
cooldown_time = 600;       // steps until it refills (60 = 1 second); set to 10 secs rn
cooldown      = 0;

auto_heal     = false;     // true = heals on walking up, false = press the key
interact_key  = ord("E");

image_speed = 0;           // the code picks the frame
is_full     = true;
can_use     = false;