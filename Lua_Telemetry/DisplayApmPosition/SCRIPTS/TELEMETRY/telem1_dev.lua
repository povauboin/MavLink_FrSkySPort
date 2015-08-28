----------------------------------------------------------------------------------
-- 2015/08/25                                                                   --
-- Telemetry script for FrSky Taranis                                           --
--                                                                              --
--                                                                              --
--                                                                              --
--                                                                              --
-- Copyright Clooney                                                            --
----------------------------------------------------------------------------------
-- Date of last Change: 2015/08/25                                              --
-- Verion: 0.01                                                                 --
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--                                                                              --
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Do some init tasks - PLEASE DO NOT EDIT                                      --
----------------------------------------------------------------------------------
local _directory = {}



----------------------------------------------------------------------------------
-- User configurable part                                                       --
----------------------------------------------------------------------------------

local play_sounds = false

_directory.sounds = "/SCRIPTS/TELEMETRY/SOUNDS/"
_directory.pics   = "/SCRIPTS/TELEMETRY/BMP/"

local FlightMode = { 
		[0]  = "Stabilize",
		[1]  = "Acro",
		[2]  = "AltHold",
		[3]  = "Auto",
		[4]  = "Guided",
		[5]  = "Loiter",
		[6]  = "RTL",
		[7]  = "Circle",
		[8]  = "Invalid",
		[9]  = "Land",
		[10] = "Invalid",
		[11] = "Drift",
		[12] = "Invalid",
		[13] = "Sport",
		[14] = "Flip",
		[15] = "AutoTune",
		[16] = "PosHold",
		[17] = "Brake"
		}
--		[--] = "12345678901234567890"


-- SMLSIZE = 04x06
-- DEFAULT = 05x07
-- MIDSIZE = 08x10
-- DBLSIZE = 10x14
-- XXLSIZE = 22x38

----------------------------------------------------------------------------------
--            please do not edit below, unless you know what you do             --
----------------------------------------------------------------------------------
modelInfo = model.getInfo()
modelName = modelInfo.name

--Timer 0 is time while vehicle is armed
model.setTimer(0, {mode=0, start=0, value= 0, countdownBeep=0, minuteBeep=1, persistent=1})

--Timer 1 is accumulated time per flight mode
--model.setTimer(1, {mode=0, start=0, value= 0, countdownBeep=0, minuteBeep=0, persistent=1})

----------------------------------------------------------------------------------
-- Variables Definitions                                                        --
----------------------------------------------------------------------------------

local data = {}

local home = {
	set  = 0,
	lat  = 0,
	lon  = 0,
	hdg  = 0,
	time = 0
	}

local apm_status_message = {severity = 0, textid = 0, timestamp = 0, last_played = 0}

local number_cells =  0				-- Cellcount. Used if no single cell voltage available

local lastArmed    = 0    			-- Nur bei Wertwechsel Sound
local last_flight_mode = 0
local SumFlightTime    = 0
local NumFlighModes = 99

local localtime       = 0
local oldlocaltime    = 0
local localtimetwo    = 0
local oldlocaltimetwo = 0

local whconsumed = 0
local maxconsume = 0
local watthours = 0

local offsetX = 0
local offsetY = 0

local arrowLine = {
  {-4, 5, 0, -4},
  {-3, 5, 0, -3},
  {3, 5, 0, -3},
  {4, 5, 0, -4}
}

--local seconds = 0
--local minutes = 0
--local counter = 0
--local lastMeasure = 0

--RIGHTPX = 212
--BOTTOMPX = 63

----------------------------------------------------------------------------------
-- Helper functions                                                             --
----------------------------------------------------------------------------------
local function getValueOrDefault(value)
	local tmp = getValue(value)
	if tmp == nil then
		return 0
	end
	return tmp
end

local function getTelemetryId(name)
	field = getFieldInfo(name)
	if field then
		return field.id
	else
		return -1
	end
