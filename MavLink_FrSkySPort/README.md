this increase the teensy functionality to measure all lipo cells separate via lipo balancer jack. this require teensy pins A0 to A5(6S Lipo) connected via an voltage divider resistor network.

it display firstly the lowest lipo cell voltage,secondly the difference between highest and  lowest lipo cell voltage and at least the highest lipo cell voltage.

this will give you an quick overview about the lipo health.

if connecting the lipo balancer plug to your teensy, it will be important to divide all lipo-cell voltage outputs to a value <= 3,3V.

example for an full 6S Lipo(25,2V):

LipoCell | R1 in series to cell | R2 to gnd | software  divider 

S1  4,2V |   1k  |  3k3 |  234.899328859
S2  8,4V |   8k4 |  1k2 |  114.689333174
S3 12,6V |   3k6 |  1k2 |  76.5399737877
S4 16,8V |   5k1 |  1k2 |  58.1913499345
S5 21,0V |   6k8 |  1k2 |  45.8772770853
S6 25,2V |  11k  |  1k6 |  39.0300415468
all needed resistors found in E24 series. the divider are defined in MavLink_FrSkySPort.ino. if you use other resistors all dividers must recalculated. 
