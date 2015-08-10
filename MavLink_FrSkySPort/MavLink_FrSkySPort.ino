/*
APM2.5 Mavlink to FrSky X8R SPort interface using Teensy 3.1  http://www.pjrc.com/teensy/index.html
 based on ideas found here http://code.google.com/p/telemetry-convert/
 ******************************************************
 Cut board on the backside to separate Vin from VUSB
 
 Connection on Teensy 3.1:
 SPort S --> TX1
 SPort + --> Vin
 SPort  - --> GND
 
 APM Telemetry DF13-5  Pin 2 --> RX2
 APM Telemetry DF13-5  Pin 3 --> TX2
 APM Telemetry DF13-5  Pin 5 --> GND
 Note that when used with other telemetry device (3DR Radio 433 or 3DR Bluetooth tested) in parallel on the same port the Teensy should only Receive, so please remove it's TX output (RX input on PixHawk or APM)
 
 Analog input  --> A0 (pin14) on Teensy 3.1 ( max 3.3 V ) - Not used 
 
 
 This is the data we send to FrSky, you can change this to have your own
 set of data
 
******************************************************
Data transmitted to FrSky Taranis:
Cell            ( Voltage of Cell=Cells/(Number of cells). [V]) 
Cells           ( Voltage from LiPo [V] )
A2              ( HDOP value * 25 - 8 bit resolution)
A3              ( Roll angle from -Pi to +Pi radians, converted to a value between 0 and 1024)
A4              ( Pitch angle from -Pi/2 to +Pi/2 radians, converted to a value between 0 and 1024)
Alt             ( Altitude from baro.  [m] )
GAlt            ( Altitude from GPS   [m])
HDG             ( Compass heading  [deg]) v
Rpm             ( Throttle when ARMED [%] *100 + % battery remaining as reported by Mavlink)
VSpd            ( Vertical speed [m/s] )
Speed           ( Ground speed from GPS,  [km/h] )
T1              ( GPS status = ap_sat_visible*10) + ap_fixtype )
T2              ( Armed Status and Mavlink Messages :- 16 bit value: bit 1: armed - bit 2-5: severity +1 (0 means no message - bit 6-15: number representing a specific text)
Vfas            ( same as Cells )
Longitud        ( Longitud )
Latitud         ( Latitud )
Dist            ( Will be calculated by FrSky Taranis as the distance from first received lat/long = Home Position )
Fuel            ( Current Flight Mode reported by Mavlink )
AccX            ( X Axis average vibration m/s?)
AccY            ( Y Axis average vibration m/s?)
AccZ            ( Z Axis average vibration m/s?)
******************************************************
 */

#include "GCS_MAVLink.h"
#include "FrSkySPort.h"

#define debugSerial         Serial
#define _MavLinkSerial      Serial2
#define _MavLinkSerialBaud  57600
#define START               1
#define MSG_RATE            10              // Hertz
#define AP_SYSID            1 // autopilot system id
#define AP_CMPID            1 // autopilot component id
#define GB_SYSID            71 // gimbal system id
#define GB_CMPID            67 // gimbal component id
#define MY_SYSID            123 // teensy system id
#define MY_CMPID            123 // teensy component id

//#define DEBUG_VFR_HUD
//#define DEBUG_GPS_RAW
//#define DEBUG_ACC
//#define DEBUG_BAT
//#define DEBUG_MODE
//#define DEBUG_MAVLINK_MSGS
//#define DEBUG_STATUS
//#define DEBUG_ATTITUDE
//#define DEBUG_GIMBAL
//#define DEBUG_FRSKY_SENSOR_REQUEST
//#define DEBUG_AVERAGE_VOLTAGE
//#define DEBUG_PARSE_STATUS_TEXT
//#define DEBUG_LIPO_SINGLE_CELL_MONITOR
//#define DEBUG_RC_CHANNELS

//#define USE_RC_CHANNELS

/// Wolke lipo-single-cell-monitor
/*
 *
 * this will monitor 1 - 8 cells of your lipo
 * it display the low cell, the high cell and the difference between this cells
 * this will give you a quick overview about your lipo status and if the lipo is well balanced
 *
 * detailed informations and schematics here
 *
 */