end

----------------------------------------------------------------------------------
-- Play sounds function                                                         --
----------------------------------------------------------------------------------
local function playSounds(Value)

	if play_sounds then
		

	end

end

----------------------------------------------------------------------------------
-- Get Telemetry data functions                                                 --
----------------------------------------------------------------------------------
local function getTelemetry()

	local tmp  = 0	
	--local data = {}
	
	-- RPM Sensor Values
	data.t1          = getValue("T1")			-- (ap_sat_visible * 10) + ap_fixtype
	data.t2          = getValue("T2")			-- Armed Status + Severity + Statustext
	data.rpm         = getValue("RPM")			-- ap_throttle * 200+ap_battery_remaining*2
	
	-- FAS Sensor Values
	data.vfas        = getValue("VFAS")			-- Batt Voltage
	data.vfasmin     = getValue("VFAS-min")			-- min Batt Voltage
	data.curr        = getValue("Curr")			-- Current (mA)
	
	-- FLVSS Sensor Values
	data.cels        = getValue("Cels")			-- Cells Voltage
	data.z1          = getValue("Z1")			-- 1. Cell
	data.z2          = getValue("Z2")			-- 2. Cell
	data.z3          = getValue("Z3")			-- 3. Cell
	--data.z4          = getValue("Z4")			-- 4. Cell
	--data.z5          = getValue("Z5")			-- 5. Cell
	--data.z6          = getValue("Z6")			-- 6. Cell
	--data.z7          = getValue("Z7")			-- 7. Cell
	--data.z8          = getValue("Z8")			-- 8. Cell
	data.cmin        = getValue("Cmin")			-- lowest Cell Voltage
	
	-- Consumtion Values
	data.mah         = getValue("mAh")			-- mAh
	data.watt        = getValue("Watt")			-- Watts

	-- GPS Sensor Values
	data.lat         = math.rad(getValue("latitude"))	-- current position Latitude
	data.long        = math.rad(getValue("longitude"))	-- current position Longitude
	data.gps_heading = getValue("Hdg")			-- current heading
	data.gps_speed   = getValue("GSpd")			-- GPS Speed (m/s)
	data.gps_alt     = getValue("GAlt")			-- GPS Alt
	--data.gps_altmax  = getValue("GAltM")			-- max. Alt
	data.distance    = getValue("distance")			-- GPS distance
	data.hdop        = getValue("A2")/10			-- HDOP

	
	-- Angle Values
	data.roll        = getValue("A3")			-- ap_roll_angle  + 180
	data.pitch       = getValue("A4")			-- ap_pitch_angle + 180

	-- Vario Sensor Values
	data.alt         = getValue("Alt")			-- ap_bar_altitude
	data.altmax      = getValue("AltM")			-- max altitude
	data.vario       = getValue("VSpd")			-- ap_climb_rate
	
	-- acceleration Sensor Values
	data.accx        = getValue("AccX")			-- AccX g
	data.accy        = getValue("AccY")			-- AccY g
	data.accz        = getValue("AccZ")			-- AccZ g

	-- Fuel Sensor Values
	data.FMod        = getValue("Fuel")			-- Flightmode

	-- Other Sensor Values
	data.rssi        = getValue("RSSI")			-- RSSI
	data.rxbt        = getValue("RxVt")			-- RxBt
	data.swr         = getValue("SWR")			-- SWR
	--data.txbt        = getValue("tx-voltage")		-- TX-Voltage
	data.txbt        = getValue(189)/10			-- TX-Voltage

	----------------------------------------
	-- combined values from teensy script --
	----------------------------------------

	data.sats        = data.t1%10				-- Number of Sats
	data.fixtype     = (data.t1 - data.sats)/10		-- 0 = no GPS, 1 = no Fix, 2 = 2D Fix, 3 = 3D Fix
	
	data.armed       = 0
	data.armed       = data.t2%0x02				-- 0 = disarmed, 1 = armed
	tmp = (data.t2 - data.armed)/0x02
	data.severity    = tmp%0x10				-- Severity
	tmp = (tmp - data.severity)/0x10
	data.textid      = tmp%0x400				-- Text ID
	
	data.throttle    = data.rpm%200				-- Throttle in percent (0 = 0, 100, 100)
	data.battremain  = (data.rpm - data.throttle)/2		-- Remaining Bat. capacitiy in percent
	

	--return data
	return 0
