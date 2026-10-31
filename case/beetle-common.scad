// Beetle E1 case: shared dimensions and helpers.
//
// Included by beetle-base.scad, beetle-lid.scad and beetle-assembly.scad, so
// a change here applies to both printed parts.
//
// Coordinates in mm, with the case as mounted on the wall:
//   X to the right, Y up, Z out from the wall (the back of the base is z = 0).
//   X = 0, Y = 0 is the centre of the carrier board.

$fn = 48;

// ------------------------------------------------------------------ board
board_w = 56;
board_l = 101;
board_t = 1.8;
board_r = 3;

// KiCad board coordinates (origin top left, y down) to case coordinates.
function kicad(p) = [p[0] - board_w / 2, board_l / 2 - p[1]];

mount_holes = [for (p = [[3.5, 3.5], [52.5, 3.5], [3.5, 97.5], [52.5, 97.5]]) kicad(p)];

// Module PCB underside above the carrier board top: 8.5 mm female socket
// plus the 2.5 mm plastic spacer of the male pins.
header_stack = 11;

// CubeCell HTCC-AB01 V2 (datasheet: 1 mm PCB, USB-C 3 mm tall on top,
// centred on the short edge and sticking out 1.6 mm past it).
cc_x = [kicad([30.5, 0])[0], kicad([53.36, 0])[0]];
cc_y = [kicad([0, 100.5])[1], kicad([0, 59.86])[1]];
cc_pcb_t = 1;
usb_w = 9;
usb_h = 3.2;
usb_overhang = 1.6;
usb_x = kicad([41.93, 0])[0];

// BH1750 (GY-302) module centre, and the 18650 cell.
bh1750_pos = kicad([41.9, 45.8]);
cell_x = kicad([13.35, 0])[0];
cell_d = 18.6;
cell_lift = 1.2;        // holder floor under the cell

// ------------------------------------------------------------- base (tray)
floor_t = 2.4;
standoff = 5;           // gap under the board for pin tails and keyhole bosses
wall_t = 2;
side_gap = 0.4;         // board edge to wall, left/right
top_gap = 0.4;          // board top edge to wall
bottom_gap = 2.9;       // board bottom edge to wall, room for the clip

// Clip at the bottom edge of the board: a spring bar along the bottom wall,
// with a rounded bump that reaches in over the edge of the board.
clip_x = -7.75;         // centre, in line with the middle rib between the bottom vents
clip_l = 24;            // bar length, including the posts that hold it at the ends
clip_t = 1;             // bar thickness
clip_gap = 0.8;         // free space behind the bar
clip_over = 0.4;        // how far the bump reaches in over the board
clip_w = 3;             // bump width

board_z = floor_t + standoff;       // underside of the board
board_top = board_z + board_t;
usb_z = board_top + header_stack + cc_pcb_t + usb_h / 2;
// Notch in the bottom wall for the USB-C plug overmould. It is open at the
// top and a tab on the lid fills it, so the lid comes off for charging. On the
// right it runs on through the corner and up the side wall, so the tab joins
// the wing cover, and the reset button on the CubeCell can be reached with the
// lid off.
usb_hole = [14, 9];     // around the plug: the notch starts usb_hole[0] / 2 left of it
usb_notch_z = usb_z - usb_hole[1] / 2;
usb_side_open = 13;     // up the side wall to this far above the inside of the bottom wall

Bw = board_w / 2 + side_gap + wall_t;                           // half width
Yb_top = board_l / 2 + top_gap + wall_t;
Yb_bot = -(board_l / 2 + bottom_gap + wall_t);
base_r_top = 4;
base_r_bot = 8;         // follows the oval wing tips of the lid
Hb = 26;                // wall height; the battery reaches up into the lid

// Lip along the top of the base. The lid hooks in behind it.
lip_h = 1.8;            // how far it stands up from the top face
lip_t = 2.4;
lip_x = 25.5;           // half length
lip_bevel = 1.6;        // size of the 45° bevels on its outer edges