//#define USE_SINGLE_CELL_MONITOR
//#define USE_AP_VOLTAGE_BATTERY_FROM_SINGLE_CELL_MONITOR // use this only with enabled USE_SINGLE_CELL_MONITOR
#ifdef USE_SINGLE_CELL_MONITOR
// configure number maximum connected analog inputs(cells) if you build an six cell network then MAXCELLS is 6 
#define MAXCELLS 6
#endif
/// ~ Wolke lipo-single-cell-monitor

// ******************************************
// Message #0  HEARTHBEAT 
uint8_t    ap_type = 0;
uint8_t    ap_autopilot = 0;
uint8_t    ap_base_mode = 0;
int32_t    ap_custom_mode = -1;
uint8_t    ap_system_status = 0;
uint8_t    ap_mavlink_version = 0;

// Message # 1  SYS_STATUS 
uint16_t   ap_voltage_battery = 0;       // 1000 = 1V
int16_t    ap_current_battery = 0;      //  10 = 1A
int8_t    ap_battery_remaining = 0;   // Remaining battery energy: (0%: 0, 100%: 100), -1: autopilot estimate the remaining battery

// Message #24  GPS_RAW_INT 
uint8_t    ap_fixtype = 3;                //   0= No GPS, 1 = No Fix, 2 = 2D Fix, 3 = 3D Fix
uint8_t    ap_sat_visible = 0;            // number of visible satelites

#ifdef USE_RC_CHANNELS
// Message #65 RC_CHANNELS
uint8_t   ap_chancount = 0;      // Number of RC_Channels used
uint16_t  ap_chan_raw[18] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}; // RC channel x input value, in microseconds. A value of UINT16_MAX (65535U)
//uint8_t   ap_rssi = 0;        // Receive signal strength indicator, 0: 0%, 100: 100%, 255: invalid/unknown.
//uint32_t  ap_time_boot_ms = 0;
#endif

// FrSky Taranis uses the first recieved lat/long as homeposition. 
int32_t    ap_latitude = 0;               // 585522540;
int32_t    ap_longitude = 0;              // 162344467;
int32_t    ap_gps_altitude = 0;           // 1000 = 1m
int32_t    ap_gps_speed = 0;
uint16_t   ap_gps_hdop = 255;             // GPS HDOP horizontal dilution of position in cm (m*100). If unknown, set to: 65535
// uint16_t    ap_vdop=0;                 // GPS VDOP horizontal dilution of position in cm (m*100). If unknown, set to: 65535
uint32_t    ap_cog = 0;                // Course over ground (NOT heading, but direction of movement) in degrees * 100, 0.0..359.99 degrees. If unknown, set to: 65535


// Message #74 VFR_HUD 
uint32_t  ap_groundspeed = 0;       // Current ground speed in m/s
uint32_t  ap_heading = 0;           // Current heading in degrees, in compass units (0..360, 0=north)
uint16_t  ap_throttle = 0;          // Current throttle setting in integer percent, 0 to 100

// uint32_t  ap_alt=0;             //Current altitude (MSL), in meters
// int32_t   ap_airspeed = 0;      // Current airspeed in m/s


// FrSky Taranis uses the first recieved value after 'PowerOn' or  'Telemetry Reset'  as zero altitude
int32_t    ap_bar_altitude = 0;    // 100 = 1m
int32_t    ap_climb_rate=0;        // 100= 1m/s

// Messages needed to use current Angles and axis speeds
// Message #30 ATTITUDE           //MAVLINK_MSG_ID_ATTITUDE
int32_t ap_roll_angle = 0;    //Roll angle (deg -180/180)
int32_t ap_pitch_angle = 0;   //Pitch angle (deg -180/180)
uint32_t ap_yaw_angle = 0;     //Yaw angle (rad)
uint32_t ap_roll_speed = 0;    //Roll angular speed (rad/s)
uint32_t ap_pitch_speed = 0;   //Pitch angular speed (rad/s)
uint32_t ap_yaw_speed = 0;     //Yaw angular speed (rad/s)


// Message #253 MAVLINK_MSG_ID_STATUSTEXT
uint16_t   ap_status_severity = 255;
uint16_t   ap_status_send_count = 0;
uint16_t   ap_status_text_id = 0;
mavlink_statustext_t statustext;