end

----------------------------------------------------------------------------------
-- Telemetry background tasks                                                   --
----------------------------------------------------------------------------------
local function doTelemetry()
	
	if lastArmed ~= data.armed then
	  if data.armed then
	    if data.fixtype == 3 then
	      home.set  = 1
	      home.lat  = data.lat
	      home.long = data.long
	      home.hdg  = data.gps_heading
	      home.time = getTime()
	    end
	    model.setTimer(0,{ mode=1, start=0, value= SumFlightTime, countdownBeep=0, minuteBeep=1, persistent=1 })
	    -- play_sounds ARMED
	    playSounds("armed")
	  else
	    SumFlightTime = model.getTimer(0).value
	    model.setTimer(0,{ mode=0, start=0, value= model.getTimer(0).value, countdownBeep=0, minuteBeep=1, persistent=1 })
	    -- play_sounds DISARMED
	    playSounds("disarmed")
	  end
	  lastArmed = data.armed
	end

	if data.cmin == 0 then
	  if number_cells == 0 then
	    if data.vfas > 0 then
	      number_cells = math.ceil (data.vfas/4.2)
	    end
	  end
	  if number_cells > 0 then
	    data.cmin = data.vfas / number_cells
	  end
	end

        if data.FMod>NumFlighModes then
          data.FMod=13
        end
        if data.FMod~=last_flight_mode then
          -- play_sounds FlightMode
          -- playFile("/SOUNDS/en/AVFM"..(data.FMod).."A.wav")
	  playSounds("flightmode")
          last_flight_mode=data.FMod
        end

	if data.severity > 0 then
	  if data.severity ~= apm_status_message.severity or data.textid ~= apm_status_message.textid then
	    apm_status_message.severity = data.severity
	    apm_status_message.textid = data.textid
	    apm_status_message.timestamp = getTime()
	  end
	end
	
	if apm_status_message.timestamp > 0 and (apm_status_message.timestamp + 2*100) < getTime() then
	  apm_status_message.severity = 0
	  apm_status_message.textid = 0
	  apm_status_message.timestamp = 0
	  apm_status_message.last_played = 0
	end
	 
	-- play sound
	if apm_status_message.textid >0 then
	  if apm_status_message.last_played ~= apm_status_message.textid then
	    --playFile("SOUNDS/en/MSG"..apm_status_message.textid..".wav")
	    playSounds("apm_status_message.textid")
	    apm_status_message.last_played = apm_status_message.textid
	  end
	end
end

----------------------------------------------------------------------------------
-- play alarm wh reach maximum level                                            --
----------------------------------------------------------------------------------
local function playMaxWhReached()
	if (watthours  + ( watthours * ( model.getGlobalVariable(8, 1)/100) ) ) >= maxconsume then
	  localtimetwo = localtimetwo + (getTime() - oldlocaltimetwo)
	  if localtimetwo >=800 then --8s
	    -- play_sounds MaxWhReached
	    --playFile("/SOUNDS/en/ALARM3K.wav")
	    localtimetwo = 0
	  end
	  oldlocaltimetwo = getTime()
	end
end

----------------------------------------------------------------------------------
--                                                                              --
----------------------------------------------------------------------------------
local function round(num, idp)
	local mult
	mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

