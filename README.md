MavLink_FrSkySPort
==================
This is a modified version of the mavlink to frsky s.port code found here:
http://diydrones.com/forum/topics/amp-to-frsky-x8r-sport-converter

It's based on the official 1.3 version.

The main focus of this script and teensy modification is the exact monitoring of the flight battery capacity and voltage. The consumption in mA / h and watt-hours can be calibrated on a separate model script. Moreover, by the modification described below on teensy, which are allowed lipo monitors individual cell voltage. The radar on the left represents the position and the orientation of the vehicle.

![](https://raw.githubusercontent.com/wolkstein/MavLink_FrSkySPort/s-c-l-v-rc/tele1simu.jpg)


The interface between the APM/PixHawk and the FrSky X series receiver is a small Teensy 3.1 board running a custom protocol translator from Mavlink to SPort telemetry.

Almost all the parameters on the normal telemetry screens of the Taranis X9D are correct, with some exceptions (RPM and T2), that combine multiple values on a single field.

Cell ( Voltage of Cell=Cells/(Number of cells). [V]) 

Cells ( Voltage from LiPo [V] )

A2 ( HDOP value * 25 - 8 bit resolution)

A3 ( Roll angle from -Pi to +Pi radians, converted to a value between 0 and 1024)

A4 ( Pitch angle from -Pi/2 to +Pi/2 radians, converted to a value between 0 and 1024)

Alt ( Altitude from baro. [m] )

GAlt ( Altitude from GPS [m])

HDG ( Compass heading [deg]) v

Rpm ( Throttle when ARMED [%] *100 + % battery remaining as reported by Mavlink)

VSpd ( Vertical speed [m/s] )

Speed ( Ground speed from GPS, [km/h] )

T1 ( GPS status = ap_sat_visible*10) + ap_fixtype )

T2 ( Armed Status and Mavlink Messages :- 16 bit value: bit 1: armed - bit 2-5: severity +1 (0 means no message - bit 6-15: 
number representing a specific text)

Vfas ( same as Cells )

Longitud ( Longitud )

Latitud ( Latitud )

Dist ( Will be calculated by FrSky Taranis as the distance from first received lat/long = Home Position )

Fuel ( Current Flight Mode reported by Mavlink )

AccX ( X Axis average vibration m/s?)

AccY ( Y Axis average vibration m/s?)

AccZ ( Z Axis average vibration m/s?)

Also, this script relies heavily on voice alerts and prompts.

The screen explanation:

![](https://raw.githubusercontent.com/wolkstein/MavLink_FrSkySPort/s-c-l-v-rc/tele1+lables.jpeg)

A-Current Flight Mode Active as reported by the Flight Controller. If blinking the vehicle is not Armed.

B-Current Flight Mode Timer. Each Flight Mode has its own timer. The timer stops if the vehicle is not Armed.

C-Radio Transmitter Battery Voltage.

D-RSSI value

E-Reported Flight Battery Voltage from MavLink or if teensy a0-a6 are connected will measured Voltage from lipo balancer connectors. 

F-Reported Flight Battery Current.

G-Actual power output in Watts (VxA)

H-consumed power in mA/h, offset adjustable from Modelscript

I-consumed power in Wh, offset adjustable from Modelscript

J-Lipo Cell minimum. this simple display lowest cell from your lipo

K-Heading in degrees

L-Baro-Altitude

M-Maximum reached Altitude

N-Armed Time Timer - Starts and stops when the Vehicle is armed/disarmed

O-Speed in Km/h

P-GPS Indicator, 3D, 2D or no status

Q-HDop indicator. Blinks when over 2

R-Number of reported satellites

V-Radar

S-Vehicle Arrow can move and rotate. this display position relative to home and heading relative to home

T-Home/Centre Position

U-Distance to home (Distance to the point the Taranis received a good satellite fix) 



Single Cell Lipo Voltage Monitor
================================

this increase the teensy functionality to measure all lipo cells separate via lipo balancer jack. this require teensy pins A0 to A5(6S Lipo) connected via an voltage divider resistor network.

if connecting the lipo balancer plug to your teensy, it will be important to divide all lipo-cell voltage outputs to a value <= 3,3V.

example for an full 6S Lipo(25,2V):

LipoCell | R1 in series to cell | R2 to gnd | software  divider 

S1  4,2V |   1k  |  3k3 |  237.350026082

S2  8,4V |   2k  |  1k2 |  116.006256517

S3 12,6V |   3k6 |  1k2 |  77.3509473318

S4 16,8V |   5k1 |  1k2 |  58.7966886122

S5 21,0V |   6k8 |  1k2 |  46.3358699051

S6 25,2V |  11k  |  1k6 |  39.4176445024

all needed resistors found in E24 series. the divider are defined in MavLink_FrSkySPort.ino. if you use other resistors all dividers must recalculated.

![](https://raw.githubusercontent.com/wolkstein/MavLink_FrSkySPort/single-cell-lipo-voltage/resistor_network.jpg)


![](https://raw.githubusercontent.com/wolkstein/MavLink_FrSkySPort/single-cell-lipo-voltage/CellsScreen.jpg)


![](https://raw.githubusercontent.com/wolkstein/MavLink_FrSkySPort/single-cell-lipo-voltage/MainScreen.jpg)