/*
  MAV_SEVERITY_EMERGENCY=0, System is unusable. This is a "panic" condition.
  MAV_SEVERITY_ALERT=1, Action should be taken immediately. Indicates error in non-critical systems.
  MAV_SEVERITY_CRITICAL=2, Action must be taken immediately. Indicates failure in a primary system.
  MAV_SEVERITY_ERROR=3, Indicates an error in secondary/redundant systems.
  MAV_SEVERITY_WARNING=4, Indicates about a possible future error if this is not resolved within a given timeframe. Example would be a low battery warning.
  MAV_SEVERITY_NOTICE=5, An unusual event has occured, though not an error condition. This should be investigated for the root cause.
  MAV_SEVERITY_INFO=6, Normal operational messages. Useful for logging. No action is required for these messages.
  MAV_SEVERITY_DEBUG=7, Useful non-operational messages that can assist in debugging. These should not occur during normal operation.
  MAV_SEVERITY_ENUM_END=8,
*/


// ******************************************
// These are special for FrSky
int32_t     vfas = 0;                // 100 = 1,0V
int32_t     gps_status = 0;     // (ap_sat_visible * 10) + ap_fixtype
// ex. 83 = 8 sattelites visible, 3D lock 
uint8_t   ap_cell_count = 0;

// ******************************************
uint8_t     MavLink_Connected;
uint8_t     buf[MAVLINK_MAX_PACKET_LEN];

uint16_t  hb_count;

unsigned long MavLink_Connected_timer;
unsigned long hb_timer;

int led = 13;

mavlink_message_t msg;
mavlink_system_t mavlink_system = {MY_SYSID,MY_CMPID};

/// Wolke lipo-single-cell-monitor
#ifdef USE_SINGLE_CELL_MONITOR

//cell voltage divider. this is dependent from your resitor voltage divider network
double LIPOCELL_1TO8[13] =
{
  1905.331599479, // 277.721518987, //1897.85344189,// 10bit 237.350026082,   3,97
  929.011553273,  // 137.358490566, //926.799312208,// 10bit 116.006256517,   8,03
  615.667808219,  // 91.373534338,  //618.198183455,// 10bit 77.3509473318,  12,04
  0.0, // 470.134166514,// 10bit 58.7966886122,
  0.0, // 370.317778975,// 10bit 46.3358699051,
  0.0, // 315.045617465,// 10bit 39.4176445024,
  0.0, // diverders 7-12 not defined because my network includes only 6 voltage dividers
  0.0,
  0.0,
  0.0,
  0.0,
  0.0
};

double individualcelldivider[MAXCELLS+1];
uint8_t analogread_threshold = 100;         // threshold for connected zelldetection in mV
uint8_t cells_in_use = MAXCELLS;
int32_t zelle[MAXCELLS+1];
double cell[MAXCELLS+1];
int32_t alllipocells = 0;
float lp_filter_val = 0.99; // this determines smoothness  - .0001 is max  0.99 is off (no smoothing)
double smoothedVal[MAXCELLS+1]; // this holds the last loop value

#endif
/// ~Wolke lipo-single-cell-monitor

// ******************************************
void setup()  {
  
  delay(20000);   // Waiting 20sec for bootup of pixhawk or apm
  
  FrSkySPort_Init();
  

  


  _MavLinkSerial.begin(_MavLinkSerialBaud);
  MavLink_Connected = 0;
  MavLink_Connected_timer=millis();
  hb_timer = millis();
  hb_count = 0;

  pinMode(led,OUTPUT);
  pinMode(12,OUTPUT);

  pinMode(14,INPUT);
  
  analogReadResolution(13);
  analogReference(DEFAULT);

  /// Wolke lipo-single-cell-monitor
#ifdef USE_SINGLE_CELL_MONITOR
  for(int i = 0; i < MAXCELLS; i++){
    zelle[i] = 0;
    cell[i] = 0.0;
    individualcelldivider[i] = LIPOCELL_1TO8[i];
    smoothedVal[i] = 900.0;
  }
#endif
  /// ~Wolke lipo-single-cell-monitor

}


