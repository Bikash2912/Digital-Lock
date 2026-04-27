## ============================================================
## Basys3_DigitalLock.xdc  –  FPGA Secure Digital Lock
## Xilinx Artix-7 XC7A35T, 100 MHz system clock
## ============================================================

## ── Clock ───────────────────────────────────────────────────
set_property PACKAGE_PIN W5  [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## ── Onboard push buttons ────────────────────────────────────
## BTNC = reset
set_property PACKAGE_PIN U18  [get_ports rst_btn]
set_property IOSTANDARD LVCMOS33 [get_ports rst_btn]

## BTNU = save (active HIGH, internal pull-down on Basys3)
set_property PACKAGE_PIN T18  [get_ports save_btn]
set_property IOSTANDARD LVCMOS33 [get_ports save_btn]

## BTNL = check (active HIGH, internal pull-down on Basys3)
set_property PACKAGE_PIN W19  [get_ports check_btn]
set_property IOSTANDARD LVCMOS33 [get_ports check_btn]

## ── Onboard slide switch ────────────────────────────────────
## SW0 = mode (1=SAVE, 0=CHECK)
set_property PACKAGE_PIN V17  [get_ports mode_sw]
set_property IOSTANDARD LVCMOS33 [get_ports mode_sw]

## ── Onboard LEDs ─────────────────────────────────────────────
## LD0 = unlock
set_property PACKAGE_PIN U16  [get_ports unlock_led]
set_property IOSTANDARD LVCMOS33 [get_ports unlock_led]

## LD1 = error
set_property PACKAGE_PIN E19  [get_ports error_led]
set_property IOSTANDARD LVCMOS33 [get_ports error_led]

## LD2 = save
set_property PACKAGE_PIN U19  [get_ports save_led]
set_property IOSTANDARD LVCMOS33 [get_ports save_led]

## LD3 = keypress
set_property PACKAGE_PIN V19  [get_ports press_led]
set_property IOSTANDARD LVCMOS33 [get_ports press_led]

## LD14 = SAVE mode indicator
set_property PACKAGE_PIN P1   [get_ports mode_led14]
set_property IOSTANDARD LVCMOS33 [get_ports mode_led14]

## LD15 = SAVE mode indicator
set_property PACKAGE_PIN L1   [get_ports mode_led15]
set_property IOSTANDARD LVCMOS33 [get_ports mode_led15]

## ── 7-segment display ────────────────────────────────────────
## Anodes (active LOW)
set_property PACKAGE_PIN U2   [get_ports {an[0]}]
set_property PACKAGE_PIN U4   [get_ports {an[1]}]
set_property PACKAGE_PIN V4   [get_ports {an[2]}]
set_property PACKAGE_PIN W4   [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[*]}]

## Segments (active LOW) {CA,CB,CC,CD,CE,CF,CG}
set_property PACKAGE_PIN W7   [get_ports {seg[0]}]
set_property PACKAGE_PIN W6   [get_ports {seg[1]}]
set_property PACKAGE_PIN U8   [get_ports {seg[2]}]
set_property PACKAGE_PIN V8   [get_ports {seg[3]}]
set_property PACKAGE_PIN U5   [get_ports {seg[4]}]
set_property PACKAGE_PIN V5   [get_ports {seg[5]}]
set_property PACKAGE_PIN U7   [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]

## Decimal point (active LOW, tied OFF in RTL)
set_property PACKAGE_PIN V7   [get_ports dp]
set_property IOSTANDARD LVCMOS33 [get_ports dp]