----------------------------------------------------------------------------------
-- Calculate watthours                                                          --
----------------------------------------------------------------------------------
local function calcWattHs()
	localtime = localtime + (getTime() - oldlocaltime)
	if localtime >=10 then --100 ms
	  watthours = watthours + ( getValue("Watt") * (localtime/360000) )
	  localtime = 0
	end  
	oldlocaltime = getTime()
	maxconsume = model.getGlobalVariable(8, 2)
end




----------------------------------------------------------------------------------
-- Draw Top Panel                                                               --
----------------------------------------------------------------------------------
local function toppanel()
	lcd.drawFilledRectangle(0, 0, 212, 9, 0)
	if data.armed == 1 then
	  lcd.drawText(1, 0, (FlightMode[data.FMod]), INVERS)
	else
	  lcd.drawText(1, 0, (FlightMode[data.FMod]), INVERS+BLINK)
	end
	lcd.drawText(134, 0, "TX:", INVERS)
	lcd.drawNumber(160, 0, data.txbt, 0+PREC1+INVERS)
	lcd.drawText(lcd.getLastPos(), 0, "v", INVERS)
	lcd.drawText(172, 0, "rssi:", INVERS)
	lcd.drawNumber(lcd.getLastPos()+10, 0, data.rssi, 0+INVERS)
end

----------------------------------------------------------------------------------
-- draw arrow                                                                   --
----------------------------------------------------------------------------------
local function drawArrow()
	local X1 = 0
	local Y1 = 0
	local X2 = 0
	local Y2 = 0
	local sinCorr = 0
	local cosCorr = 0
	local FORCE = 0x02 -- draw ??? line or rectangle
	local CenterXcolArrow = 189
	local CenterYrowArrow = 41

	sinCorr = math.sin(math.rad(data.gps_heading-home.hdg))
	cosCorr = math.cos(math.rad(data.gps_heading-home.hdg))
	for index, point in pairs(arrowLine) do
	  X1 = CenterXcolArrow + offsetX + math.floor(point[1] * cosCorr - point[2] * sinCorr + 0.5)
	  Y1 = CenterYrowArrow + offsetY + math.floor(point[1] * sinCorr + point[2] * cosCorr + 0.5)
	  X2 = CenterXcolArrow + offsetX + math.floor(point[3] * cosCorr - point[4] * sinCorr + 0.5)
	  Y2 = CenterYrowArrow + offsetY + math.floor(point[3] * sinCorr + point[4] * cosCorr + 0.5)
	  
	  if X1 == X2 and Y1 == Y2 then
	    lcd.drawPoint(X1, Y1, SOLID, FORCE)
	  else
	    lcd.drawLine (X1, Y1, X2, Y2, SOLID, FORCE)
	  end
	end

end


----------------------------------------------------------------------------------
-- draw Wh Gauge                                                                --
----------------------------------------------------------------------------------
local function drawWhGauge()
	whconsumed = watthours + ( watthours * ( model.getGlobalVariable(8, 1)/100) )
	if whconsumed >= maxconsume then
	  whconsumed = maxconsume
	end
	lcd.drawFilledRectangle(74,9,11,55,INVERS)
	lcd.drawFilledRectangle(75,9,9, (whconsumed - 0)* ( 55 - 0 ) / (maxconsume - 0) + 0, 0)
end

