/*
  ESP32 radio low-profile integrated cabinet

  Front layout:
  - F12E28A01-1 oval speaker at the bottom
  - bass-reflex style port above the speaker
  - OLED display left of the port
  - volume knob right of the port

  This is a compact packaging draft for the radio electronics, not a final
  measured production model. Measure the actual speaker, OLED, encoder, ESP32
  board, and wire bends before printing the final version.

  Print parts:
  - part_mode = 1: front shell
  - part_mode = 2: rear cover
  - part_mode = 3: port plug
  - part_mode = 0: all parts side by side

  All dimensions are millimeters.
*/

$fn = 80;

part_mode = 0;

// Low profile cabinet. Depth is limited by the F12E28A01-1 depth of about
// 39.5 mm plus front baffle, rear cover, and wire clearance.
case_w = 118;
case_h = 70;
case_d = 52;
wall = 4.0;
corner_r = 5;
front_th = 4.0;
back_th = 4.0;

// Front layout.
speaker_x = 54;
speaker_y = 21;
port_x = 54;
port_y = 54;
display_x = 94;
display_y = 59;
knob_x = 21;
knob_y = 58;

// F12E28A01-1 is a 30 x 70 mm oval speaker. The front opening is kept to the
// measured 66 x 26 mm rounded slot only; no inner alignment groove is modeled.
speaker_cutout_w = 66.0;
speaker_cutout_h = 26.0;
speaker_cutout_r = 13.0;

speaker_mount_holes_enabled = false;
speaker_screw_span_x = 81.0;
speaker_screw_span_y = 35.0;
speaker_screw_hole_d = 3.6;

// Port. Keep short because the cabinet is shallow; use the plug if muddy.
port_enabled = true;
port_d = 9.5;
port_len = 22;
port_wall = 2.2;

// OLED board stays outside; only its pin header enters the cabinet.
oled_header_slot_w = 12;
oled_header_slot_h = 4;

// KY-040 / volume knob. Only the center shaft hole is cut on the front panel.
encoder_shaft_hole_d = 7.4;
// Rear cover.
lip_depth = 1.0;
lip_clearance = 1.2;
cover_screw_d = 3.0;
cover_screw_offset = 10.0;
cover_receiver_depth = 5.0;
cover_receiver_wall = 3.0;
cover_receiver_overlap = 1.2;

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

module speaker_mount_holes() {
  // Optional rectangular mounting pattern for the oval speaker tabs.
  for (sx = [-1, 1]) {
    for (sy = [-1, 1]) {
      translate([
        speaker_x + sx * speaker_screw_span_x / 2,
        speaker_y + sy * speaker_screw_span_y / 2,
        -0.2
      ])
        cylinder(h = front_th + 0.4, d = speaker_screw_hole_d);
    }
  }
}

module front_cutouts() {
  translate([speaker_x, speaker_y, -0.2])
    linear_extrude(height = front_th + 0.4)
      rounded_rect_2d(speaker_cutout_w, speaker_cutout_h, speaker_cutout_r);

  if (speaker_mount_holes_enabled) {
    speaker_mount_holes();
  }

  if (port_enabled) {
    translate([port_x, port_y, -0.2])
      cylinder(h = front_th + 0.4, d = port_d);
  }

  translate([display_x, display_y, -0.2])
    linear_extrude(height = front_th + 0.4)
      rounded_rect_2d(oled_header_slot_w, oled_header_slot_h, 1.0);

  translate([knob_x, knob_y, -0.2])
    cylinder(h = front_th + 0.4, d = encoder_shaft_hole_d);
}

module front_shell_wall() {
  difference() {
    case_box(case_w, case_h, case_d - back_th, corner_r);

    translate([wall, wall, front_th])
      case_box(
        case_w - wall * 2,
        case_h - wall * 2,
        case_d,
        max(corner_r - wall, 1)
      );

    translate([wall, wall, case_d - back_th - 0.2])
      case_box(
        case_w - wall * 2,
        case_h - wall * 2,
        back_th + 0.4,
        max(corner_r - wall, 1)
      );

  }
}

module port_tube() {
  if (port_enabled) {
    translate([port_x, port_y, front_th - 0.2])
      difference() {
        cylinder(h = port_len + 0.2, d = port_d + port_wall * 2);
        translate([0, 0, -0.2])
          cylinder(h = port_len + 0.6, d = port_d);
      }
  }
}

module cover_screw_receiver(x, y) {
  // Compact rectangular screw receiver near the rear opening. The receiver is
  // tied into its two adjacent walls, while the screw hole center stays fixed.
  hole_r = cover_screw_d / 2;
  half = hole_r + cover_receiver_wall;
  left_side = x < case_w / 2;
  bottom_side = y < case_h / 2;
  block_left = left_side ? wall - cover_receiver_overlap : x - half;
  block_right = left_side ? x + half : case_w - wall + cover_receiver_overlap;
  block_bottom = bottom_side ? wall - cover_receiver_overlap : y - half;
  block_top = bottom_side ? y + half : case_h - wall + cover_receiver_overlap;
  z = case_d - back_th - 1.5 - cover_receiver_depth;

  difference() {
    translate([block_left, block_bottom, z])
      cube([block_right - block_left, block_top - block_bottom, cover_receiver_depth]);
    translate([x, y, z - 0.2])
      cylinder(h = cover_receiver_depth + 0.4, d = cover_screw_d);
  }
}

module internal_features() {
  port_tube();

  // Compact rear cover screw receivers.
  for (x = [cover_screw_offset, case_w - cover_screw_offset]) {
    for (y = [cover_screw_offset, case_h - cover_screw_offset]) {
      cover_screw_receiver(x, y);
    }
  }
}

module front_shell() {
  difference() {
    union() {
      front_shell_wall();
      internal_features();
    }

    front_cutouts();
  }
}

module back_cover() {
  difference() {
    union() {
      case_box(case_w, case_h, back_th, corner_r);

      translate([wall + lip_clearance, wall + lip_clearance, back_th - 0.15])
        case_box(
          case_w - wall * 2 - lip_clearance * 2,
          case_h - wall * 2 - lip_clearance * 2,
          lip_depth + 0.15,
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

module port_plug() {
  plug_len = 7.5;
  grip_d = port_d + 7.0;

  union() {
    cylinder(h = plug_len, d = port_d - 0.4);
    translate([0, 0, plug_len - 0.2])
      cylinder(h = 2.0, d = grip_d);
  }
}

if (part_mode == 1) {
  front_shell();
} else if (part_mode == 2) {
  back_cover();
} else if (part_mode == 3) {
  port_plug();
} else {
  front_shell();
  translate([case_w + 10, 0, 0]) back_cover();
  translate([case_w * 2 + 25, 25, 0]) port_plug();
}
