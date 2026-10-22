// Beetle E1 case: base, lid and a mock-up of the board, as mounted on the
// wall (X right, Y up, Z out from the wall). For viewing only, print the
// parts from beetle-base.scad and beetle-lid.scad.

include <beetle-common.scad>
use <beetle-base.scad>
use <beetle-lid.scad>

/* [View] */
show_base = true;
show_board = true;
show_lid = true;
// Moves the lid away from the wall.
explode = 0;    // [0:5:60]
// Swings the lid open around the top hook, as when fitting it.
open_angle = 0; // [0:1:30]
// Cuts the model open along X = section_x (0 = off).
section = false;
section_x = 13.9;   // [-30:0.5:30]

module view() {
    if (show_base) color("#d8d6cc") beetle_base();
    if (show_board) board_mockup();
    if (show_lid) color("#3b6d11")
        translate([0, 0, explode])
            translate([0, Yb_top + lid_clr, skirt_z]) rotate([-open_angle, 0, 0])
                translate([0, -Yb_top - lid_clr, -skirt_z])
                beetle_lid();
}

if (section)
    difference() {
        view();
        translate([section_x, -100, -10]) cube([100, 200, 100]);
    }
else
    view();

// ------------------------------------------------------------ board mock-up

module board_mockup() {
    // Carrier board.
    color("#2f6b3a") translate([0, 0, board_z]) linear_extrude(board_t) difference() {
        offset(r = board_r) square([board_w - 2 * board_r, board_l - 2 * board_r], center = true);
        for (p = mount_holes) translate(p) circle(d = 3.2);
    }

    // 18650 cell in its holder.
    color("#333") translate([cell_x - 20.75 / 2, -38.6, board_top]) difference() {
        cube([20.75, 77.2, 14.86]);
        translate([1, 1, 1.2]) cube([18.75, 75.2, 20]);
    }
    color("#d87ab0") translate([cell_x, -32.5, board_top + cell_lift + cell_d / 2])
        rotate([-90, 0, 0]) cylinder(d = cell_d, h = 65);

    // CubeCell on its two sockets, with the USB-C port at the bottom edge.
    for (x = [kicad([31.79, 0])[0], kicad([52.07, 0])[0]])
        color("#222") translate([x - 1.27, kicad([0, 91.42])[1], board_top]) cube([2.54, 28.04, 8.5]);
    translate([cc_x[0], cc_y[0], board_top + header_stack]) {
        color("#111") cube([cc_x[1] - cc_x[0], cc_y[1] - cc_y[0], cc_pcb_t]);
        color("silver") translate([5, 18, cc_pcb_t]) cube([16, 12, 2.2]);
    }
    color("silver") translate([usb_x - usb_w / 2, cc_y[0] - usb_overhang, board_top + header_stack + cc_pcb_t])
        cube([usb_w, 7.4, usb_h]);

    // BME280 (sensor side down) and BH1750 (sensor side up) on their sockets.
    sensor(kicad([40.63, 9]), 15.5, -12, "#5b2a86");
    sensor(kicad([41.9, 53.5]), 13.9, 18, "#1e4f9c");

    // Spring antenna in its clips.
    color("#111") translate([Bw - wall_t - ant_d / 2 - 0.3, -8, ant_z]) rotate([-90, 0, 0])
        cylinder(d = 5, h = 56);
}

// Pin row at p; the module body runs `len` along Y from it (negative = down).
module sensor(p, w, len, c) {
    color("#222") translate([p[0] - w / 2 + 0.6, p[1] - 1.27, board_top]) cube([w - 1.2, 2.54, 8.5]);
    color(c) translate([p[0] - w / 2, len > 0 ? p[1] - 1.3 : p[1] + 1.3 + len, board_top + header_stack])
        cube([w, abs(len), 1.6]);
}