// ******************************************
void loop()  {

  /// Wolke lipo-single-cell-monitor
#ifdef USE_SINGLE_CELL_MONITOR
  double aread[MAXCELLS+1];
  for(int i = 0; i < MAXCELLS; i++){
    aread[i] = analogRead(i);
    if(aread[i] < analogread_threshold ){
      cells_in_use = i;
      break;
    }
    else {
      cells_in_use = MAXCELLS;
    }
    // USE Low Pass filter
    smoothedVal[i] = ( aread[i] * (1 - lp_filter_val)) + (smoothedVal[i]  *  lp_filter_val);
    aread[i] = round(smoothedVal[i]);
    cell[i] = double (aread[i]/individualcelldivider[i]) * 1000;
    if( i == 0 ) zelle[i] = round(cell[i]);
    else zelle[i] =  round(cell[i] - cell[i-1]);
  }
  alllipocells = cell[cells_in_use -1];

#ifdef DEBUG_LIPO_SINGLE_CELL_MONITOR
  debugSerial.println(aread[0]);
  debugSerial.println(cell[0]);
  debugSerial.println("-------");
  
  for(int i = 0; i < MAXCELLS; i++){
    debugSerial.print(cell[i]/1000);
    debugSerial.print("V, ");
  }
  debugSerial.println();
  
  for(int i = 0; i < MAXCELLS; i++){
    debugSerial.print( aread[i]);
    debugSerial.print( ", ");    
  }  
  debugSerial.print("cells in use: ");
  debugSerial.print(cells_in_use);
  debugSerial.print( ", ");
  debugSerial.print(", sum ");
  debugSerial.println(alllipocells);
#endif
#endif
  /// ~Wolke lipo-single-cell-monitor

  // Send a heartbeat over the mavlink
  uint16_t len;
  //mavlink_msg_heartbeat_pack(123, 123, &msg, MAV_TYPE_ONBOARD_CONTROLLER, MAV_AUTOPILOT_GENERIC, MAV_MODE_PREFLIGHT, <CUSTOM_MODE>, MAV_STATE_STANDBY);
  //mavlink_msg_heartbeat_pack(mavlink_system.sysid, mavlink_system.compid, &msg, 0, 18, 0, 0, 4);
  //len = mavlink_msg_to_send_buffer(buf, &msg);
  //_MavLinkSerial.write(buf,len);

  if(millis()-hb_timer > 1500) {
    hb_timer=millis();
    if(!MavLink_Connected) {    // Start requesting data streams from MavLink
#ifdef DEBUG_MODE
      debugSerial.print(millis());
      debugSerial.print("\tEntering stream request");
      debugSerial.println();
#endif
      digitalWrite(led,HIGH);
      // mavlink_msg_request_data_stream_pack(0xFF,0xBE,&msg,1,1,MAV_DATA_STREAM_EXTENDED_STATUS, MSG_RATE, START);
      mavlink_msg_request_data_stream_pack(mavlink_system.sysid,mavlink_system.compid,&msg,1,1,MAV_DATA_STREAM_EXTENDED_STATUS, MSG_RATE, START);
      len = mavlink_msg_to_send_buffer(buf, &msg);
      _MavLinkSerial.write(buf,len);
      delay(10);
      mavlink_msg_request_data_stream_pack(mavlink_system.sysid,mavlink_system.compid,&msg,1,1,MAV_DATA_STREAM_EXTRA2, MSG_RATE, START);
      len = mavlink_msg_to_send_buffer(buf, &msg);
      _MavLinkSerial.write(buf,len);
      delay(10);
      mavlink_msg_request_data_stream_pack(mavlink_system.sysid,mavlink_system.compid,&msg,1,1,MAV_DATA_STREAM_RAW_SENSORS, MSG_RATE, START);
      len = mavlink_msg_to_send_buffer(buf, &msg);
      _MavLinkSerial.write(buf,len);
#ifdef USE_RC_CHANNELS
      delay(10);
      mavlink_msg_request_data_stream_pack(mavlink_system.sysid,mavlink_system.compid,&msg,1,1,MAV_DATA_STREAM_RC_CHANNELS, MSG_RATE, START);
      len = mavlink_msg_to_send_buffer(buf, &msg);
      _MavLinkSerial.write(buf,len);
#endif
      digitalWrite(led,LOW);
    }
  }

  if((millis() - MavLink_Connected_timer) > 1500)  {   // if no HEARTBEAT from APM  in 1.5s then we are not connected
    MavLink_Connected=0;
    hb_count = 0;
  } 

  _MavLink_receive();                   // Check MavLink communication

  FrSkySPort_Process();               // Check FrSky S.Port communication


  


}


