local E={"Stabilize","Acro","Altitude Hold","Auto","Guided","Loiter","Return to launch","Circle","Invalid Mode","Land","Optical Loiter","Drift","Invalid Mode","Sport","Flip Mode","Auto Tune","Position Hold","Brake"}local c=(1)local function r()if c==(1)then
c=(2)else
c=(1)end
end
local e=(1)local function i()if e==(1)then
e=(2)else
e=(1)end
end
local d={lat=0,lon=0}local l={lat=0,lon=0,fixtype=0,nsat=0,hdop=0}local a={lat=0,lon=0,hdg=0,dst=0}local function t()if l.fixtype<2 then
return
end
a.lat=l.lat
a.lon=l.lon
a.hdg=getValue("Hdg")a.dst=0
end
local function f(l)if e==(1)then
return l
else
return(l-a.hdg+360)%360
end
end
local function I()return e==(1)and"N"or"R"end
local function o(l,n,e,a)local a=math.rad(a-n)local n=math.rad(e-l)local l=math.rad(e+l)/2
local l=a*math.cos(l)local e=n
local a=6371e3
local a=a*math.sqrt(math.pow(l,2)+math.pow(e,2))local l=(-math.deg(math.atan2(e,l))+90+360)%360
return a,l
end
local w={hdg=0}local s={hdg=0}local n=false
local function N()l.fixtype=getValue("Tmp1")%10
l.nsat=(getValue("Tmp1")-l.fixtype)/10
l.hdop=getValue("A2")/25
if l.fixtype<2 then
return
end
local e=getValue("GPS")if type(e)~="table"then
return
end
if e.lat~=l.lat or e.lon~=l.lon then
d.lat=l.lat
_gps_prv_lon=l.lon
l.lat=e.lat
l.lon=e.lon
end
if not n then
t()n=true
end
a.dst,s.hdg=o(a.lat,a.lon,l.lat,l.lon)null,w.hdg=o(d.lat,_gps_prv_lon,l.lat,l.lon)end
local e=0
local function x()e=0
model.setTimer(0,{mode=0,start=0,value=0,countdownBeep=0,minuteBeep=true,persistent=1})end
local function o()model.setTimer(0,{mode=1,start=0,value=e,countdownBeep=0,minuteBeep=true,persistent=1})end
local function n()e=model.getTimer(0).value
model.setTimer(0,{mode=0,start=0,value=e,countdownBeep=0,minuteBeep=true,persistent=1})end
local function d()playFile("/SOUNDS/en/engarm.wav")o()t()end
local function t()playFile("/SOUNDS/en/engdisa.wav")n()end
local h=(8)local function D()local l=getValue("Fuel")if l<0 or l>17 then
l=(8)end
if l~=h then
playFile("/SOUNDS/en/TELEM/AVFM"..l.."A.wav")h=l
end
end
local S=false
local n={n=0,ts=0}local function O()local l=getValue("Tmp2")local e=bit32.extract(l,0)==1
local a=bit32.extract(l,1,4)local l=bit32.extract(l,5,10)if e~=S then
S=e
if S then
d()else
t()end
end
if a>0 and l~=n.n then
n.n=l
n.ts=getTime()end
if getTime()-n.ts>200 then
n.n=0
end
end
local e=0
local function p()local l=getValue("Cels")if type(l)~="table"then
return
end
local a=false
local n=false
for e,l in ipairs(l)do
if l<=(3.3)then
a=true
elseif l<=(3.5)then
n=true
end
end
local l=getTime()if a and(l-e>500)then
e=l
playFile("/SOUNDS/en/TELEM/ALARM3K.wav")playFile("/SOUNDS/en/batcrit.wav")elseif n and(l-e>1e3)then
e=l
playFile("/SOUNDS/en/batlow.wav")end
end
local function R(l)if l==EVT_ENTER_BREAK then
i()elseif l==EVT_PLUS_BREAK then
r()end
end
local function L(l)return-180+l*360/256
end
local function u(t,n,d,l)local a=math.sin(math.rad(l))local e=math.cos(math.rad(l))for d,l in pairs(d)do
lcd.drawLine(t+l[1]*e-l[2]*a,n+l[1]*a+l[2]*e,t+l[3]*e-l[4]*a,n+l[3]*a+l[4]*e,SOLID,FORCE)end
end
local function e(e,l,d)local a=d
local t=0
for o=10,90,10 do
local n=math.floor(d*math.cos(math.rad(o))+.5)local d=math.floor(d*math.sin(math.rad(o))+.5)lcd.drawLine(e+a,l+t,e+n,l+d,SOLID,SOLID+GREY(5))lcd.drawLine(e+a,l-t,e+n,l-d,SOLID,SOLID+GREY(5))lcd.drawLine(e-a,l+t,e-n,l+d,SOLID,SOLID+GREY(5))lcd.drawLine(e-a,l-t,e-n,l-d,SOLID,SOLID+GREY(5))a=n
t=d
end
end
local d=0
local t=0
local i=0
local r=0
local function g(l,e,a,n)d=l
t=e
i=a
r=n
end
local function m(e,l,a)if e<d then
l=l+(d-e)*math.tan(math.rad(a))e=d
end
if e>i-1 then
l=l-(e-i+1)*math.tan(math.rad(a))e=i-1
end
if l<t then
e=e+(t-l)/math.tan(math.rad(a))l=t
end
if l>r-1 then
e=e-(l-r+1)/math.tan(math.rad(a))l=r-1
end
return e,l
end
local function V(t,l,e,o)local d=0
local c=0
local n=0
local a=0
if t<=e and l<=o then
d,c=t,l
n,a=e,o
elseif t<=e and l>o then
d,c=t,o
n,a=e,l
elseif t>e and l<=o then
else
d,c=t,o
n,a=e,l
end
for i=d,n do
local n=(o-l)/(e-t)local e=math.floor((i-d)*n+1)local l=l+e
local e=n<0 and-e or(a-c)-e
lcd.drawFilledRectangle(i,l,1,e,GREY(4),FORCE)end
lcd.drawFilledRectangle(d,a,n-d+1,r-a+1,GREY(4),FORCE)lcd.drawFilledRectangle(n,c,i-n+1,a-c+1,GREY(4),FORCE)end
local function i(t,d,e,l,o)local a=t-e/2*math.cos(math.rad(l))local n=d-e/2*math.sin(math.rad(l))local t=t+e/2*math.cos(math.rad(l))local e=d+e/2*math.sin(math.rad(l))a,n=m(a,n,l)t,e=m(t,e,l)if o then
V(a,n,t,e)end
lcd.drawLine(a,n,t,e,SOLID,FORCE)end
local function o(e,l,a,t,d,n)lcd.drawLine(e,l,e,l-1+(56),SOLID,FORCE)if n~=-1 then
n=1
end
local o=d%(5)local c=d-o
local i=o*(12)/(5)for d=-3,3 do
local o=c+d*(5)local t=t/2-d*(12)+i
local a=n==1 and 0 or a-1
lcd.drawNumber(e+a,l+t-3,o,0)lcd.drawLine(e,l+t,e+5*n,l+t,SOLID,FORCE)lcd.drawLine(e,l+t+(12)/2,e+3*n,l+t+(12)/2,SOLID,FORCE)end
if(MIDSIZE)==MIDSIZE then
local n=n==1 and 0 or a
lcd.drawFilledRectangle(e-a+n,l+t/2-7,a,14,INVERS)lcd.drawNumber(e+n,l+t/2-6,d,INVERS+MIDSIZE)else
lcd.drawFilledRectangle(e-a,l+t/2-6,a,11,INVERS)lcd.drawNumber(e,l+t/2-4,d,INVERS)end
end
local function d(e,a)local l=INVERS
if not S then
l=l+BLINK
end
lcd.drawText(e+1,a,E[h+1],l)end
local t=getTime()local function S(n,a)local l=getTime()local e=(l-t)*10
if e<=0 then
return
end
lcd.drawNumber(n,a,1e3/e,INVERS)t=l
lcd.drawText(n,a+1,"Hz",SMLSIZE+INVERS)end
local function r(l,e)lcd.drawTimer(l,e,model.getTimer(0).value,INVERS)end
local function t(e,a,l)if l<0 then
l=0
elseif l>(5)then
l=(5)end
for l=1,l do
lcd.drawFilledRectangle(e+1+3*(l-1),a+1+(5-l),2,1+l,0)end
for l=l+1,(5)do
lcd.drawFilledRectangle(e+1+3*(l-1),a+1+(5-l),2,1+l,GREY(14))end
end
local function h(a,l)local e=50
local n=99
local n=(n-e)/(5)local e=math.ceil((getValue("RSSI")-e)/n)t(a,l,e)lcd.drawNumber(a+28,l,getValue("RSSI"),INVERS)lcd.drawText(lcd.getLastPos(),l+1,"dB",SMLSIZE+INVERS)end
local function m(a,e,l)if l<0 then
l=0
elseif l>(5)then
l=(5)end
lcd.drawRectangle(a+1,e+1,13,6)lcd.drawLine(a+14,e+2,a+14,e+5,SOLID,0)for l=1,l do
lcd.drawLine(a+1+2*l,e+3,a+1+2*l,e+4,SOLID,0)end
end
local function t(e,l)local a=((1.5*(6))-(1.1*(6)))/(5)local a=math.ceil((getValue("tx-voltage")-(1.1*(6)))/a)m(e,l,a)lcd.drawNumber(e+30,l,getValue("tx-voltage")*10,INVERS+PREC1)lcd.drawText(lcd.getLastPos(),l+1,"V",SMLSIZE+INVERS)end
local function T(e,l)lcd.drawFilledRectangle(e,l,(212),(8),FORCE)d((0),l)r((104),l)h((135),l)t((176),l)S((86),(0))end
local function m(e,l)if n.n>0 then
lcd.drawNumber(e-1,l+1,n.n,0)end
end
local function r(e,a)local l=getValue("GSpd")if c==(1)then
l=l*1.852
end
o(e,a,(16),((56)),l,1)end
local function E(l,l)end
local function h(e,a)local l=getValue("Alt")if c==(2)then
l=l/.3048
end
o(e,a,(17),((56)),l,-1)end
local function V(e,l)local a=-L(getValue("A3"))local t=-L(getValue("A4"))local c=5*math.sin(math.rad(a))local r=-5*math.cos(math.rad(a))local d=.5*t*math.sin(math.rad(a))local o=-.5*t*math.cos(math.rad(a))i(e+d,l+o,2*((94)-(16)-(17)),a,false)for n=-8,8,2 do
i(e+c*n+d,l+r*n+o,((94)-(16)-(17))/20*math.abs(n),a)end
lcd.drawLine(e-2,l+3,e,l,SOLID,SOLID)lcd.drawLine(e,l,e+2,l+3,SOLID,SOLID)lcd.drawNumber(e-13,l+20,a,SMLSIZE+INVERS)lcd.drawNumber(e+24,l+20,-t,SMLSIZE+INVERS)end
local function S(l,e)lcd.drawLine(l-1+(94),e,l-1+(94),e-1+(56),SOLID,0)g(l+(16),e,l+(16)+((94)-(16)-(17)),e+((56)))V(l+((94)/2),e+((56)/2))r(l+(16),e+(0))E(l,e)h(l+((94)-(17)),e+(0))end
local function h(l,e)lcd.drawLine(l,e-1+(20)/2,l+(118)-1,e-1+(20)/2,SOLID,0)local l=l+(118)/6
local a=getValue("Cels")if type(a)~="table"then
return
end
for a,n in ipairs(a)do
lcd.drawLine(l+1,e,l+1,e-1+(20)/2,SOLID,SOLID)local a=PREC1
if n<=(3.5)then
a=a+BLINK
end
lcd.drawNumber(l-2,e+1,n*10,a)l=l+(118)/6
end
end
local function i(a,e)local l=getValue("VFAS")local l=(l-(3.3*(3)))*100/((4.2*(3))-(3.3*(3)))if l<0 then
l=0
elseif l>100 then
l=100
end
lcd.drawFilledRectangle(a,e,l/100*(118),(20)/2)lcd.drawLine(a,e-1+(20)/2,a-1+(118),e-1+(20)/2,SOLID,SOLID)local a=a+l/100*(118)local n=a-8
local o=INVERS
local t=a+13
local d=0
if l<22 then
n=a+20
o=0
t=a+42
elseif l>84 then
n=a-30
t=a-8
d=INVERS
end
lcd.drawNumber(n,e+1,getValue("VFAS")*10,o+PREC1)lcd.drawText(n,e+2,"V",o+SMLSIZE)lcd.drawNumber(t,e+1,l,d)lcd.drawText(t,e+2,"%",d+SMLSIZE)end
local function r(e,l)h(e,l)i(e,l+(20)/2)end
local function t(a,e,l)if l<0 then
lcd.drawPixmap(a,e,"/SCRIPTS/BMP/arrowdown.bmp")elseif l>0 then
lcd.drawPixmap(a,e,"/SCRIPTS/BMP/arrowup.bmp")else
end
end
local function o(e,a)local l=getValue("VSpd")local n="ms"if c==(2)then
l=l/.3048
n="ft"end
t(e+1,a+3,l)if l>10 or l<-10 then
lcd.drawNumber(e+28,a+3,math.abs(l),MIDSIZE)else
lcd.drawNumber(e+28,a+3,math.abs(l)*10,MIDSIZE+PREC1)end
lcd.drawText(e+28,a+8,n,SMLSIZE)end
local function t(e,a)local l=getValue("GSpd")local n="ms"if c==(1)then
l=l*1.852/3.6
else
l=l*6076/3600
n="ft"end
lcd.drawNumber(e+28,a+3,l*10,MIDSIZE+PREC1)lcd.drawText(e+28,a+8,n,SMLSIZE)end
local function d(l,e)lcd.drawLine(l+((118)/3),e,l+((118)/3),e-1+((36)),SOLID,SOLID)o(l,e)t(l,e+((36))/2)end
local function t(a,n)local e={{-8,6,0,-10},{-7,6,0,-9},{8,6,0,-10},{7,6,0,-9},{-8,6,0,2},{-7,6,0,3},{8,6,0,2},{7,6,0,3},}local l=getValue("Hdg")u(a,n,e,f(l))end
local function n(e,a)local l=12
local n=getValue("GSpd")local l={{0,-l-0,0,-l-5},{0,-l-5,2,-l-3},{0,-l-5,-2,-l-3},}if n>0 then
u(e,a,l,f(w.hdg))end
end
local function o(l,e)lcd.drawLine(l+((118)/3),e,l+((118)/3),e-1+((36)),SOLID,SOLID)lcd.drawText(l-5+((118)/3),e+1,I(),SMLSIZE)local a=string.format("%02d",f(getValue("Hdg"))/10)lcd.drawText(l+2,e+1,a,SMLSIZE)t(l+((118)/3)/2,e+((36))/2)n(l+((118)/3)/2,e+((36))/2)end
local function i(t,a)lcd.drawFilledRectangle(t+1,a,(((118)/3)),(9),0,0)local n=0
local e=" No GPS "if l.fixtype==5 then
e=" GPS RT "elseif l.fixtype==4 then
e=" GPS DF "elseif l.fixtype==3 then
e=" GPS 3D "elseif l.fixtype==2 then
e=" GPS 2D "else
n=BLINK
end
lcd.drawText(t+4,a+1,e,INVERS+SMLSIZE+n)end
local function n(l,e)lcd.drawPixmap(l,e,"/SCRIPTS/BMP/home.bmp")end
local function t(e,l)n(e+2,l+0)lcd.drawNumber(e+28,l+1,a.dst,0)lcd.drawText(e+29,l+2,"m",SMLSIZE)end
local function c(n,e)local l=-8
local l={{0,-l-0,0,-l-15},{0,-l-15,4,-l-11},{0,-l-15,-4,-l-11},}local t={{0,-2,0,2},{-2,0,2,0},}if a.dst>0 then
u(n,e,l,f(s.hdg))else
u(n,e,t,0)end
end
local function n(a,e)lcd.drawLine(a+((118)/3),e,a+((118)/3),e-1+((36)),SOLID,SOLID)i(a,e)c(a+2+((118)/3)/2,e+5+(((36))-(9))/2)lcd.drawNumber(a+14,e+(9)+1,l.hdop*10,PREC1+SMLSIZE)lcd.drawText(a-5+((118)/3),e+(9)+1,I(),SMLSIZE)t(a+2,e+((36))-9)end
local function a(l,e)d(l,e)o(l+((118)/3),e)n(l+((118)/3)+((118)/3),e)end
local function l()N()D()p()O()end
local function e(l)lcd.clear()R(l)S(0,(8))r((94),(8))a((94),(8)+(20))T(0,0)m((212),(8))end
local function a()x()end
return{init=a,run=e,background=l}