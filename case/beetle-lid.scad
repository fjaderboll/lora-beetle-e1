// Beetle E1 case: lid (thorax and wing covers).
//
// Shown in print orientation: open side down. Supports from the build plate
// only, for the inside of the domes. Print in white so the light sensor
// sees daylight through the thin window.
//
// The hook along the top edge goes in behind the lip on the base. Swing the
// lid down onto the base until the side snaps click. To open, pull the wing
// tips away from the wall.

include <beetle-common.scad>

beetle_lid_print();

module beetle_lid_print() {
    translate([0, 0, -skirt_z]) beetle_lid();
}

// The lid in mounted position.
module beetle_lid() {
    difference() {
        union() {
            difference() {
                loft([for (y = lid_outer_ys) lid_slice(lid_outer(y), y)]);
                loft([for (y = lid_main_ys) lid_slice(lid_inner(y, Hb - 0.01), y)]);
                loft([for (y = lid_hood_ys) lid_slice(lid_inner(y, skirt_z - 1), y)]);
                translate([0, 0, -1]) linear_extrude(Hb + 1) base_outline_2d(lid_clr);
                lip(lid_clr, hook_clr);
                top_vents();
                end_vents();
                light_window();
            }
            ledge();
            collar();
            ridges();
            scutellum();
        }
        snap_beads(snap_clr);
    }
}

// Rests on top of the base walls.
module ledge() {
    translate([0, 0, Hb]) linear_extrude(ledge_h) difference() {
        base_outline_2d(lid_clr);
        base_outline_2d(lid_clr - wall_t);
    }
}

// Through the step under the thorax, so they open downwards.
module top_vents() {
    extrude_y(Y_lip - 1, Y_lip + lid_t + 1) intersection() {
        difference() {
            offset(delta = -0.4) thorax_inner_2d();
            offset(delta = 0.4) elytra_outer_2d();
        }
        for (s = [-1, 1], x = vent_top_x)
            translate([s * x - vent_w / 2, Hb + ledge_h + 0.5]) square([vent_w, 30]);
    }
}

// Through the end wall over the bottom of the base, from under the wing tips.
module end_vents() {
    extrude_y(Yb_bot - lid_clr - 1, Yb_bot + wall_t + lid_clr + 1) intersection() {
        offset(delta = -0.6) lid_section_2d(lid_inner(Yb_bot - lid_clr, Hb - 1));
        offset(delta = -0.6) lid_section_2d(lid_inner(Yb_bot + wall_t + lid_clr, Hb - 1));
        for (x = vent_end_x) translate([x - vent_w / 2, Hb + ledge_h + 0.4]) square([vent_w, 30]);
    }
}

// The thorax lip: hangs down in front of the top vents and sheds rain.
module collar() {
    extrude_y(Y_lip - collar_len, Y_lip + 0.01) difference() {
        lid_section_2d(lid_outer(Y_lip));
        offset(delta = -1.6) lid_section_2d(lid_outer(Y_lip));
        translate([-Bw - lid_clr, 0]) square([2 * (Bw + lid_clr), Hb]);
    }
}

// Thins the wing cover to win_t over the BH1750.
module light_window() {
    intersection() {
        translate([bh1750_pos[0], bh1750_pos[1], Hb + 2]) cylinder(d = win_d, h = 20);
        extrude_y(bh1750_pos[1] - win_d, bh1750_pos[1] + win_d) offset(delta = -win_t) elytra_outer_2d();
    }
}

function elytra_z(x) = let(p = lid_outer(0), u = (abs(x) - p[2]) / (p[0] - p[2]))
    Hb + p[1] * sqrt(max(0, 1 - u * u));

module ridges() {
    for (s = [-1, 1], r = ridges)
        hull() for (y = [r[1], r[2]]) translate([s * r[0], y, elytra_z(r[0])]) sphere(r = ridge_r, $fn = 12);
}

// The small triangle between the wing covers, just under the thorax.
module scutellum() {
    translate([0, 0, Hb + 4.1]) linear_extrude(elytra_b + 0.6 - 4.1) hull() {
        for (s = [-1, 1]) translate([s * 4, Y_lip - 1.5]) circle(r = 1.5);
        translate([0, Y_lip - 15]) circle(r = 1.2);
    }
}
