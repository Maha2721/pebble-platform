/* ================================================================
   PEBBLE PLATFORM — Single Accessibility Top Case
   Logitech Research Project 4

   HOW TO USE:
   1. Download OpenSCAD FREE from: openscad.org
   2. Open this file, press F6 to render (~30 s)
   3. File → Export → Export as STL
   4. Open STL in Bambu Studio / PrusaSlicer, print
   5. Press 3 magnets in, snap onto Pebble M350s base

   STRUCTURE (matches the official Logitech top case):
   - Pill / stadium outline (two semicircles + straight sides)
   - Solid top surface with the scroll-wheel opening cut through it
   - OPEN bottom (fits down over the mouse) — when you flip it you
     see the interior: 2 rectangular click tabs + 3 magnet/screw bosses
   - Centre groove dividing the left and right click buttons

   COORDINATE CONVENTION:
     +Y = REAR  (palm / wrist ledge / rear magnet)
     -Y = FRONT (click buttons / scroll wheel)
     -X = LEFT ,  +X = RIGHT ,  Z=0 = base , Z=CASE_H = top

   Dimensions verified from official Logitech STP:
     19112025_Pebble_Simplified_Adaptio.stp
     Real M350s: 107.1 mm × 59.1 mm × 35.6 mm
   ================================================================ */

$fn = 80;

// ================================================================
// DIMENSIONS
// ================================================================
MOUSE_L   = 107.0;   // full length (STP: 107.1)
MOUSE_W   =  59.0;   // full width  (STP:  59.1)
CASE_H    =  15.0;   // top-case height — thin, low profile like the real M350s
                     // top cover (was 22; real cover is a thin shell).
                     // Minimum ~14 to still clear the base internals.
WALL_T    =   2.4;   // shell wall / ceiling thickness

// Scroll wheel slot (FRONT half of the mouse)
SW_W          = 14.0;
SW_L          = 22.0;
SW_FROM_FRONT = 33.0;   // from front edge toward centre
sw_cy = -MOUSE_L/2 + SW_FROM_FRONT;   // = -20.5  (front-of-centre)

// Wide accessibility scroll ring
RING_OD   = 36.0;
RING_T    =  3.5;
RING_WALL =  5.5;

// Magnet / screw bosses — N52 discs 6 mm dia × 3 mm
// Triangle: LEFT-centre, RIGHT-centre, REAR-centre (opposite the buttons)
MAG_D       =  6.3;   // hole diameter (6 + 0.3 clearance)
MAG_DEPTH   =  3.2;   // hole depth   (3 + 0.2 clearance)
MAG_X       = 18.0;   // left/right offset
MAG_Y_SIDE  = 10.0;   // side pair, toward middle
MAG_Y_REAR  = 40.0;   // rear single, near rear edge
BOSS_OD     = 10.0;   // boss cylinder diameter
BOSS_BOTTOM =  1.5;   // Z of the boss bottom face (where the magnet sits)

// Click actuator tabs — press the internal L/R switches
CLICK_W      =  9.0;   // width  (X)
CLICK_L      =  8.0;   // depth  (Y)
CLICK_X      = 13.0;   // ± offset from centre
CLICK_Y      = -35.0;  // front area, near the buttons
// Tab bottom Z — must sit JUST above the base click switch so the flap
// only travels ~1 mm to actuate it. TUNE THIS after measuring your base:
// lower value = tab reaches further down toward the switch.
CLICK_BOTTOM =  3.0;

// Wrist support ledge (REAR)
WRIST_EXT  = 14.0;
WRIST_H    =  9.0;
WRIST_W    = 38.0;

// Tactile dots (left button, find by touch)
DOT_R    = 1.3;


// ================================================================
// FOOTPRINT — stadium / pill (matches real M350s outline)
// ================================================================
module mouse_footprint() {
    R   = MOUSE_W / 2;
    mid = (MOUSE_L - MOUSE_W) / 2;
    hull() {
        translate([0,  mid]) circle(r=R);   // rear  semicircle
        translate([0, -mid]) circle(r=R);   // front semicircle
    }
}


CEIL = CASE_H - WALL_T;   // underside of the top ceiling (= 19.6)

// Interior cavity — the hollow the mouse base slides up into.
// Anything unioned into the case must NOT fill this, or it won't fit.
module interior_cavity() {
    translate([0, 0, -1])
        linear_extrude(height=CEIL + 1, scale=[0.96, 0.96])
            offset(r=-WALL_T)
                mouse_footprint();
}