// Keyhole slots for hanging the case on two screws (head up to 8.5 mm).
key_pos = [[-14, 20], [14, 20]];
key_head_d = 8.5;
key_shank_d = 4.4;
key_slot = 8;           // the slot runs up from the entry hole
key_back_t = 2;         // material between the screw head and the wall
key_pocket_d = 9;
key_pocket_h = 3.2;
key_boss_h = key_back_t + key_pocket_h + 1;
assert(key_boss_h < board_z - 0.5, "keyhole bosses touch the board");

// LoRa antenna tunnel on the inside of the right-hand wall. The antenna is
// pushed in from below.
ant_d = 4.5;            // tunnel bore
ant_x = Bw - wall_t - ant_d / 2 - 0.3;
ant_z = Hb - 4.5;
ant_y = [Yb_top - wall_t - 21, Yb_top - wall_t - 7];    // 21 to 7 mm below the top wall

// Intake slots in the bottom wall, sheltered by the wing tips.
vent_bottom_w = 1.8;
vent_bottom_x = [-19, -14.5, -10, -5.5, -1, 3.5];
vent_bottom_z = 13;

// --------------------------------------------------------------------- lid
lid_clr = 0.3;          // lid to base, all round
lid_t = 2;
skirt_z = usb_notch_z + lid_clr;    // lower edge of the lid all round (the print bed side)
hook_clr = 0.4;         // lid hook to base lip
ledge_h = 1.5;          // inner ledge that rests on top of the base walls

// Snap beads on the outside of the base side walls, matched by grooves in
// the lid skirt.
snap_z = skirt_z + 2.5;
snap_h = 0.75;          // how far the bead sticks out (0.45 mm past the lid)
snap_w = 2.7;           // bead width at the wall
snap_y = [-38, -12];
snap_clr = 0.15;

W_el = Bw + lid_clr + lid_t;    // half width of the wing covers
elytra_b = 7;           // dome height above the base wall
elytra_k = 14.5 / W_el; // dome centres at ±k·w; the domes meet in a seam at X = 0

W_th = W_el + 1.5;      // the thorax is a bit wider ...
thorax_b = 13;          // ... and stands out further, over the top vents
thorax_k = 10 / W_th;   // and is rounder, with only a faint centre line
assert(board_top + cell_lift + cell_d + 1.5 <= Hb + elytra_b - lid_t, "battery touches the lid");

plate_y = Yb_top + lip_h + lid_clr;     // underside of the lid top, above the lip
Y_top = plate_y + 3.5;  // top of the oval, at X = 0
top_oval = 12;          // height of the oval top
crown_r = 7;            // side view rounding of the thorax top edge
thorax_len = 28;
collar_len = 3.5;       // the thorax lip hangs down in front of the top vents

oval_up = 8;            // the oval wing tips start this far above the base bottom ...
hood_len = 8;           // ... and end this far below it
tip_x = 3;              // makes the tips meet in a slight point at the seam

Y_tc = Y_top - top_oval;
Y_lip = Y_top - thorax_len;     // underside of the step from thorax to wing covers
Y_oc = Yb_bot + oval_up;
Y_end = Yb_bot - hood_len;
oval_b = (oval_up + hood_len) / sqrt(1 - pow(tip_x / (W_el + tip_x), 2));

// Light window over the BH1750: the lid is thinned from the inside.
win_d = 20;
win_t = 0.4;

// Top vents: slots through the step under the thorax lip, opening downwards.
vent_w = 2.8;
vent_top_x = [3.2, 7.2, 11.2, 15.2, 19.2, 23.2];
// Bottom vents: slots through the end wall of the lid, under the wing tips.
vent_end_x = [for (x = [-24 : 4 : 24]) x];

// Beetle details: ridges on the wing covers ([x, y from, y to]).
ridge_r = 0.9;
ridges = [[9, 25, -50], [16.5, 25, -46], [24, 25, -40]];

nh = 20;                // profile points per dome

// ----------------------------------------------------------------- helpers
function qsort_desc(v) = len(v) <= 1 ? v :
    let(p = v[floor(len(v) / 2)])
    concat(qsort_desc([for (x = v) if (x > p) x]), [for (x = v) if (x == p) x],
           qsort_desc([for (x = v) if (x < p) x]));
