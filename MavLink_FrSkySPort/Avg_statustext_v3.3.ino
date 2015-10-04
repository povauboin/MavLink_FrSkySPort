/*
 * statustext_v3.3.ino part of MavLink_FrSkySPort
 * https://github.com/Clooney82/MavLink_FrSkySPort
 *
 * Copyright (C) 2015 Jochen Kielkopf
 *    https://github.com/Clooney82/MavLink_FrSkySPort
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY, without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 * Additional permission under GNU GPL version 3 section 7
 *
 * If you modify this Program, or any covered work, by linking or
 * combining it with FrSkySportTelemetry library (or a modified
 * version of that library), containing parts covered by the terms
 * of FrSkySportTelemetry library, the licensors of this Program
 * grant you additional permission to convey the resulting work.
 * {Corresponding Source for a non-source form of such a combination
 * shall include the source code for the parts of FrSkySportTelemetry
 * library used as well as that of the covered work.}
 *
 */
void parseStatusText_ac33(int32_t severity, String text)
{
  uint16_t textId = 0;

  // Texts with textId = 0 will be ignored

  if(text == "")                                                          textId = 0;

  //APMrover2/GCS_Mavlink.cpp
  else if(text == "Initialising APM...")                                  textId = 1;
  else if(text == "PX4:")                                                 textId = 2;
  else if(text == "Unsupported preflight calibration")                    textId = 3;
  else if(text == "command received:")                                    textId = 4;

  //APMrover2/Log.cpp
  else if(text == "ERASING LOGS")                                         textId = 5;
  else if(text == "No dataflash card inserted")                           textId = 6;

  //APMrover2/Steering.cpp
  else if(text == "AUTO triggered off")                                   textId = 7;
  else if(text == "Triggered AUTO with pin")                              textId = 8;

  //APMrover2/commands.cpp
  else if(text == "Resetting prev_WP")                                    textId = 9;
  else if(text == "init home")                                            textId = 10;

  //APMrover2/navigation.cpp
  else if(text == "<navigate> WP error - distance < 0")                   textId = 11;

  //APMrover2/sensors.cpp
  else if(text == "Calibrating barometer")                                textId = 12;
  else if(text == "barometer calibration complete")                       textId = 13;

  //APMrover2/system.cpp
  else if(text == "<startup_ground> GROUND START")                        textId = 14;
  else if(text == "<startup_ground> With Delay")                          textId = 15;
  else if(text.endsWith("Ready to drive."))                               textId = 16;
  else if(text == "Beginning INS calibration; do not move vehicle")                                                            textId = 17;
  else if(text == "Warming up ADC...")                                                            textId = 18;

  //AntennaTracker/GCS_Mavlink.cpp
  else if(text == "new HOME received")                                                            textId = 19;

  //AntennaTracker/system.cpp
  else if(text.endsWith("Ready to track."))                                                            textId = 20;

  //ArduCopter/GCS_Mavlink.cpp
  else if(text == "error setting rally point")                                                            textId = 21;
  else if(text == "Frame:")                                                            textId = 22;
  else if(text == "bad rally point index")                                                            textId = 23;
  else if(text == "bad rally point message ID")                                                            textId = 24;
  else if(text == "bad rally point message count")                                                            textId = 25;
  else if(text == "failed to set rally point")                                                            textId = 26;

  //ArduCopter/Log.cpp
  else if(text == "Log erase completen")                                                            textId = 27;
  else if(text == "No dataflash inserted")                                                            textId = 28;

  //ArduCopter/control_autotune.cpp
  else if(text == "AutoTune: Failed")                                                            textId = 29;
  else if(text == "AutoTune: Saved Gains")                                                            textId = 30;
  else if(text == "AutoTune: Started")                                                            textId = 31;
  else if(text == "AutoTune: Stopped")                                                            textId = 32;
  else if(text == "AutoTune: Success")                                                            textId = 33;

  //ArduCopter/crash_check.cpp
  else if(text == "Parachute: Landed")                                                            textId = 34;
  else if(text == "Parachute: Released!")                                                            textId = 35;
  else if(text == "Parachute: Too Low")                                                            textId = 36;

  //ArduCopter/ekf_check.cpp
  else if(text == "EKF variance")                                                            textId = 37;

  //ArduCopter/esc_calibration.cpp
  else if(text == "ESC Calibration: auto calibration")                                                            textId = 38;
  else if(text == "ESC Calibration: push safety switch")                                                            textId = 39;
  else if(text == "ESC Calibration: restart board")                                                            textId = 40;

  //ArduCopter/events.cpp
  else if(text == "Low Battery!")                                                            textId = 41;

  //ArduCopter/motors.cpp
  else if(text == "ARMING MOTORS")                                                            textId = 42;
  else if(text == "Arm: Accelerometers not healthy")                                                            textId = 43;
  else if(text == "Arm: Altitude disparity")                                                            textId = 44;
  else if(text == "Arm: Barometer not healthy")                                                            textId = 45;
  else if(text == "Arm: Check Battery")                                                            textId = 46;
  else if(text == "Arm: Collective below Failsafe")                                                            textId = 47;
  else if(text == "Arm: Collective too high")                                                            textId = 48;
  else if(text == "Arm: Gyro calibration failed")                                                            textId = 49;
  else if(text == "Arm: Gyros not healthy")                                                            textId = 50;
  else if(text == "Arm: Leaning")                                                            textId = 51;
  else if(text == "Arm: Mode not armable")                                                            textId = 52;
  else if(text == "Arm: Motor Emergency Stopped")                                                            textId = 53;
  else if(text == "Arm: Motor Interlock Enabled")                                                            textId = 54;
  else if(text == "Arm: Rotor Control Engaged")                                                            textId = 55;
  else if(text == "Arm: Safety Switch")                                                            textId = 56;
  else if(text == "Arm: Throttle below Failsafe")                                                            textId = 57;
  else if(text == "Arm: Throttle too high")                                                            textId = 58;
  else if(text == "Arm: Waiting for Nav Checks")                                                            textId = 59;
  else if(text == "Arm: check fence")                                                            textId = 60;
  else if(text == "DISARMING MOTORS")                                                            textId = 61;
  else if(text == "Locate Copter Alarm!")                                                            textId = 62;
  else if(text == "PreArm: ACRO_BAL_ROLL/PITCH")                                                            textId = 64;
  else if(text == "PreArm: Accelerometers not healthy")                                                            textId = 65;
  else if(text == "PreArm: Accels not calibrated")                                                            textId = 66;
  else if(text == "PreArm: Altitude disparity")                                                            textId = 67;
  else if(text == "PreArm: Barometer not healthy")                                                            textId = 68;
  else if(text == "PreArm: Check ANGLE_MAX")                                                            textId = 69;
  else if(text == "PreArm: Check Battery")                                                            textId = 70;
  else if(text == "PreArm: Check Board Voltage")                                                            textId = 71;
  else if(text == "PreArm: Check FS_THR_VALUE")                                                            textId = 72;
  else if(text == "PreArm: Check Heli Parameters")                                                            textId = 73;
  else if(text == "PreArm: Check mag field")                                                            textId = 74;
  else if(text == "PreArm: Collective below Failsafe")                                                            textId = 75;
  else if(text == "PreArm: Duplicate Aux Switch Options")                                                            textId = 76;
  else if(text == "PreArm: EKF-home variance")                                                            textId = 77;
  else if(text == "PreArm: Gyros not healthy")                                                            textId = 78;
  else if(text == "PreArm: High GPS HDOP")                                                            textId = 79;
  else if(text == "PreArm: Interlock/E-Stop Conflict")                                                            textId = 80;
  else if(text == "PreArm: Motor Emergency Stopped")                                                            textId = 81;
  else if(text == "PreArm: Motor Interlock Enabled")                                                            textId = 82;
  else if(text == "PreArm: Need 3D Fix")                                                            textId = 83;
  else if(text == "PreArm: RC not calibrated")                                                            textId = 84;
  else if(text == "PreArm: Throttle below Failsafe")                                                            textId = 85;
  else if(text == "PreArm: Waiting for Nav Checks")                                                            textId = 86;
  else if(text == "PreArm: check fence")                                                            textId = 87;
  else if(text == "PreArm: check range finder")                                                            textId = 88;
  else if(text == "PreArm: inconsistent Accelerometers")                                                            textId = 89;
  else if(text == "PreArm: inconsistent Gyros")                                                            textId = 90;

  //ArduCopter/switches.cpp
  else if(text == "Trim saved")                                                            textId = 91;

  //ArduCopter/system.cpp
  else if(text == "GROUND START")                                                            textId = 92;
  else if(text == "Waiting for first HIL_STATE message")                                                            textId = 93;

  //ArduPlane/ArduPlane.cpp
  else if(text == "Disable fence failed (autodisable)")                                                            textId = 94;
  else if(text == "Disable fence floor failed (autodisable)")                                                            textId = 95;
  else if(text == "Fence disabled (autodisable)")                                                            textId = 96;
  else if(text == "Fence floor disabled (auto disable)")                                                            textId = 97;
  else if(text == "FBWA tdrag moden")                                                            textId = 98;

  //ArduPlane/Attitude.cpp
  else if(text == "Demo Servos!")                                                            textId = 99;

  //ArduPlane/GCS_Mavlink.cpp
  else if(text == "Fence floor disabled.")                                                            textId = 100;
  else if(text == "Go around command accepted.")                                                            textId = 101;
  else if(text == "Rejected go around command.")                                                            textId = 102;
  else if(text == "bad fence point")                                                            textId = 103;
  else if(text == "fencing must be disabled")                                                            textId = 104;

  //ArduPlane/Log.cpp
  else if(text == "Log erase complete")                                                            textId = 105;

  //ArduPlane/arming_checks.cpp
  else if(text == "PreArm: LIM_PITCH_MAX too small")                                                            textId = 106;
  else if(text == "PreArm: LIM_PITCH_MIN too large")                                                            textId = 107;
  else if(text == "PreArm: LIM_ROLL_CD too small")                                                            textId = 108;
  else if(text == "PreArm: invalid THR_FS_VALUE for rev throttle")                                                            textId = 109;

  //ArduPlane/control_modes.cpp
  else if(text == "PX4IO Override disabled")                                                            textId = 110;
  else if(text == "PX4IO Override enable failed")                                                            textId = 111;
  else if(text == "PX4IO Override enabled")                                                            textId = 112;

  //ArduPlane/events.cpp
  else if(text == "No GCS heartbeat.")                                                            textId = 113;
  else if(text == "Failsafe - Long event on")                                                            textId = 114;
  else if(text == "Failsafe - Short event off")                                                            textId = 115;
  else if(text == "Failsafe - Short event on")                                                            textId = 116;

  //ArduPlane/geofence.cpp
  else if(text == "geo-fence setup error")                                                            textId = 117;
  else if(text == "geo-fence OK")                                                            textId = 118;
  else if(text == "geo-fence loaded")                                                            textId = 119;
  else if(text == "geo-fence triggered")                                                            textId = 120;

  //ArduPlane/landing.cpp
  else if(text == "Unable to start landing sequence.")                                                            textId = 121;
  else if(text == "Auto-Disarmed")                                                            textId = 122;
  else if(text == "Landing sequence begun.")                                                            textId = 123;

  //ArduPlane/sensors.cpp
  else if(text == "zero airspeed calibrated")                                                            textId = 124;

  //ArduPlane/system.cpp
  else if(text == "NO airspeed")                                                            textId = 125;
  else if(text == "nn Ready to FLY.")                                                            textId = 126;
  else if(text == "Beginning INS calibration; do not move plane")                                                            textId = 127;

  //ArduPlane/takeoff.cpp
  else if(text == "FBWA tdrag off")                                                            textId = 128;

  //libraries/APM_OBC/APM_OBC.cpp
  else if(text == "Dual loss TERMINATE")                                                            textId = 129;
  else if(text == "Fence TERMINATE")                                                            textId = 130;
  else if(text == "GCS OK")                                                            textId = 131;
  else if(text == "GPS OK")                                                            textId = 132;
  else if(text == "RC failure terminate")                                                            textId = 133;
  else if(text == "Starting AFS_AUTO")                                                            textId = 134;
  else if(text == "State DATA_LINK_LOSS")                                                            textId = 135;
  else if(text == "State GPS_LOSS")                                                            textId = 136;

  //libraries/AP_Arming/AP_Arming.cpp
  else if(text == "PreArm: 3D accel cal needed")                                                            textId = 137;
  else if(text == "PreArm: AHRS not healthy!")                                                            textId = 138;
  else if(text == "PreArm: Bad GPS Position")                                                            textId = 139;
  else if(text == "PreArm: Barometer not healthy!")                                                            textId = 140;
  else if(text == "PreArm: Battery failsafe on.")                                                            textId = 141;
  else if(text == "PreArm: Hardware Safety Switch")                                                            textId = 142;
  else if(text == "PreArm: Radio failsafe on")                                                            textId = 143;
  else if(text == "PreArm: accels not healthy!")                                                            textId = 144;
  else if(text == "PreArm: airspeed not healthy")                                                            textId = 145;
  else if(text == "PreArm: gyros not calibrated!")                                                            textId = 146;
  else if(text == "PreArm: gyros not healthy!")                                                            textId = 147;
  else if(text == "PreArm: inconsistent gyros")                                                            textId = 148;
  else if(text == "Throttle armed!")                                                            textId = 149;
  else if(text == "Throttle disarmed!")                                                            textId = 150;

  //modules/PX4Firmware/src/modules/mavlink/mavlink_ftp.cpp
  else if(text == "FTP: can't open path (file system corrupted?)")                                                            textId = 151;
  else if(text == "FTP: list readdir_r failure")                                                            textId = 152;

  //modules/PX4Firmware/src/modules/mavlink/mavlink_main.cpp
  else if(text == "Save params and reboot to change COMPID")                                                            textId = 153;
  else if(text == "Save params and reboot to change SYSID")                                                            textId = 154;

  //modules/PX4Firmware/src/modules/mavlink/mavlink_mission.cpp
  else if(text == "ERROR: Waypoint index exceeds list capacity")                                                            textId = 155;
  else if(text == "ERROR: can't save mission state")                                                            textId = 156;
  else if(text == "ERROR: wp index out of bounds")                                                            textId = 157;
  else if(text == "IGN MISSION_ITEM: Busy")                                                            textId = 158;
  else if(text == "IGN MISSION_ITEM: No transfer")                                                            textId = 159;
  else if(text == "IGN MISSION_ITEM_REQUEST: No active transfer")                                                            textId = 160;
  else if(text == "IGN REQUEST LIST: Busy")                                                            textId = 161;
  else if(text == "Operation timeout")                                                            textId = 162;
  else if(text == "REJ. WP CMD: partner id mismatch")                                                            textId = 163;
  else if(text == "Unable to read from micro SD")                                                            textId = 164;
  else if(text == "Unable to write on micro SD")                                                            textId = 165;
  else if(text == "WPM: ERR: not all items sent -> IDLE")                                                            textId = 166;
  else if(text == "WPM: IGN CLEAR CMD: Busy")                                                            textId = 167;
  else if(text == "WPM: IGN MISSION_COUNT: Busy")                                                            textId = 168;
  else if(text == "WPM: IGN WP CURR CMD: Busy")                                                            textId = 169;
  else if(text == "WPM: REJ. CMD: Busy")                                                            textId = 170;
  else if(text == "WPM: REJ. CMD: Req. WP was unexpected")                                                            textId = 171;
  else if(text == "WPM: REJ. CMD: partner id mismatch")                                                            textId = 172;
  else if(text == "WPM: WP CURR CMD: Error setting ID")                                                            textId = 173;
  else if(text == "WPM: WP CURR CMD: Not in list")                                                            textId = 174;
  else if(text == "WP CMD OK TRY AGAIN")                                                            textId = 175;
  else if(text == "WPM: COUNT 0: CLEAR MISSION")                                                            textId = 176;
  else if(text == "WPM: Transfer complete.")                                                            textId = 177;
  else if(text == "WPM: mission is empty")                                                            textId = 178;

  else if(text.startsWith("PreArm: "))                                                   textId = 63;
  // Unknown text (textId = 1023)
  else                                                                    textId = 1023;

  ap_status_text_id = textId;

  #ifdef DEBUG_APM_PARSE_STATUSTEXT
    debugSerial.print(millis());
    debugSerial.print("\tparseStatusText. severity: ");
    debugSerial.print(severity);
    debugSerial.print(", text: \"");
    debugSerial.print(text);
    debugSerial.print("\" textId: ");
    debugSerial.print(textId);
    debugSerial.println();
  #endif
}
