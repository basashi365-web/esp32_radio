/*
  ESP32 radio compact enclosure

  Layout on the front face, left to right:
  KY-040 knob, 53 mm speaker, SSD1306 128x64 OLED.

  All dimensions are millimeters. Measure the arrived parts and tune the
  parameter block before printing the final version.
*/

$fn = 64;

// 0 = assembly, 1 = front_shell, 2 = back_cover
part_mode = 0;

// Case
case_w = 145;
case_h = 78;
case_d = 48;
wall = 2.4;
corner_r = 5;
front_th = 3.0;
back_th = 2.4;
lip_depth = 5;
lip_clearance = 0.35;

// Layout
knob_x = 23;
speaker_x = 65;
display_x = 113;
ui_y = 39;

// KY-040 / knob
encoder_shaft_hole_d = 7.4;
encoder_mount_hole_d = 3.2;
encoder_mount_spacing = 27;
encoder_body_clearance_w = 31;
encoder_body_clearance_h = 34;
encoder_body_clearance_d = 15;

// Speaker, from current project notes: outer diameter about 52.6-53 mm,
// depth about 30 mm.
speaker_outer_d = 53.4;
speaker_cutout_d = 47;
speaker_depth_clearance = 32;
speaker_screw_circle_d = 45;
speaker_screw_hole_d = 3.0;
speaker_screw_count = 4;
speaker_mount_holes_enabled = false;
speaker_grille_enabled = false;
grille_hole_d = 3.0;
grille_ring_step = 6.2;
grille_max_r = 19;

// OLED module. Defaults fit common 0.96 inch SSD1306 boards; adjust to GM009606.
oled_window_w = 26;
oled_window_h = 15;
oled_board_w = 28;
oled_board_h = 28;
oled_board_clearance_d = 8;
oled_screw_spacing_x = 23;
oled_screw_spacing_y = 23;
oled_screw_hole_d = 2.2;

// Rear cover and fasteners
cover_screw_d = 3.0;
cover_boss_outer_d = 7.2;
cover_screw_offset = 8;
usb_cutout_w = 14;
usb_cutout_h = 8;

module rounded_rect_2d(w, h, r) {
  hull() {
    translate([-(w / 2 - r), -(h / 2 - r)]) circle(r = r);
    translate([ (w / 2 - r), -(h / 2 - r)]) circle(r = r);
    translate([-(w / 2 - r),  (h / 2 - r)]) circle(r = r);
    translate([ (w / 2 - r),  (h / 2 - r)]) circle(r = r);
  }
}

module rounded_box(w, h, d, r) {
  linear_extrude(height = d)
    rounded_rect_2d(w, h, r);
}

module case_box(w, h, d, r) {
  translate([w / 2, h / 2, 0])
    rounded_box(w, h, d, r);
}

module front_panel_shape() {
  case_box(case_w, case_h, front_th, corner_r);
}

module grille_holes() {
  for (x = [-grille_max_r : grille_ring_step : grille_max_r]) {
    for (y = [-grille_max_r : grille_ring_step : grille_max_r]) {
      r = sqrt(x * x + y * y);
      if (r <= grille_max_r && r > 5) {
        translate([speaker_x + x, ui_y + y, -0.2])
          cylinder(h = front_th + 0.4, d = grille_hole_d);
      }
    }
  }
}

module speaker_mount_holes() {
  for (i = [0 : speaker_screw_count - 1]) {
    a = 360 / speaker_screw_count * i + 45;
    translate([
      speaker_x + cos(a) * speaker_screw_circle_d / 2,
      ui_y + sin(a) * speaker_screw_circle_d / 2,
      -0.2
    ])
      cylinder(h = front_th + 0.4, d = speaker_screw_hole_d);
  }
}

module front_cutouts() {
  // Knob shaft and optional KY-040 board mounting holes.
  translate([knob_x, ui_y, -0.2])
    cylinder(h = front_th + 0.4, d = encoder_shaft_hole_d);
  for (dy = [-encoder_mount_spacing / 2, encoder_mount_spacing / 2]) {
    translate([knob_x, ui_y + dy, -0.2])
      cylinder(h = front_th + 0.4, d = encoder_mount_hole_d);
  }

  // Speaker acoustic opening and grille.
  if (speaker_cutout_d > 0) {
    translate([speaker_x, ui_y, -0.2])
      cylinder(h = front_th + 0.4, d = speaker_cutout_d);
  }
  if (speaker_grille_enabled) {
    grille_holes();
  }
  if (speaker_mount_holes_enabled) {
    speaker_mount_holes();
  }

