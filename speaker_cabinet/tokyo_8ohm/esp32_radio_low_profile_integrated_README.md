# ESP32 Radio Low Profile Integrated Cabinet

This draft combines the speaker cabinet and the ESP32 radio front controls into one compact enclosure.

## Layout

- Bottom: F12E28A01-1 / 30 x 70 mm oval speaker, rotated horizontally.
- Upper center: bass-reflex style port.
- Top left: 12 x 4 mm slot for the external OLED board pin header.
- Upper right: KY-040 / volume knob shaft only. The extra KY-040 mounting holes and rear landing frame are omitted.
- Inside: open space for the ESP32-S3 board and MAX98357A board. No front-side board pads are modeled.

## Dimensions

| Item | Value |
|---|---:|
| Outer size | 118 x 70 x 52 mm |
| Wall | 4.0 mm |
| Front baffle | 4.0 mm |
| Speaker opening | 66 x 26 mm rounded slot |
| OLED/header opening | 12 x 4 mm rounded slot |
| Port | 9.5 mm x 22 mm tube |
| Rear cover lip | 1.0 mm deep, 1.2 mm clearance per side |

## Files

- `esp32_radio_low_profile_integrated.scad`: OpenSCAD source.
- `esp32_radio_low_profile_front_shell.stl`: printable front shell.
- `esp32_radio_low_profile_back_cover.stl`: printable rear cover.
- `esp32_radio_low_profile_port_plug.stl`: optional port plug.
- `esp32_radio_low_profile_front_layout.png`: front layout diagram showing display, port, volume knob, and speaker positions.

## Notes

- This is intentionally shallow, but deeper than the first round-speaker draft because the F12E28A01-1 drawing shows about 39.5 mm speaker depth.
- Check speaker terminal clearance and USB plug clearance before final printing.
- Use foam tape or a thin gasket around the speaker rim.
- If the port makes voices muddy, insert the port plug.
- Speaker screw holes are disabled until the actual tab hole positions are measured on the real unit.
- The speaker opening is a plain 66 x 26 mm rounded through-slot; the previous inner alignment groove was removed.
- The KY-040 has only the center shaft hole; rear pockets and extra service openings were removed.
- The OLED board is assumed to sit outside the cabinet; only its pin header enters through the 12 x 4 mm slot.
- The top/service cutouts were intentionally removed; add cable exits later only after the real board placement is fixed.
- The rear cover lip was reduced from the first PETG print: the former 0.35 mm per-side clearance was too tight for the printed front shell.
