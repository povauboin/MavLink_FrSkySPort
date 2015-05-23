important,

on teensy2 or pro mini it is important to hold the estimated memory use below 2000 bytes of a 2.560 byte maximum.

in Average.ino function void parseStatusText(int32_t severity, String text) line 206 holds a lot of Strings which consume memory. this strings are used to parse status text message as ID's. the lua script play this messages as audio messages. so if you need messages i have commented, simple uncomment messages you need. but you also must comment other message to hold the estimated memory use below 2000 bytes.

in "MavLink_FrSkySPort_Teensy2_and_ProMini.ino" line 59 - 65 change valus dependent to your board.

```
#define _MavLinkSerial      Serial1 // Teensy2 = Serial1 | Pro Mini = Serial
#define debugSerial          Serial 
#define START                     1
#define MSG_RATE                 10 // Hertz
#define FRSKY_PORT                4 // Teensy2 = pin 4 | Pro Mini = pin 9
#define MavLinkSerialBaud     58824 // Teensy2 = 58824 | Pro Mini = 57600
#define LEDPIN                   11 // Teensy2 = pin 11 | Pro Mini = pin 13
```

Teensy2 Connection Diagram:

![](https://raw.githubusercontent.com/wolkstein/MavLink_FrSkySPort/s-c-l-v-rc/APM_MavLink2FrSky_TEENSY2.png)

Pro Mini Connection Diagram:

![](https://raw.githubusercontent.com/wolkstein/MavLink_FrSkySPort/s-c-l-v-rc/APM_MavLink2FrSky_PRO-MINI.jpg)
