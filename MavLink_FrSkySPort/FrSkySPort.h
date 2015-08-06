#ifndef _FRSKY_SPORT_H_
#define _FRSKY_SPORT_H_

enum SensorsEnum {
  SENSOR_ID_VARIO,
  SENSOR_ID_ALTITUDE,
  SENSOR_ID_FLVSS,
  SENSOR_ID_FAS,
  SENSOR_ID_GPS,
  SENSOR_ID_RPM,
  SENSOR_ID_HDOP,
  SENSOR_ID_ACCX,
  SENSOR_ID_ACCY,
  SENSOR_ID_ACCZ,
  SENSOR_ID_GPS_STATUS,
  SENSOR_ID_ROLL_ANGLE,
  SENSOR_ID_PITCH_ANGLE,
  SENSOR_ID_FLIGHT_MODE,
  SENSOR_ID_ARM_MODE,
};

// We'll use some undefined SENSOR_ID's so expect things to break if OpenTX changes

// Frsky-specific
#define START_STOP                  0x7e
#define DATA_FRAME                  0x10

// Frsky DATA ID's
#define FR_ID_ALTITUDE              0x0100	//ALT_FIRST_ID
#define FR_ID_VARIO                 0x0110	//VARIO_FIRST_ID
#define FR_ID_VFAS                  0x0210 	//VFAS_FIRST_ID
#define FR_ID_CURRENT               0x0200 	//CURR_FIRST_ID
#define FR_ID_CELLS                 0x0300	//CELLS_FIRST_ID
#define FR_ID_CELLS_LAST            0x030F 	//CELLS_LAST_ID
#define FR_ID_T1                    0x0400	//T1_FIRST_ID
#define FR_ID_T2                    0x0410	//T2_FIRST_ID
#define FR_ID_RPM                   0x0500 	//RPM_FIRST_ID
#define FR_ID_FUEL                  0x0600	//FUEL_FIRST_ID
#define FR_ID_ACCX                  0x0700	//ACCX_FIRST_ID
#define FR_ID_ACCY                  0x0710	//ACCY_FIRST_ID
#define FR_ID_ACCZ                  0x0720	//ACCZ_FIRST_ID
#define FR_ID_LATLONG               0x0800	//GPS_LONG_LATI_FIRST_ID
#define FR_ID_GPS_ALT               0x0820	//GPS_ALT_FIRST_ID
#define FR_ID_SPEED                 0x0830 	//GPS_SPEED_FIRST_ID
#define FR_ID_GPS_COURSE            0x0840	//GPS_COURS_FIRST_ID
#define FR_ID_GPS_TIME_DATE         0x0850  //GPS_TIME_DATE_FIRST_ID
#define FR_ID_A3_FIRST              0x0900 	//A3_FIRST_ID
#define FR_ID_A4_FIRST              0x0910 	//A4_FIRST_ID
#define FR_ID_AIR_SPEED_FIRST       0x0A00 	//AIR_SPEED_FIRST_ID
#define FR_ID_RSSI                  0xF101  // used by the radio system
#define FR_ID_ADC1                  0xF102  //ADC1_ID
#define FR_ID_ADC2                  0xF103	//ADC2_ID
#define FR_ID_BATT                  0xF104  // used by the radio system
#define FR_ID_SWR                   0xF105  // used by the radio system

/* The following are defined at frsky_sport.cpp (v2.08) but not used here

#define ALT_LAST_ID             0x010f
#define VARIO_LAST_ID           0x011f
#define CURR_LAST_ID            0x020f
#define VFAS_LAST_ID            0x021f
#define T1_LAST_ID              0x040f
#define T2_LAST_ID              0x041f
#define RPM_LAST_ID             0x050f
#define ACCX_LAST_ID            0x070f
#define ACCY_LAST_ID            0x071f
#define ACCZ_LAST_ID            0x072f
#define GPS_LONG_LATI_LAST_ID   0x080f
#define GPS_ALT_LAST_ID         0x082f
#define GPS_SPEED_LAST_ID       0x083f
#define GPS_COURS_LAST_ID       0x084f
#define GPS_TIME_DATE_LAST_ID   0x085f
#define A3_LAST_ID              0x090f
#define A4_LAST_ID              0x091f
#define AIR_SPEED_LAST_ID       0x0a0f
*/

extern "C" void sport_uart0_status_isr(void);

#endif

