// move 15% of the remaining distance each step: fast at first, slowing at the edge
radius += (max_radius - radius) * spread;

// basically at full size? it's done
if (radius >= max_radius - 1) {
    instance_destroy();
}