----------------------------------------------------------------------------------
-- Power Panel                                                                  --
----------------------------------------------------------------------------------
local function powerpanel()
	local xposCons = 0
	
	--Used on power panel -- still to check if all needed
	consumption=getValue("mAh")---
	
	lcd.drawNumber(30,13,data.vfas,DBLSIZE+PREC1)
	lcd.drawText(lcd.getLastPos(),14,"V",0)
	
	lcd.drawNumber(67,9,data.curr,MIDSIZE+PREC1)
	lcd.drawText(lcd.getLastPos(),10,"A",0)

	lcd.drawNumber(67,21,data.watt,MIDSIZE)
	lcd.drawText(lcd.getLastPos(),22,"W",0)

	lcd.drawNumber(1,33,consumption + ( consumption * ( model.getGlobalVariable(8, 0)/100 ) ),MIDSIZE+LEFT)
	xposCons=lcd.getLastPos()
	lcd.drawText(xposCons,32,"m",SMLSIZE)
	lcd.drawText(xposCons,38,"Ah",SMLSIZE)

	lcd.drawNumber(67,33,( watthours + ( watthours * ( model.getGlobalVariable(8, 1)/100) ) ) *10 ,MIDSIZE+PREC1)
	xposCons=lcd.getLastPos()
	lcd.drawText(xposCons,32,"w",SMLSIZE)
	lcd.drawText(xposCons,38,"h",SMLSIZE)

	lcd.drawNumber(42,47,data.cmin,DBLSIZE+PREC2)
	xposCons=lcd.getLastPos()
	lcd.drawText(xposCons,48,"V",SMLSIZE)
	lcd.drawText(xposCons,56,"C-min",SMLSIZE)
end

----------------------------------------------------------------------------------
-- Altitude Panel                                                               --
----------------------------------------------------------------------------------
local function htsapanel()
	
	local htsapaneloffset = 11
	
	lcd.drawLine (htsapaneloffset + 154, 8, htsapaneloffset + 154, 63, SOLID, 0)
	--heading
	lcd.drawText(htsapaneloffset + 76,11,"Heading ",SMLSIZE)
	lcd.drawNumber(lcd.getLastPos(),9,data.gps_heading,MIDSIZE+LEFT)
	lcd.drawText(lcd.getLastPos(),9,"\64",MIDSIZE)
	  
	--altitude
	--Alt max
	lcd.drawText(htsapaneloffset + 76,25,"Alt ",SMLSIZE)
	lcd.drawNumber(lcd.getLastPos()+3,22,data.alt,MIDSIZE+LEFT)
	lcd.drawText(lcd.getLastPos(),22,"m",MIDSIZE)
	--vspeed
	if data.vario == 0 then
	  lcd.drawText(lcd.getLastPos(), 25,"==",0)
	elseif data.vario >0 then
	  lcd.drawText(lcd.getLastPos(), 25,"++",0)
	elseif data.vario <0 then
	  lcd.drawText(lcd.getLastPos(), 25,"--",0)
	end
	lcd.drawNumber(lcd.getLastPos(),25,data.vario,0+LEFT)

	lcd.drawText(htsapaneloffset + 76,35,"Max",SMLSIZE)
	lcd.drawNumber(lcd.getLastPos()+8,35,data.altmax,SMLSIZE+LEFT)
	lcd.drawText(lcd.getLastPos(),35,"m",SMLSIZE)
	
	--Armed time
	lcd.drawTimer(htsapaneloffset + 106,42,model.getTimer(0).value,MIDSIZE)

	lcd.drawText(htsapaneloffset + 76,56,"Speed",SMLSIZE)
	lcd.drawNumber(lcd.getLastPos()+8, 53,data.gps_speed,MIDSIZE+LEFT)

end

