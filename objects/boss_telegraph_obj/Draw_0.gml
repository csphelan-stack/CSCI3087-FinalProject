// ============================================================
// BOSS TELEGRAPH - DRAW
// ============================================================

// The two sides of the lane and its far end.
var _px = lengthdir_x(width / 2, dir + 90);
var _py = lengthdir_y(width / 2, dir + 90);
var _ex = lengthdir_x(length, dir);
var _ey = lengthdir_y(length, dir);

// How far through the windup we are (0 to 1).
var _progress = clamp(timer / max(windup, 1), 0, 1);

// In the last moments the aim is locked and the lane flashes.
var _locked = (timer >= windup - 14);

draw_set_colour(colour);

// ---------- the whole lane, faint ----------
var _alpha = 0.14;

if (_locked)
{
    _alpha = 0.22 + 0.12 * sin(timer * 1.1);
}

draw_set_alpha(_alpha);
draw_triangle(x + _px, y + _py, x - _px, y - _py, x - _px + _ex, y - _py + _ey, false);
draw_triangle(x + _px, y + _py, x - _px + _ex, y - _py + _ey, x + _px + _ex, y + _py + _ey, false);

// ---------- the part that fills up as the attack gets closer ----------
var _fx = _ex * _progress;
var _fy = _ey * _progress;

draw_set_alpha(0.34);
draw_triangle(x + _px, y + _py, x - _px, y - _py, x - _px + _fx, y - _py + _fy, false);
draw_triangle(x + _px, y + _py, x - _px + _fx, y - _py + _fy, x + _px + _fx, y + _py + _fy, false);

// ---------- the edges of the lane ----------
draw_set_alpha(0.85);
draw_line_width(x + _px, y + _py, x + _px + _ex, y + _py + _ey, 2);
draw_line_width(x - _px, y - _py, x - _px + _ex, y - _py + _ey, 2);
draw_line_width(x + _px + _ex, y + _py + _ey, x - _px + _ex, y - _py + _ey, 2);

// Put the drawing settings back to normal.
draw_set_alpha(1);
draw_set_colour(c_white);
