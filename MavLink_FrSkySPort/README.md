this increase the teensy functionality to measure all lipo cells separate via lipo balancer jack. this require teensy pins A0 to A5(6S Lipo) connected via an voltage divider resistor network.

if connecting the lipo balancer plug to your teensy, it will be important to divide all lipo-cell voltage outputs to a value <= 3,3V.

example for an full 6S Lipo(25,2V):

LipoCell | R1 in series to cell | R2 to gnd | software  divider 

S1  4,2V |   1k  |  3k3 |  237.350026082

S2  8,4V |   8k4 |  1k2 |  116.006256517

S3 12,6V |   3k6 |  1k2 |  77.3509473318

S4 16,8V |   5k1 |  1k2 |  58.7966886122

S5 21,0V |   6k8 |  1k2 |  46.3358699051

S6 25,2V |  11k  |  1k6 |  39.4176445024

all needed resistors found in E24 series. the divider are defined in MavLink_FrSkySPort.ino. if you use other resistors all dividers must recalculated.

