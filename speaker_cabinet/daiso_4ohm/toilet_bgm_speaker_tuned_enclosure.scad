/*
  Larger BGM-oriented enclosure for the low-cost 53 mm / 4 ohm speaker.

  This is not a mathematically tuned hi-fi cabinet. The speaker's Thiele/Small
  parameters are unknown, so the design focuses on practical improvements:
  - larger rear air volume than the minimal box
  - stiffer front baffle
  - shallow speaker recess for a foam gasket
  - front-facing port that can be plugged if the result sounds boomy

  Print parts:
  - part_mode = 1: front cabinet
  - part_mode = 2: rear cover
  - part_mode = 3: port plug
  - part_mode = 0: all parts side by side

  All dimensions are millimeters.
*/

$fn = 80;

part_mode = 0;

// A larger cabinet for better speech/BGM fullness.
box_w = 92;
box_h = 92;
box_d = 68;
wall = 4.0;
corner_r = 7;
front_th = 4.0;
back_th = 4.0;

// Speaker.
speaker_outer_d = 53.4;
speaker_recess_d = 54.6;
speaker_recess_depth = 2.0;
speaker_cutout_d = 52.0;
speaker_body_clearance_d = 56.0;
speaker_depth_clearance = 33.0;
speaker_x = box_w / 2;
speaker_y = 55;

speaker_mount_holes_enabled = true;
speaker_screw_spacing = 44.0; // 44 mm square, about 62.2 mm diagonal.
speaker_screw_hole_d = 3.0;

// Front bass-reflex style port. Treat it as an adjustable experiment.
port_enabled = true;
port_d = 11.0;
port_len = 34.0;
port_x = box_w / 2;
port_y = 18;
port_wall = 1.8;

// Rear cover and screws.
lip_depth = 1.0;
lip_clearance = 0.35;
cover_screw_d = 3.0;
cover_boss_d = 8.0;
cover_screw_offset = 9.0;

// Rear cable exit. Face this downward if wall-mounted.
wire_slot_w = 9.0;
wire_slot_h = 4.5;

// Optional wall/keyhole slots in the rear cover.
keyhole_enabled = true;
keyhole_big_d = 8.0;
keyhole_slot_w = 4.0;
keyhole_slot_h = 13.0;

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

module standoff(x, y, z, h, od, id) {
  translate([x, y, z])
    difference() {
      cylinder(h = h, d = od);
      translate([0, 0, -0.2])
        cylinder(h = h + 0.4, d = id);
    }
}

module speaker_mount_holes() {
  for (sx = [-1, 1]) {
    for (sy = [-1, 1]) {
      translate([
        speaker_x + sx * speaker_screw_spacing / 2,
        speaker_y + sy * speaker_screw_spacing / 2,
        -0.2
      ])
        cylinder(h = front_th + 0.4, d = speaker_screw_hole_d);
    }
  }
}

module front_openings() {
  translate([speaker_x, speaker_y, -0.2])
    cylinder(h = front_th + 0.4, d = speaker_cutout_d);

  translate([speaker_x, speaker_y, front_th - speaker_recess_depth])
    cylinder(h = speaker_recess_depth + 0.4, d = speaker_recess_d);

  if (speaker_mount_holes_enabled) {
    speaker_mount_holes();
  }

  if (port_enabled) {
    translate([port_x, port_y, -0.2])
      cylinder(h = front_th + 0.4, d = port_d);
  }
}

module rear_wire_slot() {
  translate([box_w / 2, -0.3, box_d - back_th - wire_slot_h / 2])
    rotate([90, 0, 0])
      linear_extrude(height = wall + 0.6)
        rounded_rect_2d(wire_slot_w, wire_slot_h, 1.2);
}

module cabinet_wall() {
  difference() {
    case_box(box_w, box_h, box_d - back_th, corner_r);

    translate([wall, wall, front_th])
      case_box(
        box_w - wall * 2,
        box_h - wall * 2,
        box_d,
        max(corner_r - wall, 1)
      );

    translate([wall, wall, box_d - back_th - 0.2])
      case_box(
        box_w - wall * 2,
        box_h - wall * 2,
        back_th + 0.4,
        max(corner_r - wall, 1)
      );

    rear_wire_slot();
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

module internal_features() {
  port_tube();

  for (x = [cover_screw_offset, box_w - cover_screw_offset]) {
    for (y = [cover_screw_offset, box_h - cover_screw_offset]) {
      standoff(x, y, front_th, box_d - front_th - back_th - 1.5, cover_boss_d, cover_screw_d);
    }
  }
}

module front_cabinet() {
  difference() {
    union() {
      cabinet_wall();
      internal_features();
    }

    front_openings();

    translate([speaker_x, speaker_y, front_th + 1])
      cylinder(h = speaker_depth_clearance, d = speaker_body_clearance_d);
  }
}

module keyhole_cutout(x, y) {
  translate([x, y, -0.2])
    cylinder(h = back_th + lip_depth + 0.4, d = keyhole_big_d);

  translate([x, y + keyhole_slot_h / 2, -0.2])
    linear_extrude(height = back_th + lip_depth + 0.4)
      rounded_rect_2d(keyhole_slot_w, keyhole_slot_h, 1.2);
}

module rear_cover() {
  difference() {
    union() {
      case_box(box_w, box_h, back_th, corner_r);

      translate([wall + lip_clearance, wall + lip_clearance, back_th - 0.15])
        case_box(
          box_w - wall * 2 - lip_clearance * 2,
          box_h - wall * 2 - lip_clearance * 2,
          lip_depth + 0.15,
          max(corner_r - wall - lip_clearance, 1)
        );
    }

    translate([wall * 2, wall * 2, back_th - 0.2])
      case_box(
        box_w - wall * 4,
        box_h - wall * 4,
        lip_depth + 0.4,
        max(corner_r - wall * 2, 1)
      );

    for (x = [cover_screw_offset, box_w - cover_screw_offset]) {
      for (y = [cover_screw_offset, box_h - cover_screw_offset]) {
        translate([x, y, -0.2])
          cylinder(h = back_th + lip_depth + 0.4, d = cover_screw_d);
      }
    }

    if (keyhole_enabled) {
      keyhole_cutout(box_w / 2, box_h / 2 + 11);
    }
  }
}

module port_plug() {
  plug_len = 8;
  grip_d = port_d + 8;

  union() {
    cylinder(h = plug_len, d = port_d - 0.4);
    translate([0, 0, plug_len - 0.2])
      cylinder(h = 2.2, d = grip_d);
  }
}

if (part_mode == 1) {
  front_cabinet();
} else if (part_mode == 2) {
  rear_cover();
} else if (part_mode == 3) {
  port_plug();
} else {
  front_cabinet();
  translate([box_w + 12, 0, 0]) rear_cover();
  translate([box_w * 2 + 28, 24, 0]) port_plug();
}