  // OLED viewing window.
  translate([display_x, ui_y, -0.2])
    linear_extrude(height = front_th + 0.4)
      rounded_rect_2d(oled_window_w, oled_window_h, 1.2);
}

module front_shell_wall() {
  difference() {
    case_box(case_w, case_h, case_d - back_th, corner_r);
    translate([wall, wall, front_th])
      case_box(case_w - wall * 2, case_h - wall * 2, case_d, max(corner_r - wall, 1));
    // Rear opening.
    translate([wall, wall, case_d - back_th - 0.2])
      case_box(case_w - wall * 2, case_h - wall * 2, back_th + 0.4, max(corner_r - wall, 1));
    // USB/service cutout on the bottom rear.
    translate([case_w / 2, case_h / 2, case_d - 20])
      rotate([90, 0, 0])
        linear_extrude(height = wall + 0.6)
          rounded_rect_2d(usb_cutout_w, usb_cutout_h, 1.2);
  }
}

module standoff(x, y, z, h, od, id) {
  translate([x, y, z])
    difference() {
      cylinder(h = h, d = od);
      translate([0, 0, -0.2])
        cylinder(h = h + 0.4, d = id);
    }
}

module internal_mounts() {
  // Speaker support ring.
  translate([speaker_x, ui_y, front_th])
    difference() {
      cylinder(h = 4, d = speaker_outer_d + 4);
      translate([0, 0, -0.2])
        cylinder(h = 4.4, d = speaker_outer_d + 0.6);
    }

  // OLED board standoffs.
  for (sx = [-1, 1]) {
    for (sy = [-1, 1]) {
      standoff(
        display_x + sx * oled_screw_spacing_x / 2,
        ui_y + sy * oled_screw_spacing_y / 2,
        front_th,
        oled_board_clearance_d,
        5.2,
        oled_screw_hole_d
      );
    }
  }

  // Encoder board clearance frame, useful as a glue/screw landing zone.
  translate([knob_x, ui_y, front_th])
    difference() {
      linear_extrude(height = 3)
        rounded_rect_2d(encoder_body_clearance_w + 4, encoder_body_clearance_h + 4, 2);
      translate([0, 0, -0.2])
        linear_extrude(height = 3.4)
          rounded_rect_2d(encoder_body_clearance_w, encoder_body_clearance_h, 1.5);
    }

  // Rear cover bosses.
  for (x = [cover_screw_offset, case_w - cover_screw_offset]) {
    for (y = [cover_screw_offset, case_h - cover_screw_offset]) {
      standoff(x, y, front_th, case_d - front_th - back_th - 1.5, cover_boss_outer_d, cover_screw_d);
    }
  }
}

module front_shell() {
  difference() {
    union() {
      front_shell_wall();
      internal_mounts();
    }
    front_cutouts();
    // Speaker rear clearance.
    translate([speaker_x, ui_y, front_th + 1])
      cylinder(h = speaker_depth_clearance, d = speaker_outer_d + 1.0);
    // OLED board rear clearance.
    translate([display_x, ui_y, front_th + 1])
      linear_extrude(height = oled_board_clearance_d + 1)
        rounded_rect_2d(oled_board_w + 1.0, oled_board_h + 1.0, 1.5);
    // Encoder body rear clearance.
    translate([knob_x, ui_y, front_th + 1])
      linear_extrude(height = encoder_body_clearance_d + 1)
        rounded_rect_2d(encoder_body_clearance_w, encoder_body_clearance_h, 1.5);
  }
}

module back_cover() {
  difference() {
    union() {
      case_box(case_w, case_h, back_th, corner_r);
      translate([wall + lip_clearance, wall + lip_clearance, back_th])
        case_box(
          case_w - wall * 2 - lip_clearance * 2,
          case_h - wall * 2 - lip_clearance * 2,
          lip_depth,
          max(corner_r - wall - lip_clearance, 1)
        );
    }
    translate([wall * 2, wall * 2, back_th - 0.2])
      case_box(
        case_w - wall * 4,
        case_h - wall * 4,
        lip_depth + 0.4,
        max(corner_r - wall * 2, 1)
      );
    for (x = [cover_screw_offset, case_w - cover_screw_offset]) {
      for (y = [cover_screw_offset, case_h - cover_screw_offset]) {
        translate([x, y, -0.2])
          cylinder(h = back_th + lip_depth + 0.4, d = cover_screw_d);
      }
    }
  }
}

if (part_mode == 1) {
  front_shell();
} else if (part_mode == 2) {
  back_cover();
} else {
  front_shell();
  translate([0, case_h + 10, 0]) back_cover();
}