## ── Keypad — Pmod JA ─────────────────────────────────────────
## Rows (output, active LOW drive)
## JA1=row[0]  JA2=row[1]  JA3=row[2]  JA4=row[3]
set_property PACKAGE_PIN J1   [get_ports {row[0]}]
set_property PACKAGE_PIN L2   [get_ports {row[1]}]
set_property PACKAGE_PIN J2   [get_ports {row[2]}]
set_property PACKAGE_PIN G2   [get_ports {row[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {row[*]}]

## Columns (input, active LOW with PULLUP)
## JA7=col[0]  JA8=col[1]  JA9=col[2]  JA10=col[3]
set_property PACKAGE_PIN H1   [get_ports {col[0]}]
set_property PACKAGE_PIN K2   [get_ports {col[1]}]
set_property PACKAGE_PIN H2   [get_ports {col[2]}]
set_property PACKAGE_PIN G3   [get_ports {col[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {col[*]}]
set_property PULLUP TRUE [get_ports {col[0]}]
set_property PULLUP TRUE [get_ports {col[1]}]
set_property PULLUP TRUE [get_ports {col[2]}]
set_property PULLUP TRUE [get_ports {col[3]}]

## ── LCD — Pmod JB ────────────────────────────────────────────
## JB1=RS  JB2=EN  JB3=D4  JB4=D5  JB7=D6  JB8=D7
set_property PACKAGE_PIN A14  [get_ports lcd_rs]
set_property PACKAGE_PIN A16  [get_ports lcd_en]
set_property PACKAGE_PIN B15  [get_ports {lcd_d[0]}]
set_property PACKAGE_PIN A15  [get_ports {lcd_d[1]}]
set_property PACKAGE_PIN B16  [get_ports {lcd_d[2]}]
set_property PACKAGE_PIN B17  [get_ports {lcd_d[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_rs]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_en]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_d[*]}]

## ── External peripherals — Pmod JC ───────────────────────────
## Upper row (JC1–JC4): outputs
## JC1 = buzzer
set_property PACKAGE_PIN K17  [get_ports buzzer]
set_property IOSTANDARD LVCMOS33 [get_ports buzzer]

## JC2 = led_green (unlock)
set_property PACKAGE_PIN M18  [get_ports led_green]
set_property IOSTANDARD LVCMOS33 [get_ports led_green]

## JC3 = led_red (error/locked)
set_property PACKAGE_PIN N17  [get_ports led_red]
set_property IOSTANDARD LVCMOS33 [get_ports led_red]

## JC4 = led_yellow (keypress)
set_property PACKAGE_PIN P18  [get_ports led_yellow]
set_property IOSTANDARD LVCMOS33 [get_ports led_yellow]

## Lower row (JC7–JC10): active-LOW tactile switches with PULLUP
## JC7 = ext_save_btn
set_property PACKAGE_PIN L17  [get_ports ext_save_btn]
set_property IOSTANDARD LVCMOS33 [get_ports ext_save_btn]
set_property PULLUP TRUE [get_ports ext_save_btn]

## JC8 = ext_check_btn
set_property PACKAGE_PIN M19  [get_ports ext_check_btn]
set_property IOSTANDARD LVCMOS33 [get_ports ext_check_btn]
set_property PULLUP TRUE [get_ports ext_check_btn]

## JC9 = ext_rst_btn
set_property PACKAGE_PIN P17  [get_ports ext_rst_btn]
set_property IOSTANDARD LVCMOS33 [get_ports ext_rst_btn]
set_property PULLUP TRUE [get_ports ext_rst_btn]

## JC10 = ext_mode_btn (unused in RTL but must be constrained to avoid DRC error)
set_property PACKAGE_PIN R18  [get_ports ext_mode_btn]
set_property IOSTANDARD LVCMOS33 [get_ports ext_mode_btn]
set_property PULLUP TRUE [get_ports ext_mode_btn]

## ── False path constraints (async inputs) ────────────────────
set_false_path -from [get_ports rst_btn]
set_false_path -from [get_ports save_btn]
set_false_path -from [get_ports check_btn]
set_false_path -from [get_ports mode_sw]
set_false_path -from [get_ports {col[*]}]
set_false_path -from [get_ports ext_save_btn]
set_false_path -from [get_ports ext_check_btn]
set_false_path -from [get_ports ext_rst_btn]
set_false_path -from [get_ports ext_mode_btn]
