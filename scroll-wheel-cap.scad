/* ================================================================
   PEBBLE PLATFORM — Scroll Wheel Cap (Extender)
   Logitech Research Project 4

   WHAT THIS IS:
   A small SEPARATE part that clips onto the Pebble M350s's real
   scroll wheel and makes it BIGGER, so it is easy to turn with a
   thumb, knuckle or palm — not just a fingertip.

   HOW IT WORKS (the "cap on the wheel" idea):
   - The real wheel is a small ridged rubber wheel.
   - This cap is a ring that presses over that wheel (a tight
     friction fit).
   - Because it grips the wheel, when you turn the big cap the real
     wheel turns WITH it — so the scrolling actually happens.

   HOW TO INSTALL:
   1. Gently pop the mouse's scroll wheel off its axle clip
      (it usually lifts straight out of the little side clips).
   2. Slide this printed cap over the wheel (along the axle direction)
      until it is centred.
   3. Click the wheel (now wearing the cap) back onto its axle.
   4. Reversible any time — just pull the cap off.

   PRINT:
   PLA or PETG · 0.12 mm layers (fine detail) · 3 walls · 40% infill
   Small part — print with the flat face on the bed, no supports.

   >>> THE NUMBERS BELOW ARE ESTIMATED FROM A PHOTO. <<<
   After a test print, measure the real wheel with calipers and tune
   WHEEL_D and WHEEL_W until the cap presses on snug but not loose.
   ================================================================ */

$fn = 96;

// ---- MEASURE THESE ON THE REAL WHEEL AND UPDATE ----
WHEEL_D = 11.0;   // diameter of the real scroll wheel  (estimate)
WHEEL_W =  6.0;   // width (thickness) of the real wheel (estimate)

// ---- FIT ----
// Bore is made slightly smaller than the wheel so it grips by friction.
// Too loose (cap slips) → INCREASE grip: make GRIP_INTERF bigger.
// Too tight (won't go on) → DECREASE GRIP_INTERF.
GRIP_INTERF = 0.4;   // how much smaller the bore is than the wheel

// ---- NEW BIGGER WHEEL ----
CAP_D    = 16.0;  // new outer diameter — bigger = easier to turn
SIDE_WALL = 1.6;  // how thick the cap wall is at the sides
GRIP_N    = 22;   // number of grip ridges around the outside
RIDGE_D   = 1.0;  // ridge thickness

BORE_D  = WHEEL_D - GRIP_INTERF;   // inner grip diameter
CAP_W   = WHEEL_W - 0.4;           // slightly narrower so it never rubs

// ================================================================
module wheel_cap() {
    difference() {
        union() {
            // main ring body
            cylinder(d=CAP_D, h=CAP_W, center=true);

            // grip ridges around the rim
            for (a = [0 : 360/GRIP_N : 359.9])
                rotate([0, 0, a])
                    translate([CAP_D/2, 0, 0])
                        cylinder(d=RIDGE_D, h=CAP_W, center=true, $fn=16);
        }

        // hollow bore that grips the real wheel
        cylinder(d=BORE_D, h=CAP_W + 1, center=true);

        // two shallow inner rings to bite the wheel's rubber for extra grip
        for (z = [-CAP_W/4, CAP_W/4])
            translate([0, 0, z])
                rotate_extrude()
                    translate([BORE_D/2 - 0.15, 0])
                        circle(d=0.7);
    }
}

wheel_cap();

/* ================================================================
   QUICK TUNING GUIDE (after first test print)

   Cap won't fit onto the wheel   → GRIP_INTERF smaller (e.g. 0.4 → 0.2)
   Cap spins loose on the wheel   → GRIP_INTERF bigger  (e.g. 0.4 → 0.6)
   Cap rubs the case sides        → CAP_W smaller, or WHEEL_W measured smaller
   Want an even easier turn       → CAP_D bigger (but keep it under ~18 mm
                                     so it still shows through the case slot)
   ================================================================ */