function uniq_desc(v) = let(s = qsort_desc(v))
    [for (i = [0 : len(s) - 1]) if (i == 0 || s[i] < s[i - 1] - 1e-4) s[i]];
function frange(a, b, s) = [for (y = [a : s : b]) y];

// Cross-section (X, Z) of the lid: vertical sides from zs up to the base wall
// height, then two half-ellipse domes centred at X = ±c that meet in a seam
// at X = 0.
function hump_profile(w, b, c, zs, n = nh) =
    let(a = w - c, ps = acos(c / a))
    concat(
        [[-w, zs]],
        [for (i = [0 : n]) let(p = 180 - i * (180 - ps) / n) [-c + a * cos(p), Hb + b * sin(p)]],
        [for (i = [n - 1 : -1 : 0]) let(p = 180 - i * (180 - ps) / n) [c - a * cos(p), Hb + b * sin(p)]],
        [[w, zs]]);

// Lid seen from the front: half width at height y. Oval top, thorax, wing
// covers, oval wing tips.
function lid_w(y) =
    y > Y_tc ? W_th * pow(max(0, 1 - pow((y - Y_tc) / top_oval, 3)), 1 / 3)
    : y >= Y_lip ? W_th
    : y >= Y_oc ? W_el
    : max(0, (W_el + tip_x) * sqrt(max(0, 1 - pow((Y_oc - y) / oval_b, 2))) - tip_x);

// Lid seen from the side: dome height above the base wall at height y.
function lid_b(y) =
    y > Y_top - crown_r ? thorax_b - crown_r + sqrt(max(0, pow(crown_r, 2) - pow(y - Y_top + crown_r, 2)))
    : y >= Y_lip ? thorax_b
    : y >= Yb_bot ? elytra_b
    : elytra_b * sqrt(max(0, 1 - pow((Yb_bot - y) / hood_len, 2)));

function lid_k(y) = y >= Y_lip ? thorax_k : elytra_k;

// [half width, dome height, dome offset, lower edge] of the outside ...
function lid_outer(y) = let(w = lid_w(y)) [w, lid_b(y), lid_k(y) * w, skirt_z];

// ... and of the inside. The wall is kept lid_t thick where the outline
// slopes along y, and the step under the thorax is lid_t thick too.
function lid_dw(y) = (lid_w(y + 0.05) - lid_w(y - 0.05)) / 0.1;
function lid_db(y) = (lid_b(y + 0.05) - lid_b(y - 0.05)) / 0.1;
function lid_inner(y, zs) =
    let(ye = y >= Y_lip && y < Y_lip + lid_t ? Y_lip - 0.2 : y,
        w = lid_w(ye) - lid_t * sqrt(1 + pow(lid_dw(ye), 2)),
        b = max(0.3, lid_b(ye) - lid_t * sqrt(1 + pow(lid_db(ye), 2))))
    [w, b, min(lid_k(ye) * lid_w(ye), 0.47 * w), zs];

// Slice heights, dense where the shape changes.
lid_outer_ys = uniq_desc(concat(
    [Y_top - 0.02, Y_top - 0.1, Y_top - 0.25], frange(Y_tc, Y_top - 0.5, 0.5),
    [Y_lip, Y_lip - 0.01],
    [Yb_bot], frange(Y_end + 0.5, Y_oc, 0.5), [Y_end + 0.25, Y_end + 0.1, Y_end + 0.03]));

// Inside of the lid over the base: from under the lid top down to the end
// wall that sits on the bottom wall of the base.
lid_main_y = [Yb_bot + wall_t + lid_clr, plate_y];
lid_main_ys = uniq_desc(concat(
    [lid_main_y[1]], frange(Y_tc, lid_main_y[1], 0.5),
    [Y_lip + lid_t, Y_lip + lid_t - 0.01],
    frange(lid_main_y[0], Y_oc, 0.5), [lid_main_y[0], Y_oc]));

// Inside of the wing tips, open towards the wall: the air intake.
lid_hood_ys = uniq_desc(concat(
    [for (y = frange(Y_end, Yb_bot - lid_clr, 0.5)) if (lid_inner(y, 0)[0] >= 3) y], [Yb_bot - lid_clr]));