// ================================================================
// SHELL BODY — solid top ceiling, walls all round, OPEN bottom
// ================================================================
module shell_body() {
    difference() {
        // outer solid
        linear_extrude(height=CASE_H, scale=[0.96, 0.96])
            mouse_footprint();
        // hollow it out
        interior_cavity();
    }
}


// ================================================================
// PALM DOME — gentle raised curve on the rear/palm half
// ================================================================
module palm_dome() {
    translate([0, MOUSE_L/4, CASE_H - 1])
        scale([MOUSE_W * 0.30, MOUSE_L * 0.20, 3])
            sphere(r=1);
}


// ================================================================
// SCROLL WHEEL OPENING — cut through the top ceiling (and the ring)
// ================================================================
module scroll_opening() {
    translate([0, sw_cy, CEIL - 2])
        linear_extrude(height=WALL_T + 8)
            hull() {
                translate([0,  SW_L/2 - SW_W/2]) circle(r=SW_W/2);
                translate([0, -SW_L/2 + SW_W/2]) circle(r=SW_W/2);
            }
}


// ================================================================
// SCROLL RING — wide raised, ridged ring around the wheel
// ================================================================
module scroll_ring() {
    translate([0, sw_cy, CASE_H - 1]) {
        difference() {
            cylinder(d=RING_OD, h=RING_T + 1);
            translate([0, 0, -0.1])
                cylinder(d=RING_OD - RING_WALL*2, h=RING_T + 1.3);
        }
        for (a = [0 : 40 : 359])
            rotate([0, 0, a])
                translate([RING_OD/2 - RING_WALL/2, 0, 0])
                    cube([1.2, 2.0, RING_T], center=true);
    }
}


// ================================================================
// CENTRE GAP — through-slot dividing left / right click buttons.
// Runs from the scroll slot all the way THROUGH the front edge.
// ================================================================
GAP_W = 1.4;   // width of the parting gap between the two buttons

module button_groove() {
    y_back  = sw_cy - SW_L/2 + 2;   // meets the scroll slot
    y_front = -MOUSE_L/2 - 2;       // cuts clean through the front edge
    translate([0, (y_back + y_front)/2, CASE_H - WALL_T/2])
        cube([GAP_W, y_back - y_front, WALL_T + 4], center=true);
}

// ================================================================
// BUTTON RELEASE SLOTS — free the front button flaps so they FLEX.
// A thin arc just inside the outer rim, around the front only.
// Combined with the centre gap, each button is attached only at its
// rear (a living hinge behind the scroll) so pressing it can click.
// ================================================================
module button_release_slots() {
    hinge_y = sw_cy - SW_L/2;        // buttons stay joined behind this line
    translate([0, 0, CEIL - 1])
        linear_extrude(height = WALL_T + 4)
            intersection() {
                // 1.5 mm arc slot, ~3 mm inside the outer edge
                difference() {
                    offset(r=-3.0) mouse_footprint();
                    offset(r=-4.5) mouse_footprint();
                }
                // keep only the FRONT region (in front of the hinge)
                translate([-100, -300]) square([200, 300 + hinge_y]);
            }
}


// ================================================================
// CLICK ACTUATOR TABS — 2 rectangular tabs hanging from the ceiling
// Labels 1 (left) & 2 (right). Visible in the interior when flipped.
// ================================================================
module click_actuators() {
    for (side = [-1, 1])
        translate([side * CLICK_X - CLICK_W/2, CLICK_Y - CLICK_L/2, CLICK_BOTTOM])
            cube([CLICK_W, CLICK_L, CEIL - CLICK_BOTTOM + 0.1]);
}


// ================================================================
// MAGNET / SCREW BOSSES — 3 cylindrical posts from ceiling to base
// Labels 3 (left), 4 (right), 5 (rear centre). Holes open downward.
// ================================================================
mag_positions = [
    [-MAG_X,  MAG_Y_SIDE],   // 3 — centre left
    [ MAG_X,  MAG_Y_SIDE],   // 4 — centre right
    [    0,   MAG_Y_REAR ]   // 5 — rear centre
];

module magnet_bosses() {
    for (p = mag_positions)
        translate([p[0], p[1], BOSS_BOTTOM])
            cylinder(d=BOSS_OD, h = CEIL - BOSS_BOTTOM + 0.1);
}

module magnet_pockets() {
    for (p = mag_positions)
        translate([p[0], p[1], BOSS_BOTTOM - 0.1])
            cylinder(d=MAG_D, h=MAG_DEPTH);
}


