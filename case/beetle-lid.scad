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

/* [View] */
// Turns the lid over to show the inside (turn off again before exporting).
upside_down = false;

if (upside_down) rotate([0, 180, 0]) beetle_lid_print();
else beetle_lid_print();

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
                // Opens the wing tips up to the rounded corners of the base.
                extrude_y(Yb_bot - lid_clr - 0.01, Yb_bot + base_r_bot) intersection() {
                    lid_section_2d(lid_inner(Yb_bot - lid_clr, skirt_z - 1));
                    translate([-50, 0]) square([100, Hb]);
                }
                lip(lid_clr, hook_clr);
                top_vents();
                end_vents();
                light_window();
            }
            ledge();
            usb_tab();
            collar();
            ridges();
            scutellum();
        }
        snap_beads(snap_clr);
    }
}

// Rests on top of the base walls. At the top end it reaches over the lip to
// the top wall, so it prints without support.
module ledge() {
    translate([0, 0, Hb]) linear_extrude(ledge_h) difference() {
        base_outline_2d(lid_clr);
        base_outline_2d(lid_clr - wall_t);
    }
    // Over the lip, with a 45° fillet into the top wall that clears the outer
    // bevel on the lip by lid_clr. Seen from the side (Y, Z).
    f = lid_clr + lip_bevel / sqrt(2) - lid_clr * sqrt(2);
    translate([-lip_x - lid_clr, 0, 0]) rotate([90, 0, 90]) linear_extrude(2 * (lip_x + lid_clr))
        polygon([[Yb_top, Hb], [plate_y - f, Hb], [plate_y + 0.01, Hb - f - 0.01],
                 [plate_y + 0.01, Hb + ledge_h], [Yb_top, Hb + ledge_h]]);
}

// Fills the USB-C notch in the bottom wall of the base.
module usb_tab() {
    extrude_y(Yb_bot, Yb_bot + wall_t) intersection() {
        usb_notch_2d(-lid_clr);
        translate([-50, skirt_z]) square([100, Hb - skirt_z + 0.01]);
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

// The small triangle between the wing covers, just under the thorax. It
// leaves a 2 mm gap under the step for the middle top vents, and slopes down
// to the tip, which stands about 1 mm above the seam.
module scutellum() {
    z0 = Hb + 4.1;
    hull() {
        for (s = [-1, 1]) translate([s * 4, Y_lip - 3.5, z0]) cylinder(r = 1.5, h = elytra_b + 0.6 - 4.1);
        translate([0, Y_lip - 17, z0]) cylinder(r = 1.2, h = 1.1);
    }
}
