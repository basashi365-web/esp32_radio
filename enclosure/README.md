# ESP32 Radio Enclosure

`esp32_radio_compact.scad` is a first compact enclosure draft for the arrived
53 mm speaker.

## Layout

Front face, left to right:

1. KY-040 knob
2. 53 mm full-range speaker
3. SSD1306 128x64 OLED

The initial outside size is `145 x 78 x 48 mm`. This keeps the radio compact
while leaving room for the speaker depth, OLED board, KY-040 body, ESP32-S3,
MAX98357A, and wiring.

## Parts

- Front shell: set `part_mode = 1;`
- Back cover: set `part_mode = 2;`
- Preview both: set `part_mode = 0;`

## Measure Before Final Print

Tune these parameters after checking the actual parts:

- `speaker_outer_d`: actual speaker outside diameter
- `speaker_cutout_d`: full round opening diameter; current draft uses `47`
- `speaker_grille_enabled`: keep `false` when no protective grille is needed
- `speaker_mount_holes_enabled`: keep `false` when using the rear support ring
- `speaker_screw_circle_d`: speaker screw pitch circle
- `speaker_screw_hole_d`: screw hole diameter
- `encoder_shaft_hole_d`: knob shaft hole
- `encoder_mount_spacing`: KY-040 board mounting pitch
- `oled_window_w` / `oled_window_h`: visible OLED window
- `oled_board_w` / `oled_board_h`: OLED PCB size
- `oled_screw_spacing_x` / `oled_screw_spacing_y`: OLED mounting holes

## Print Notes

- Print the front shell face down if the printer handles bridge holes cleanly.
- Print the back cover flat.
- First print a thin front-panel-only test or use slicer preview to confirm the
  knob, speaker, and OLED positions before committing to a full enclosure.
- Keep Wi-Fi credentials and local configuration outside public CAD/docs.