// ================================================================
// WRIST SUPPORT LEDGE — rear palm extension
// Bonds to the rear wall + top ceiling and extends BEHIND the mouse.
// The interior cavity is carved back out so it never blocks the fit.
// ================================================================
module wrist_ledge() {
    y_bond = MOUSE_L/2 - 6;             // small overlap onto the rear wall/ceiling
    y_out  = MOUSE_L/2 + WRIST_EXT;     // extends beyond the rear edge
    difference() {
        hull() {
            // bond edge — tall, grips the rear wall + ceiling
            translate([-WRIST_W/2, y_bond, 0]) cylinder(r=5, h=CASE_H - 2);
            translate([ WRIST_W/2, y_bond, 0]) cylinder(r=5, h=CASE_H - 2);
            // outer tip — sloped palm rest beyond the rear edge
            translate([-WRIST_W/3, y_out, 0]) cylinder(r=4, h=WRIST_H);
            translate([ WRIST_W/3, y_out, 0]) cylinder(r=4, h=WRIST_H);
        }
        // keep the mouse cavity clear so the case still slides on
        interior_cavity();
    }
}

// ================================================================
// SIDE GRIP RIBS — 5 vertical ridges on each side wall (external)
// Placed along the FLAT middle section so all 5 sit on the wall.
// ================================================================
N_RIBS = 5;
RIB_H  = 10.0;   // rib height (vertical, along Z)
RIB_W  = 2.4;    // rib thickness

module one_side_ribs(side) {
    y_span = 34;   // spread; stays inside the straight zone (±24)
    for (i = [0 : N_RIBS-1]) {
        y = -y_span/2 + y_span * i / (N_RIBS - 1);
        translate([side * (MOUSE_W/2 - 0.3), y, CASE_H * 0.32])
            cylinder(r=RIB_W/2, h=RIB_H, center=true);
    }
}

module grip_ribs() {
    one_side_ribs( 1);
    one_side_ribs(-1);
}


// ================================================================
// FEATURE 6 — BUTTON EXTENSION
// A raised pad across the front button zone. Brings the clicking
// surface up and forward so fingers reach it with less travel.
// ================================================================
module button_extension() {
    hull() {
        translate([-18, -MOUSE_L/2 + 14, CASE_H - 0.5]) cylinder(r=5, h=2);
        translate([ 18, -MOUSE_L/2 + 14, CASE_H - 0.5]) cylinder(r=5, h=2);
        translate([-12, -MOUSE_L/2 + 4,  CASE_H - 0.5]) cylinder(r=4, h=2);
        translate([ 12, -MOUSE_L/2 + 4,  CASE_H - 0.5]) cylinder(r=4, h=2);
    }
}

// ================================================================
// FEATURE 5 — TACTILE DOTS
// 4-dot cluster on the LEFT button pad (+X). Find the click by touch.
// ================================================================
module tactile_dots() {
    dots = [[10, -43], [13, -45], [9, -47], [12, -41]];
    for (d = dots)
        translate([d[0], d[1], CASE_H + 0.8]) sphere(r=DOT_R);
}


// ================================================================
// FULL ASSEMBLY
// ================================================================
difference() {
    union() {
        shell_body();
        palm_dome();
        // scroll_ring() removed — the fixed raised ring obstructed the wheel
        // and could not spin. Scrolling now uses the separate wheel cap
        // (scroll-wheel-cap.scad) that clips onto the real wheel.
        wrist_ledge();
        grip_ribs();
        button_extension();
        tactile_dots();
        click_actuators();
        magnet_bosses();
    }
    scroll_opening();
    button_groove();
    button_release_slots();
    magnet_pockets();
    // trim below the print bed
    translate([0, 0, -50]) cube([400, 400, 100], center=true);
}


/* ================================================================
   PRINT GUIDE
   Material  : PETG (preferred) or PLA+
   Layer     : 0.20 mm   Walls: 3   Infill: 20 % gyroid
   Nozzle    : 235 °C PETG / 215 °C PLA+
   Bed       : 85 °C PETG / 60 °C PLA+
   Supports  : under the wrist-ledge overhang only
   Orient    : print with the TOP (palm) face down on the bed

   AFTER PRINTING
   1. Press 3 N52 magnets (6 × 3 mm) into the boss holes on the
      underside — left-centre, right-centre, rear-centre.
   2. Lower the case onto the Pebble M350s — magnets self-align
      and snap it on. No tools, no glue, no modification.
   ================================================================ */
