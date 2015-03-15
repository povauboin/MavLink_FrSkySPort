important,

on teensy2 or pro mini it is important to hold the estimated memory use below 2000 bytes of a 2.560 byte maximum.

in Average.ino function void parseStatusText(int32_t severity, String text) line 206 holds a lot of Strings which consume memory. this strings are used to parse status text message as ID's. the lua script play this messages as audio messages. so if you need messages i have commented, simple uncomment messages you need. but you also must comment other message to hold the estimated memory use below 2000 bytes.

LED pin:

Teensy2: 11
Pro Mini: 13