// ----------------------------------------------------------------- modules

// Skin through a list of cross-sections. Each slice is a list of [x, y, z]
// points with the same count; slices are ordered by decreasing y.
module loft(slices) {
    n = len(slices);
    N = len(slices[0]);
    faces = concat(
        [[for (i = [N - 1 : -1 : 0]) i]],
        [[for (i = [0 : N - 1]) (n - 1) * N + i]],
        [for (j = [0 : n - 2], i = [0 : N - 1])
            let(a = j * N + i, b = j * N + (i + 1) % N, c = (j + 1) * N + (i + 1) % N, d = (j + 1) * N + i)
            each [[a, b, c], [a, c, d]]]);
    polyhedron(points = [for (s = slices) each s], faces = faces, convexity = 10);
}

function lid_slice(p, y) = [for (q = hump_profile(p[0], p[1], p[2], p[3])) [q[0], y, q[1]]];

// A 2D shape in the (X, Z) plane, extruded along Y from y0 to y1.
module extrude_y(y0, y1) {
    translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
}

// Outline of the base seen from the front, grown by d.
module base_outline_2d(d = 0) {
    offset(r = d) hull()
        for (sx = [-1, 1]) {
            translate([sx * (Bw - base_r_top), Yb_top - base_r_top]) circle(r = base_r_top);
            translate([sx * (Bw - base_r_bot), Yb_bot + base_r_bot]) circle(r = base_r_bot);
        }
}

// Lid cross-sections at fixed heights, as 2D shapes in the (X, Z) plane.
module lid_section_2d(p) polygon(hump_profile(p[0], p[1], p[2], p[3]));
module elytra_outer_2d() lid_section_2d(lid_outer(0));
module thorax_inner_2d() lid_section_2d(lid_inner(Y_lip + lid_t + 1, Hb - 1));

// Snap bead profile in the (X, Z) plane, at the wall surface x = 0.
module snap_bead_2d(grow = 0) {
    offset(delta = grow)
        polygon([[-0.5, -snap_w / 2], [0, -snap_w / 2], [snap_h, snap_h - snap_w / 2],
                 [snap_h, snap_w / 2 - snap_h], [0, snap_w / 2], [-0.5, snap_w / 2]]);
}

module snap_beads(grow = 0) {
    for (m = [0, 1]) mirror([m, 0, 0])
        extrude_y(snap_y[0] - grow, snap_y[1] + grow) translate([Bw, snap_z]) snap_bead_2d(grow);
}

// USB-C notch in the bottom wall, as a 2D shape in the (X, Z) plane, grown by d.
module usb_notch_2d(d = 0) {
    r = 1.5;
    x = [usb_x - usb_hole[0] / 2, Bw + 2];
    offset(delta = d) hull() {
        for (xi = [x[0] + r, x[1] - r]) translate([xi, usb_notch_z + r]) circle(r = r);
        translate([x[0], Hb]) square([x[1] - x[0], 5]);
    }
}

// The whole notch, grown by d: through the bottom wall, the rounded corner on
// the right and the bottom of the right-hand wall, where it ends in the same
// rounded corner, seen from the side (Y, Z).
module usb_notch(d = 0) {
    r = 1.5;
    y = [Yb_bot - 1, Yb_bot + wall_t + usb_side_open];
    intersection() {
        extrude_y(y[0], y[1] + 1) usb_notch_2d(d);
        translate([-Bw - 5, 0, 0]) rotate([90, 0, 90]) linear_extrude(2 * Bw + 10) offset(delta = d) hull() {
            translate([y[1] - r, usb_notch_z + r]) circle(r = r);
            translate([y[0], usb_notch_z]) square([1, Hb + 5 - usb_notch_z]);
            translate([y[0], Hb]) square([y[1] - y[0], 5]);
        }
    }
}

// The lip on top of the base, grown by d (and lowered by dz at the back).
module lip(d = 0, dz = 0) {
    translate([-lip_x - d, Yb_top - 1, Hb - lip_t - dz]) cube([2 * (lip_x + d), 1 + lip_h + d, lip_t + dz]);
}
