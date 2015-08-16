#include "Time.h"
#include "FrSkySportSensor.h"
#include "FrSkySportSensorFcs.h"
#include "FrSkySportSensorFuel.h"
#include "FrSkySportSensorFlvss.h"
#include "FrSkySportSensorGps.h"
#include "FrSkySportSensorRpm.h"
#include "FrSkySportSensorAcc.h"
#include "FrSkySportSensorSp2uart.h"
#include "FrSkySportSensorVario.h"
#include "FrSkySportSingleWireSerial.h"
#include "FrSkySportTelemetry.h"
#if !defined(__MK20DX128__) && !defined(__MK20DX256__)
//#include "SoftwareSerial.h"
#endif

FrSkySportSensorFcs fcs;                               // Create FCS sensor with default ID
FrSkySportSensorFuel flightmode;                       // Create FUEL sensor with default ID
FrSkySportSensorFlvss flvss1;                          // Create FLVSS sensor with default ID
//FrSkySportSensorFlvss flvss2(FrSkySportSensor::ID15);  // Create FLVSS sensor with given ID
FrSkySportSensorGps gps;                               // Create GPS sensor with default ID
FrSkySportSensorRpm rpm;                               // Create RPM sensor with default ID
FrSkySportSensorAcc acc;                               // Create ACC sensor with default ID
FrSkySportSensorSp2uart sp2uart;                       // Create SP2UART Type B sensor with default ID
FrSkySportSensorVario vario;                           // Create Variometer sensor with default ID
FrSkySportTelemetry telemetry;                         // Create Variometer telemetry object


float FCSCurrent = 0.0;
float FCSVoltage = 0.0;

// Scale factor for roll/pitch:
// We need to scale down 360 deg to fit when max value is 256, and 256 equals 362 deg
float scalefactor = 360.0/((362.0/360.0)*256.0);

uint32_t handle_A2_A3_value(uint32_t value)
{
  return (value *330-165)/0xFF;
}

void FrSkySPort_Init()
{
  // Configure the telemetry serial port and sensors (remember to use & to specify a pointer to sensor)
#if defined(__MK20DX128__) || defined(__MK20DX256__)
  telemetry.begin(FrSkySportSingleWireSerial::SERIAL_1, &fcs, &flvss1, &gps, &sp2uart, &rpm, &vario, &flightmode, &acc);
//  telemetry.begin(FrSkySportSingleWireSerial::SERIAL_1, &fcs, &flvss1, &flvss2, &gps, &sp2uart, &rpm, &vario, &flightmode, &acc);
#else
  telemetry.begin(FrSkySportSingleWireSerial::SOFT_SERIAL_PIN_12, &fcs, &flvss1, &gps, &sp2uart, &rpm, &vario,  &flightmode, &acc);
//  telemetry.begin(FrSkySportSingleWireSerial::SOFT_SERIAL_PIN_12, &fcs, &flvss1, &flvss2, &gps, &sp2uart, &rpm, &vario,  &flightmode, &acc);
#endif
}

void FrSkySPort_Process()
{
  // Set current/voltage sensor (FCS) data
  // (set Voltage source to FAS in menu to use this data for battery voltage,
  //  set Current source to FAS in menu to use this data for current readins)
  if(currentCount > 2) {
    FCSVoltage = readAndResetAverageVoltage() / 1000.0 ;
    FCSCurrent = readAndResetAverageCurrent();  
    #ifdef DEBUG_FrSkySportTelemetry_FAS
      debugSerial.print(millis());
      debugSerial.print("\tVFAS (0x0210): ");
      debugSerial.print(FCSVoltage);
      debugSerial.print("\tCurr (0x0200): ");
      debugSerial.print(FCSCurrent);
      debugSerial.println();
    #endif
    fcs.setData(ap_current_battery / 10.0,   // Current consumption in amps
                FCSVoltage);  // Battery voltage in volts
  }
  /*
  fcs.setData(ap_current_battery / 10.0,   // Current consumption in amps
              ap_voltage_battery / 1000.0);  // Battery voltage in volts
  */

  #ifdef USE_SINGLE_CELL_MONITOR
  // Set LiPo voltage sensor (FLVSS) data (we use two sensors to simulate 8S battery 
  // (set Voltage source to Cells in menu to use this data for battery voltage)
  //flvss1.setData(4.07, 4.08, 4.09, 4.10, 4.11, 4.12);  // Cell voltages in volts (cells 1-6)
  //flvss2.setData(4.13, 4.14);                          // Cell voltages in volts (cells 7-8)
  #ifdef DEBUG_FrSkySportTelemetry_FLVSS
      debugSerial.print(millis());
      debugSerial.print("\tmaxCells: ");
      debugSerial.println(MAXCELLS);
    for (int i=0; i < MAXCELLS; i++) {
      debugSerial.print(millis());
      debugSerial.print("\tZelle[");
      debugSerial.print(i);
      debugSerial.print("]: ");
      debugSerial.print(zelle[i] / 1000.0);
      debugSerial.println("Volt");
      
    }
  #endif
  switch(MAXCELLS) {
    case 1:
      flvss1.setData(zelle[0] / 1000.0);
      break;
    case 2:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0);
      break;
    case 3:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0);
      break;
    case 4:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0, zelle[3] / 1000.0);
      break;
    case 5:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0, zelle[3] / 1000.0, zelle[4] / 1000.0);
      break;
    case 6:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0, zelle[3] / 1000.0, zelle[4] / 1000.0, zelle[5] / 1000.0);
      break;