----------------------------------------------------------------------------------
-- GPS Panel                                                                    --
----------------------------------------------------------------------------------
local function gpspanel()
	
	local z1 = 0
	local z2 = 0
	local hypdist = 0
	local radTmp = 0
	local radarxtmp = 0
	local radarytmp = 0
	local divtmp = 1
	local upppp = 20480
	local divvv = 2048
  
	if data.fixtype >= 3 then
	  lcd.drawText (168, 10, "3D",0)
	  lcd.drawNumber (195, 10, data.sats, 0+LEFT)
	  lcd.drawText (lcd.getLastPos(), 10, "S", 0)  
	elseif data.fixtype>1 then
	  lcd.drawText (168, 10, "2D", 0)
	  lcd.drawNumber (195, 10, data.sats, 0+LEFT )
	  lcd.drawText (lcd.getLastPos(), 10, "S", 0)
	else
	  lcd.drawText (168, 10, "NO", 0+BLINK+INVERS)
	  lcd.drawText (195, 10, "--S",0)
	end

	if data.hdop <20 then
	  lcd.drawNumber (180, 10, data.hdop, PREC1+LEFT+SMLSIZE )
	else
	  lcd.drawNumber (180, 10, data.hdop, PREC1+LEFT+BLINK+INVERS+SMLSIZE)
	end

	if home.lat~=0 and data.lat~=0 and home.long~=0 and data.long~=0 then
	  z1 = math.sin(data.long - home.long) * math.cos(data.lat)
	  z2 = math.cos(home.lat) * math.sin(data.lat) - math.sin(home.lat) * math.cos(data.lat) * math.cos(data.long - home.long)

	  -- use prearmheading later to rotate cordinates relative to copter.
	  radarx=z1*6358364.9098634 -- meters for x absolut to center(homeposition)
	  radary=z2*6358364.9098634 -- meters for y absolut to center(homeposition)
	  hypdist =  math.sqrt( math.pow(math.abs(radarx),2) + math.pow(math.abs(radary),2) )

	  radTmp = math.rad( home.hdg )
	  radarxtmp = radarx * math.cos(radTmp) - radary * math.sin(radTmp)
	  radarytmp = radarx * math.sin(radTmp) + radary * math.cos(radTmp)

	  if math.abs(radarxtmp) >= math.abs(radarytmp) then --divtmp
	    for i = 13 ,1,-1 do
	      if math.abs(radarxtmp) >= upppp then
	        divtmp=divvv
	        break
	      end
	      divvv = divvv/2
	      upppp = upppp/2
	    end
	  else
	    for i = 13 ,1,-1 do
	      if math.abs(radarytmp) >= upppp then
	        divtmp=divvv
	        break
	      end
	      divvv = divvv/2
	      upppp = upppp/2
	    end
	  end
	  
	  upppp = 20480
	  divvv = 2048 --12 mal teilen
    
	  offsetX = radarxtmp / divtmp
	  offsetY = (radarytmp / divtmp)*-1
	end
	
	lcd.drawText(187,37,"o",0)
	lcd.drawRectangle(167, 19, 45, 45)
	for j=169, 209, 4 do
	  lcd.drawPoint(j, 19+22)
	end
	for j=21, 61, 4 do
	  lcd.drawPoint(167+22, j)
	end
	lcd.drawNumber(180, 57,hypdist, SMLSIZE)
	lcd.drawText(lcd.getLastPos(), 57, "m", SMLSIZE)
end


----------------------------------------------------------------------------------
--                                                                              --
----------------------------------------------------------------------------------


----------------------------------------------------------------------------------
--                                                                              --
----------------------------------------------------------------------------------



















----------------------------------------------------------------------------------
-- INIT FUNCTION                                                                --
----------------------------------------------------------------------------------
local function init()
	local i
	for i=1, 99 do
	  if FlightMode[i] == nil then
	    NumFlighModes = i-1
	  end
	end
end

----------------------------------------------------------------------------------
-- BACKGROUND FUNCTION                                                          --
----------------------------------------------------------------------------------
local function background()
	getTelemetry()
	doTelemetry()
	calcWattHs()
	playMaxWhReached()
end

----------------------------------------------------------------------------------
-- RUN FUNCTION                                                                 --
----------------------------------------------------------------------------------
local function run()
	lcd.clear()
	background()
	--
	toppanel()
	
	powerpanel()
	
	htsapanel()
	
	gpspanel()
	
	drawArrow()
	
	drawWhGauge()

end

----------------------------------------------------------------------------------
-- SCRIPT END                                                                   --
----------------------------------------------------------------------------------
--return {init=init, run=run, background=background}
return{run=run, background=background}