void _MavLink_receive() { 
  mavlink_message_t msg;
  mavlink_status_t status;

  while(_MavLinkSerial.available()) 
  { 
    uint8_t c = _MavLinkSerial.read();
    if(mavlink_parse_char(MAVLINK_COMM_0, c, &msg, &status) && (AP_SYSID == msg.sysid && AP_CMPID == msg.compid)) // only proceed with autopilot messages
    {
      switch(msg.msgid)
      {
      case MAVLINK_MSG_ID_HEARTBEAT:  // 0
        ap_base_mode = (mavlink_msg_heartbeat_get_base_mode(&msg) & 0x80) > 7;
        ap_custom_mode = mavlink_msg_heartbeat_get_custom_mode(&msg);
#ifdef DEBUG_MODE
        debugSerial.print(millis());
        debugSerial.print("\tMAVLINK_MSG_ID_SYS_STATUS: base_mode: ");
        debugSerial.print((mavlink_msg_heartbeat_get_base_mode(&msg) & 0x80) > 7);
        debugSerial.print(", custom_mode: ");
        debugSerial.print(mavlink_msg_heartbeat_get_custom_mode(&msg));
        debugSerial.println();
#endif              
        MavLink_Connected_timer=millis(); 
        if(!MavLink_Connected); 
        {
          hb_count++;   
          if((hb_count++) > 10) {        // If  received > 10 heartbeats from MavLink then we are connected
            MavLink_Connected=1;
            hb_count=0;
            digitalWrite(led,HIGH);      // LED will be ON when connected to MavLink, else it will slowly blink
          }
        }
        break;
      case MAVLINK_MSG_ID_STATUSTEXT:     //253
        mavlink_msg_statustext_decode(&msg,&statustext);
        ap_status_severity = statustext.severity;
        ap_status_send_count = 5;
        parseStatusText(statustext.severity, statustext.text);
        
#ifdef DEBUG_STATUS
        debugSerial.print(millis());
        debugSerial.print("\tMAVLINK_MSG_ID_STATUSTEXT: severity ");
        debugSerial.print(statustext.severity);
        debugSerial.print(", text");
        debugSerial.print(statustext.text);
        debugSerial.println();
#endif
        break;
break; 
      case MAVLINK_MSG_ID_SYS_STATUS :   // 1
#ifdef USE_AP_VOLTAGE_BATTERY_FROM_SINGLE_CELL_MONITOR
        ap_voltage_battery = alllipocells;
        //no lipo to network connected use reported mavlink_msg voltage
        if(cells_in_use == 0) ap_voltage_battery = mavlink_msg_sys_status_get_voltage_battery(&msg);
#else
        ap_voltage_battery = mavlink_msg_sys_status_get_voltage_battery(&msg);  // 1 = 1mV
#endif
        ap_current_battery = mavlink_msg_sys_status_get_current_battery(&msg);     // 1=10mA
        ap_battery_remaining = mavlink_msg_sys_status_get_battery_remaining(&msg); //battery capacity reported in %
        storeVoltageReading(ap_voltage_battery);
        storeCurrentReading(ap_current_battery);

#ifdef DEBUG_BAT
        debugSerial.print(millis());
        debugSerial.print("\tMAVLINK_MSG_ID_SYS_STATUS: voltage_battery: ");
        debugSerial.print(mavlink_msg_sys_status_get_voltage_battery(&msg));
        debugSerial.print(", current_battery: ");
        debugSerial.print(mavlink_msg_sys_status_get_current_battery(&msg));
        debugSerial.println();
#endif
        uint8_t temp_cell_count;
#ifdef USE_SINGLE_CELL_MONITOR
        ap_cell_count = cells_in_use;
        if(cells_in_use == 0){
          if(ap_voltage_battery > 21000) temp_cell_count = 6;
          else if (ap_voltage_battery > 17500) temp_cell_count = 5;
          else if(ap_voltage_battery > 12750) temp_cell_count = 4;
          else if(ap_voltage_battery > 8500) temp_cell_count = 3;
          else if(ap_voltage_battery > 4250) temp_cell_count = 2;
          else temp_cell_count = 0;
          if(temp_cell_count > ap_cell_count)
            ap_cell_count = temp_cell_count;          
        }
        break;
#else
        if(ap_voltage_battery > 21000) temp_cell_count = 6;
        else if (ap_voltage_battery > 17500) temp_cell_count = 5;
        else if(ap_voltage_battery > 12750) temp_cell_count = 4;
        else if(ap_voltage_battery > 8500) temp_cell_count = 3;
        else if(ap_voltage_battery > 4250) temp_cell_count = 2;
        else temp_cell_count = 0;
        if(temp_cell_count > ap_cell_count)
          ap_cell_count = temp_cell_count;
        break;
#endif

      case MAVLINK_MSG_ID_GPS_RAW_INT:   // 24
        ap_fixtype = mavlink_msg_gps_raw_int_get_fix_type(&msg);                               // 0 = No GPS, 1 =No Fix, 2 = 2D Fix, 3 = 3D Fix
        ap_sat_visible =  mavlink_msg_gps_raw_int_get_satellites_visible(&msg);          // numbers of visible satelites
        gps_status = (ap_sat_visible*10) + ap_fixtype; 
        ap_gps_hdop = mavlink_msg_gps_raw_int_get_eph(&msg)/4;
        // Max 8 bit
        if(ap_gps_hdop == 0 || ap_gps_hdop > 255)
          ap_gps_hdop = 255;
        if(ap_fixtype == 3)  {
          ap_latitude = mavlink_msg_gps_raw_int_get_lat(&msg);
          ap_longitude = mavlink_msg_gps_raw_int_get_lon(&msg);
          ap_gps_altitude = mavlink_msg_gps_raw_int_get_alt(&msg);      // 1m =1000
          ap_gps_speed = mavlink_msg_gps_raw_int_get_vel(&msg);         // 100 = 1m/s
        }
        else
        {
          ap_gps_speed = 0;  
        }
#ifdef DEBUG_GPS_RAW    
        debugSerial.print(millis());
        debugSerial.print("\tMAVLINK_MSG_ID_GPS_RAW_INT: fixtype: ");
        debugSerial.print(ap_fixtype);
        debugSerial.print(", visiblesats: ");
        debugSerial.print(ap_sat_visible);
        debugSerial.print(", status: ");
        debugSerial.print(gps_status);
        debugSerial.print(", gpsspeed: ");
        debugSerial.print(mavlink_msg_gps_raw_int_get_vel(&msg)/100.0);
        debugSerial.print(", hdop: ");
        debugSerial.print(mavlink_msg_gps_raw_int_get_eph(&msg)/100.0);
        debugSerial.print(", alt: ");
        debugSerial.print(mavlink_msg_gps_raw_int_get_alt(&msg));
        debugSerial.println();                                     
#endif
        break;

      case MAVLINK_MSG_ID_RAW_IMU:   // 27
        storeAccX(mavlink_msg_raw_imu_get_xacc(&msg) / 10);
        storeAccY(mavlink_msg_raw_imu_get_yacc(&msg) / 10);
        storeAccZ(mavlink_msg_raw_imu_get_zacc(&msg) / 10);

#ifdef DEBUG_ACC
        debugSerial.print(millis());
        debugSerial.print("\tMAVLINK_MSG_ID_RAW_IMU: xacc: ");
        debugSerial.print(mavlink_msg_raw_imu_get_xacc(&msg));
        debugSerial.print(", yacc: ");
        debugSerial.print(mavlink_msg_raw_imu_get_yacc(&msg));
        debugSerial.print(", zacc: ");
        debugSerial.print(mavlink_msg_raw_imu_get_zacc(&msg));
        debugSerial.println();
#endif
        break;

      case MAVLINK_MSG_ID_ATTITUDE:     //30
        ap_roll_angle = mavlink_msg_attitude_get_roll(&msg)*180/3.1416;  //value comes in rads, convert to deg
        // Not upside down
        if(abs(ap_roll_angle) <= 90)
        {
          ap_pitch_angle = mavlink_msg_attitude_get_pitch(&msg)*180/3.1416; //value comes in rads, convert to deg
        }
        // Upside down
        else
        {
          ap_pitch_angle = 180-mavlink_msg_attitude_get_pitch(&msg)*180/3.1416; //value comes in rads, convert to deg
        }
        ap_yaw_angle = (mavlink_msg_attitude_get_yaw(&msg)+3.1416)*162.9747; //value comes in rads, add pi and scale to 0 to 1024
      
#ifdef DEBUG_ATTITUDE
        debugSerial.print("MAVLINK Roll Angle: ");
        debugSerial.print(mavlink_msg_attitude_get_roll(&msg));
        debugSerial.print(" (");
        debugSerial.print(ap_roll_angle);
        debugSerial.print("deg)");
        debugSerial.print("\tMAVLINK Pitch Angle: ");
        debugSerial.print(mavlink_msg_attitude_get_pitch(&msg));
        debugSerial.print(" (");
        debugSerial.print(ap_pitch_angle);
        debugSerial.print("deg)");
        debugSerial.print("\tMAVLINK Yaw Angle: ");
        debugSerial.print(mavlink_msg_attitude_get_yaw(&msg));
        debugSerial.println();
#endif
        break;
        
#ifdef USE_RC_CHANNELS
      case MAVLINK_MSG_ID_RC_CHANNELS:    //65    
        ap_chancount = mavlink_msg_rc_channels_get_chancount(&msg);     // Number of RC Channels used
        //ap_time_boot_ms = mavlink_msg_rc_channels_get_time_boot_ms(&msg);
        ap_chan_raw[1] = mavlink_msg_rc_channels_get_chan1_raw(&msg);   // The PPM values of the RC channels received. 
        ap_chan_raw[2] = mavlink_msg_rc_channels_get_chan2_raw(&msg);   // The standard PPM modulation is as follows: 
        ap_chan_raw[3] = mavlink_msg_rc_channels_get_chan3_raw(&msg);   // 1000 microseconds: 0%, 2000 microseconds: 100%. 
        ap_chan_raw[4] = mavlink_msg_rc_channels_get_chan4_raw(&msg);   // Individual receivers/transmitters might violate this specification.
        ap_chan_raw[5] = mavlink_msg_rc_channels_get_chan5_raw(&msg);
        ap_chan_raw[6] = mavlink_msg_rc_channels_get_chan6_raw(&msg);
        ap_chan_raw[7] = mavlink_msg_rc_channels_get_chan7_raw(&msg);
        ap_chan_raw[8] = mavlink_msg_rc_channels_get_chan8_raw(&msg);
        
        ap_chan_raw[9] = mavlink_msg_rc_channels_get_chan9_raw(&msg);
        ap_chan_raw[10] = mavlink_msg_rc_channels_get_chan10_raw(&msg);
        ap_chan_raw[11] = mavlink_msg_rc_channels_get_chan11_raw(&msg);
        ap_chan_raw[12] = mavlink_msg_rc_channels_get_chan12_raw(&msg);
        ap_chan_raw[13] = mavlink_msg_rc_channels_get_chan13_raw(&msg);
        ap_chan_raw[14] = mavlink_msg_rc_channels_get_chan14_raw(&msg);
        ap_chan_raw[15] = mavlink_msg_rc_channels_get_chan15_raw(&msg);
        ap_chan_raw[16] = mavlink_msg_rc_channels_get_chan16_raw(&msg);
        ap_chan_raw[17] = mavlink_msg_rc_channels_get_chan17_raw(&msg);
        ap_chan_raw[18] = mavlink_msg_rc_channels_get_chan18_raw(&msg);
        //ap_rssi = mavlink_msg_rc_channels_get_rssi(&msg);       // Receive signal strength indicator, 0: 0%, 100: 100%, 255: invalid/unknown.

#ifdef DEBUG_RC_CHANNELS
        debugSerial.print(millis());
        debugSerial.print(" - ");
        //debugSerial.print(ap_time_boot_ms);
        debugSerial.print("\tMAVLINK_MSG_ID_RC_CHANNELS: chancount: ");
        debugSerial.print(ap_chancount);
        debugSerial.println();
        debugSerial.print("\tMAVLINK_MSG_ID_RC_CHANNELS: ap_chan1-4_raw: ");
        for (int i = 1; i <= 4; i++) {
          debugSerial.print(ap_chan_raw[i]);
          debugSerial.print(", ");
        }
        debugSerial.println();
        debugSerial.print("\tMAVLINK_MSG_ID_RC_CHANNELS: ap_chan5-8_raw: ");
        for (int i = 5; i <= 8; i++) {
          debugSerial.print(ap_chan_raw[i]);
          debugSerial.print(", ");
        }
        debugSerial.println();
        debugSerial.print("\tMAVLINK_MSG_ID_RC_CHANNELS: ap_chan9-12_raw: ");
        for (int i = 9; i <= 12; i++) {
          debugSerial.print(ap_chan_raw[i]);
          debugSerial.print(", ");
        }
        debugSerial.println();
        debugSerial.print("\tMAVLINK_MSG_ID_RC_CHANNELS: ap_chan13-16_raw: ");
        for (int i = 13; i <= 16; i++) {
          debugSerial.print(ap_chan_raw[i]);
          debugSerial.print(", ");
        }
        debugSerial.println();
        debugSerial.print("\tMAVLINK_MSG_ID_RC_CHANNELS: ap_chan17-18_raw: ");
        for (int i = 16; i < 18; i++) {
          debugSerial.print(ap_chan_raw[i]);
          debugSerial.print(", ");
        }
        debugSerial.println();
#endif
      break;
#endif

      case MAVLINK_MSG_ID_VFR_HUD:   //  74
        ap_groundspeed = mavlink_msg_vfr_hud_get_groundspeed(&msg);      // 100 = 1m/s
        ap_heading = mavlink_msg_vfr_hud_get_heading(&msg);              // 100 = 100 deg
        ap_throttle = mavlink_msg_vfr_hud_get_throttle(&msg);            //  100 = 100%
        ap_bar_altitude = mavlink_msg_vfr_hud_get_alt(&msg) * 100;       //  m
        ap_climb_rate=mavlink_msg_vfr_hud_get_climb(&msg) * 100;         //  m/s
#ifdef DEBUG_VFR_HUD
        debugSerial.print(millis());
        debugSerial.print("\tMAVLINK_MSG_ID_VFR_HUD: groundspeed: ");
        debugSerial.print(ap_groundspeed);
        debugSerial.print(", heading: ");
        debugSerial.print(ap_heading);
        debugSerial.print(", throttle: ");
        debugSerial.print(ap_throttle);
        debugSerial.print(", alt: ");
        debugSerial.print(ap_bar_altitude);
        debugSerial.print(", climbrate: ");
        debugSerial.print(ap_climb_rate);
        debugSerial.println();
#endif
        break; 
      default:
#ifdef DEBUG_MAVLINK_MSGS
        debugSerial.print(millis());
        debugSerial.print("\tMSG: ");
        debugSerial.print(msg.msgid);        
        debugSerial.println();
#endif
        break;
      }

    } else if (GB_SYSID == msg.sysid && GB_CMPID == msg.compid) // only proceed with gimbal messages
    {
      switch(msg.msgid)
      {
      case MAVLINK_MSG_ID_HEARTBEAT:  // 0
#ifdef DEBUG_MODE
        debugSerial.print(millis());
        debugSerial.print("\tGIMBAL MESSAGE: ");
        debugSerial.print((mavlink_msg_heartbeat_get_base_mode(&msg) & 0x80) > 7);
        debugSerial.print(", custom_mode: ");
        debugSerial.print(mavlink_msg_heartbeat_get_custom_mode(&msg));
        debugSerial.println();
#endif              
      break;
      }
    } else {
      switch(msg.msgid)
      {
      case MAVLINK_MSG_ID_HEARTBEAT:  // 0
#ifdef DEBUG_MODE
        debugSerial.print(millis());
        debugSerial.print("\tOTHER MESSAGE: ");
        debugSerial.print("sysid: ");
        debugSerial.print(msg.sysid);
        debugSerial.print(", compid: ");
        debugSerial.print(msg.compid);
        debugSerial.print(", base_mode: ");
        debugSerial.print((mavlink_msg_heartbeat_get_base_mode(&msg) & 0x80) > 7);
        debugSerial.print(", custom_mode: ");
        debugSerial.print(mavlink_msg_heartbeat_get_custom_mode(&msg));
        debugSerial.println();
#endif              
      break;
      }
    }      
    
  }
}
