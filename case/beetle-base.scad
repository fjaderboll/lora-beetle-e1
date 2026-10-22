// Beetle E1 case: base (wall plate and tray for the carrier board).
//
// Shown in print orientation: back on the bed, no supports needed.
//
// Hang it on two screws through the keyhole slots (28 mm apart, level).
// Then slide the top edge of the board under the two lips at the top and
// press the bottom edge down until the hook clicks. To take the board out,
// push the hook towards the bottom wall and lift that end.

include <beetle-common.scad>

beetle_base();

module beetle_base() {
    difference() {
        union() {
            linear_extrude(floor_t) base_outline_2d();
            linear_extrude(Hb) difference() {
                base_outline_2d();
                base_outline_2d(-wall_t);
            }
            lip();
            keyhole_bosses();
            board_supports();
            antenna_clips();
            snap_beads();
        }
        keyhole_cuts();
        usb_hole();
        bottom_vents();
        hook_relief();
        // Bevels on the lip so the lid can swing on and off.
        for (z = [Hb - lip_t, Hb]) translate([0, Yb_top + lip_h, z]) rotate([45, 0, 0])
            cube([2 * lip_x + 2, 1.6, 1.6], center = true);
    }
    board_hook();
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

post_d = 6.5;
pin_d = 2.8;
top_lips = [[-20, -8], [8, 20]];    // X ranges, clear of the mounting holes
lip_overlap = 1.5;                  // over the top edge of the board

module board_supports() {
    // Posts under the mounting holes, with locating pins in the bottom two.
    for (p = mount_holes) translate(p) cylinder(d = post_d, h = board_z);
    for (p = [mount_holes[2], mount_holes[3]]) translate([p[0], p[1], board_z]) {
        translate([0, 0, -1]) cylinder(d = pin_d, h = board_t + 1.2);
        translate([0, 0, board_t + 0.2]) cylinder(d1 = pin_d, d2 = pin_d - 0.8, h = 0.6);
    }
    // Slot for the top edge of the board: a ledge under it and lips over it.
    y0 = board_l / 2 - lip_overlap;
    y1 = board_l / 2 + top_gap + 0.5;
    for (r = top_lips) {
        translate([r[0], y0, 0]) cube([r[1] - r[0], y1 - y0, board_z]);
        translate([r[0], y0, board_top + 0.25]) cube([r[1] - r[0], y1 - y0, 1.5]);
    }
    // Ledges under the long edges, half way up.
    for (s = [-1, 1]) translate([s * (board_w / 2 + side_gap / 2 - 0.25) - 1.25, -6, 0])
        cube([2.5, 12, board_z]);
}

// Flexible hook that catches the bottom edge of the board.
hook_face = -board_l / 2 - hook_gap;
hook_root = floor_t - 1.4;
hook_top = board_top + 0.2 + hook_ramp + 1.5;

module board_hook() {
    translate([hook_x[0], hook_face - hook_t, hook_root])
        cube([hook_x[1] - hook_x[0], hook_t, hook_top - hook_root]);
    // Catch with a lead-in ramp, seen from the side (Y, Z).
    translate([hook_x[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(hook_x[1] - hook_x[0])
        polygon([[hook_face - 0.01, board_top + 0.2], [hook_face + hook_catch, board_top + 0.2],
                 [hook_face - 0.01, board_top + 0.2 + hook_ramp]]);
}

// Lowers the floor around the hook so the arm is longer and bends easier.
module hook_relief() {
    translate([hook_x[0] - 1, hook_face - hook_t - hook_flex, hook_root])
        cube([hook_x[1] - hook_x[0] + 2, hook_t + hook_flex + 0.6, floor_t]);
}

// ----------------------------------------------------------------- antenna

// Cradles on the right-hand wall; the antenna presses in from the front.
module antenna_clips() {
    xin = Bw - wall_t;
    xc = xin - ant_d / 2 - 0.3;
    ro = ant_d / 2 + 1.4;
    for (y = ant_clip_y) extrude_y(y - ant_clip_l / 2, y + ant_clip_l / 2) difference() {
        union() {
            translate([xc, ant_z]) circle(r = ro);
            // 45° gusset underneath, so it prints without support.
            polygon([[xin + 0.5, ant_z - (xin + 0.5 - xc + ro)], [xin + 0.5, ant_z], [xc - ro, ant_z]]);
        }
        translate([xc, ant_z]) circle(d = ant_d);
        translate([xc - ant_d * 0.4, ant_z]) square([ant_d * 0.8, ro + 1]);
    }
}

// ------------------------------------------------------------- bottom wall

module usb_hole() {
    extrude_y(Yb_bot - 1, Yb_bot + wall_t + 1) usb_notch_2d();
}

module bottom_vents() {
    extrude_y(Yb_bot - 1, Yb_bot + wall_t + 1)
        for (x = vent_bottom_x) translate([x - vent_bottom_w / 2, vent_bottom_z])
            square([vent_bottom_w, Hb - 2.5 - vent_bottom_z]);
}
