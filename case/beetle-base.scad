// Beetle E1 case: base (wall plate and tray for the carrier board).
//
// Shown in print orientation: back on the bed, no supports needed.
//
// Hang it on two screws through the keyhole slots (28 mm apart, level).
// Then slide the top end of the board into the slot at the top, under the
// antenna tunnel, and press the bottom edge down until it snaps in under the
// clip on the bottom wall. To take the board out, pull the antenna out of the
// tunnel, lift the bottom end past the clip and pull the board out of the slot.

include <beetle-common.scad>

beetle_base();

module beetle_base() {
    difference() {
        union() {
            linear_extrude(floor_t) base_outline_2d();
            linear_extrude(Hb, convexity = 4) difference() {
                base_outline_2d();
                base_outline_2d(-wall_t);
            }
            lip();
            keyhole_bosses();
            board_supports();
            antenna_tunnel();
            snap_beads();
        }
        keyhole_cuts();
        usb_notch();
        bottom_vents();
        clip_relief();
        // Bevels on the lip so the lid can swing on and off.
        for (z = [Hb - lip_t, Hb]) translate([0, Yb_top + lip_h, z]) rotate([45, 0, 0])
            cube([2 * lip_x + 2, lip_bevel, lip_bevel], center = true);
    }
    board_clip();
}

// ---------------------------------------------------------------- keyholes

module keyhole_2d(d) {
    hull() {
        circle(d = d);
        translate([0, key_slot]) circle(d = d);
    }
}

module keyhole_bosses() {
    for (p = key_pos) translate(p) linear_extrude(key_boss_h) offset(r = 1.6) keyhole_2d(key_pocket_d);
}

// Entry hole for the screw head, slot for the shank above it and a closed
// pocket behind the slot for the head.
module keyhole_cuts() {
    for (p = key_pos) translate(p) {
        translate([0, 0, -1]) cylinder(d = key_head_d, h = key_back_t + key_pocket_h + 1);
        translate([0, 0, -1]) linear_extrude(key_back_t + 1.01) keyhole_2d(key_shank_d);
        translate([0, 0, key_back_t]) linear_extrude(key_pocket_h) keyhole_2d(key_pocket_d);
    }
}

// ------------------------------------------------------------ board mount

pin_d = 2.8;
bar_w = 6.5;        // how far the end bars reach in under the board
slot_overlap = 1.5; // how far the bar over the top slot reaches over the board

module board_supports() {
    // Bars across the top and bottom ends, merged into the walls, with
    // locating pins for the bottom two mounting holes.
    linear_extrude(board_z) intersection() {
        base_outline_2d();
        for (m = [0, 1]) mirror([0, m]) translate([-Bw, board_l / 2 - bar_w]) square([2 * Bw, 10]);
    }
    // Bar over the top edge of the board: with the bar under it, a slot that
    // keeps the board in when the case is moved around.
    translate([0, 0, board_top + 0.25]) linear_extrude(1.5) intersection() {
        base_outline_2d();
        translate([-Bw, board_l / 2 - slot_overlap]) square([2 * Bw, 10]);
    }
    for (p = [mount_holes[2], mount_holes[3]]) translate([p[0], p[1], board_z]) {
        translate([0, 0, -1]) cylinder(d = pin_d, h = board_t + 1.2);
        translate([0, 0, board_t + 0.2]) cylinder(d1 = pin_d, d2 = pin_d - 0.8, h = 0.6);
    }
    // Ledges under the long edges, half way up.
    for (s = [-1, 1]) translate([s * (board_w / 2 + side_gap / 2 - 0.25) - 1.25, -6, 0])
        cube([2.5, 12, board_z]);
}

// Spring bar along the bottom wall, held at its ends by two posts, with a
// rounded bump that reaches in over the bottom edge of the board and holds it
// down. The bar bends sideways, along the print layers, so it doesn't snap.
clip_post = 2;                          // post width
clip_yb = Yb_bot + wall_t + clip_gap;   // back of the bar
clip_yf = clip_yb + clip_t;             // front of the bar

module board_clip() {
    // Bump seen from the side (Y, Z): a rounded tip, 45° underneath so it
    // prints without support, and a lead-in on top at 30° from vertical. The
    // top corner of the board just touches the underside.
    r = 0.6;
    a = 30;
    c = [-board_l / 2 + clip_over - r, board_top + clip_over + (sqrt(2) - 1) * r];
    z_lo = c[1] - (c[0] - clip_yf) - sqrt(2) * r;
    z_hi = c[1] + r * sin(a) + (c[0] + r * cos(a) - clip_yf) / tan(a);
    x0 = clip_x - clip_l / 2;
    translate([x0, clip_yb, board_z]) cube([clip_l, clip_t, z_hi - board_z]);
    for (x = [x0, x0 + clip_l - clip_post])
        translate([x, Yb_bot + wall_t - 0.01, board_z - 0.01]) cube([clip_post, clip_gap + 0.02, z_hi - board_z + 0.01]);
    translate([clip_x - clip_w / 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(clip_w) hull() {
        translate(c) circle(r = r);
        translate([clip_yf - 0.01, z_lo]) square([0.01, z_hi - z_lo]);
    }
}

// Lowers the bottom end bar under the spring bar, so the bar is free to bend.
module clip_relief() {
    translate([clip_x - clip_l / 2 + clip_post, Yb_bot + wall_t - 0.01, board_z - 2])
        cube([clip_l - 2 * clip_post, clip_gap + clip_t + 0.5, 2.01]);
}

// ----------------------------------------------------------------- antenna

// Tunnel on the right-hand wall; the antenna is pushed in from below.
module antenna_tunnel() {
    xin = Bw - wall_t;
    ro = ant_d / 2 + 1.4;
    zw = ant_z - sqrt(2) * ro - (xin - ant_x);  // where the underside meets the wall
    lead = 0.6;                                 // lead-in at the lower end
    difference() {
        // 45° underside down to the wall, so it prints without support.
        extrude_y(ant_y[0], ant_y[1]) hull() {
            translate([ant_x, ant_z]) circle(r = ro);
            translate([xin - 0.01, zw]) square([0.5, ant_z - zw]);
        }
        extrude_y(ant_y[0] - 1, ant_y[1] + 1) translate([ant_x, ant_z]) circle(d = ant_d);
        translate([ant_x, ant_y[0] - 0.01, ant_z]) rotate([-90, 0, 0])
            cylinder(d1 = ant_d + 2 * lead, d2 = ant_d, h = lead);
    }
}

// ------------------------------------------------------------- bottom wall

module bottom_vents() {
    extrude_y(Yb_bot - 1, Yb_bot + wall_t + 1)
        for (x = vent_bottom_x) translate([x - vent_bottom_w / 2, vent_bottom_z])
            square([vent_bottom_w, Hb - 2.5 - vent_bottom_z]);
}