/*    case 7:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0, zelle[3] / 1000.0, zelle[4] / 1000.0, zelle[5] / 1000.0);
      flvss2.setData(zelle[6] / 1000.0);
      break;
    case 8:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0, zelle[3] / 1000.0, zelle[4] / 1000.0, zelle[5] / 1000.0);
      flvss2.setData(zelle[6] / 1000.0, zelle[7] / 1000.0);
      break;
    case 9:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0, zelle[3] / 1000.0, zelle[4] / 1000.0, zelle[5] / 1000.0);
      flvss2.setData(zelle[6] / 1000.0, zelle[7] / 1000.0, zelle[8] / 1000.0);
      break;
    case 10:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0, zelle[3] / 1000.0, zelle[4] / 1000.0, zelle[5] / 1000.0);
      flvss2.setData(zelle[6] / 1000.0, zelle[7] / 1000.0, zelle[8] / 1000.0, zelle[9] / 1000.0);
      break;
    case 11:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0, zelle[3] / 1000.0, zelle[4] / 1000.0, zelle[5] / 1000.0);
      flvss2.setData(zelle[6] / 1000.0, zelle[7] / 1000.0, zelle[8] / 1000.0, zelle[9] / 1000.0, zelle[10] / 1000.0);
      break;
    case 12:
      flvss1.setData(zelle[0] / 1000.0, zelle[1] / 1000.0, zelle[2] / 1000.0, zelle[3] / 1000.0, zelle[4] / 1000.0, zelle[5] / 1000.0);
      flvss2.setData(zelle[6] / 1000.0, zelle[7] / 1000.0, zelle[8] / 1000.0, zelle[9] / 1000.0, zelle[10] / 1000.0, zelle[11] / 1000.0);
      break;
*/
  }
  
  
  
  #endif
  
  // Set GPS data
  #ifdef DEBUG_FrSkySportTelemetry_GPS
    debugSerial.print(millis());
    debugSerial.print("\tLatitude: ");
    debugSerial.print(ap_latitude);
    debugSerial.print("\tLongitude: ");
    debugSerial.print(ap_longitude);
    debugSerial.print("\tGPSAlt: ");
    debugSerial.print(ap_gps_altitude / 1000.0);
    debugSerial.print("\tGPSSpeed: ");
    debugSerial.print(ap_gps_speed / 100);
    debugSerial.print("\tCog: ");
    debugSerial.print(ap_cog);
    debugSerial.print("\tHDOP: ");
    debugSerial.print(ap_gps_hdop);
    debugSerial.print("\tDATE: ");
    debugSerial.print(year(ap_gps_time_unix_utc));
    debugSerial.print("-");
    debugSerial.print(month(ap_gps_time_unix_utc));
    debugSerial.print("-");
    debugSerial.print(day(ap_gps_time_unix_utc));
    debugSerial.print("\tTIME: ");
    debugSerial.print(hour(ap_gps_time_unix_utc));
    debugSerial.print(":");
    debugSerial.print(minute(ap_gps_time_unix_utc));
    debugSerial.print(":");
    debugSerial.print(second(ap_gps_time_unix_utc));
    debugSerial.println();
  #endif
  if(ap_fixtype==3) {
    gps.setData(ap_latitude, ap_longitude,    // Latitude and longitude in degrees decimal (positive for N/E, negative for S/W)
              ap_gps_altitude / 1000.0,       // Altitude (AMSL, NOT WGS84), in meters * 1000 (positive for up). Note that virtually all GPS modules provide the AMSL altitude in addition to the WGS84 altitude.
              ap_gps_speed / 100,             // GPS ground speed (m/s * 100). If unknown, set to: UINT16_MAX
              ap_cog,                         // Course over ground (NOT heading, but direction of movement) in degrees * 100, 0.0..359.99 degrees. If unknown, set to: UINT16_MAX
              ap_gps_hdop,                    // GPS HDOP horizontal dilution of position in cm (m*100)
              year(ap_gps_time_unix_utc)-2000, month(ap_gps_time_unix_utc), day(ap_gps_time_unix_utc),             // Date (year - 2000, month, day)
              hour(ap_gps_time_unix_utc), minute(ap_gps_time_unix_utc), second(ap_gps_time_unix_utc));           // Time (hour, minute, second) - will be affected by timezone setings in your radio
  }
  
  // Set RPM/temperature sensor data
  // (set number of blades to 2 in telemetry menu to get correct rpm value)
  // 16 bit value: 
  // bit 1: armed
  // bit 2-5: severity +1 (0 means no message)
  // bit 6-15: number representing a specific text
  uint32_t ap_status_value = ap_base_mode&0x01;
  // If we have a message-text to report (we send it multiple times to make sure it arrives even on telemetry glitches)
  if(ap_status_send_count > 0 && ap_status_text_id > 0)
  {
    // Add bits 2-15
    ap_status_value |= (((ap_status_severity+1)&0x0F)<<1) |((ap_status_text_id&0x3FF)<<5);
    ap_status_send_count--;
    if(ap_status_send_count == 0)
    {
       // Reset severity and text-message after we have sent the message
       ap_status_severity = 0; 
       ap_status_text_id = 0;
    }          
  }
  #ifdef DEBUG_FrSkySportTelemetry_RPM
    debugSerial.print(millis());
    debugSerial.print("\tRPM (Throttle/battery_remain): ");
    debugSerial.print(ap_throttle * 200+ap_battery_remaining*2);
    debugSerial.print("\tT1 ((ap_sat_visible * 10) + ap_fixtype): ");
    debugSerial.print(gps_status);
    debugSerial.print("\tT2 (Armed Status + Severity + Statustext): ");
    debugSerial.print(ap_status_value);
    debugSerial.println();
  #endif
  rpm.setData(ap_throttle * 200+ap_battery_remaining*2,    // * 2 if number of blades on Taranis is set to 2 + First 4 digits reserved for battery remaining in %
              gps_status,         // (ap_sat_visible * 10) + ap_fixtype eg. 83 = 8 sattelites visible, 3D lock 
              ap_status_value);   // Armed Status + Severity + Statustext

  // Set SP2UART sensor data
  // (values from 0.0 to 3.3 are accepted)
  #ifdef DEBUG_FrSkySportTelemetry_A3A4
    debugSerial.print(millis());
    debugSerial.print("\tRoll Angle: ");
    debugSerial.print(handle_A2_A3_value((ap_roll_angle+180)/scalefactor));
    debugSerial.print("\tPitch Angle: ");
    debugSerial.print(handle_A2_A3_value((ap_pitch_angle+180)/scalefactor));
    debugSerial.println();
  #endif
  sp2uart.setData(handle_A2_A3_value((ap_roll_angle+180)/scalefactor)/100.0,     // Roll Angle
                  handle_A2_A3_value((ap_pitch_angle+180)/scalefactor)/100.0);   // Pitch Angle

  // Set variometer data
  // (set Variometer source to VSpd in menu to use the vertical speed data from this sensor for variometer).
  #ifdef DEBUG_FrSkySportTelemetry_VARIO
    debugSerial.print(millis());
    debugSerial.print("\tCurrent altitude: ");
    debugSerial.print(ap_bar_altitude);
    debugSerial.print("\tCurrent climb rate in meters/second: ");
    debugSerial.print(ap_climb_rate);
    debugSerial.println();
  #endif
  vario.setData(ap_bar_altitude / 100.0,  // Current altitude (MSL), in meters
                ap_climb_rate / 100.0 );   // Current climb rate in meters/second

  // Set acc meter data
  // 
  #ifdef DEBUG_FrSkySportTelemetry_ACC
    debugSerial.print(millis());
    debugSerial.print("\tX acceleration (raw): ");
    debugSerial.print(fetchAccX());
    debugSerial.print("\tY acceleration (raw): ");
    debugSerial.print(fetchAccY());
    debugSerial.print("\tZ acceleration (raw): ");
    debugSerial.print(fetchAccZ());
    debugSerial.println();
  #endif
  acc.setData(fetchAccX(),        // X acceleration (raw)
              fetchAccY(),        // Y acceleration (raw)
              fetchAccZ());       // Z acceleration (raw)

  // Set FlightMode data
  //
  #ifdef DEBUG_FrSkySportTelemetry_FLIGHTMODE
    debugSerial.print(millis());
    debugSerial.print("\tFlightmode: ");
    debugSerial.print(ap_custom_mode);
    debugSerial.println();
  #endif
  if(ap_custom_mode >= 0) {
    flightmode.setData(ap_custom_mode);
  }
  
  // Send the telemetry data, note that the data will only be sent for sensors
  // that are being polled at given moment
  telemetry.send();
}
