--
-- telem1.lua part of of MavLink_FrSkySPort
--		https://github.com/Clooney82/MavLink_FrSkySPort
--
-- Copyright (C) 2014 Luis Vale Gonçalves
--   https://github.com/lvale/MavLink_FrSkySPort
--
--  Improved by:
--    (2015) Michael Wolkstein
--   https://github.com/wolkstein/MavLink_FrSkySPort
--
--    (2015) Jochen Kielkopf
--    https://github.com/Clooney82/MavLink_FrSkySPort
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
--
--------------------------------------------------------------------------------
-- Date of last Change: 2015/09/22
-- Version: 0.40
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Do some init tasks - PLEASE DO NOT EDIT
--------------------------------------------------------------------------------
_directory = {}
Severity={}

--------------------------------------------------------------------------------
-- User configurable part
--------------------------------------------------------------------------------
-- Used Flight Mode for storeing config variables of telem script
local used_flightmode   = 8

-- Setup Language you want. possibilities: en, de
LANGUAGE = "en"

-- Setup Path of your Soundfiles and Images
_directory.sounds = "/SOUNDS/"..LANGUAGE.."/TELEM/"
_directory.pics   = "/SCRIPTS/BMP/"

-- Available FlightModes
FlightMode = {
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

--------------------------------------------------------------------------------
--            please do not edit below, unless you know what you do
--------------------------------------------------------------------------------
modelInfo = model.getInfo()
modelName = modelInfo.name

--------------------------------------------------------------------------------
-- Variables Definitions
--------------------------------------------------------------------------------

data = {}

home = {
	set  = 0,
	lat  = 0,
	lon  = 0,
	hdg  = 0,
	time = 0
	}

local apm_status_message = {severity = 0, textid = 0, timestamp = 0, last_played = 0}

local lastArmed   		 = 0
local last_flight_mode = 0
local SumFlightTime    = 0
local NumFlighModes 	 = 99

local localtime      	 = 0
local oldlocaltime   	 = 0
local localtimetwo   	 = 0
local oldlocaltimetwo	 = 0

local whconsumed			 = 0
local maxconsume			 = 0
local watthours				 = 0

local offsetX					 = 0
local offsetY					 = 0

local arrowLine = {
		{-4, 5, 0, -4},
		{-3, 5, 0, -3},
		{3, 5, 0, -3},
		{4, 5, 0, -4}
		}

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- Play sounds function
--------------------------------------------------------------------------------
local function playSound(sType, sValue, sValue2)
	if model.getGlobalVariable(0, used_flightmode) == 1 then
	  if sType == "txt" then
	    if sValue == "armed" then
	      playFile(_directory.sounds.."SARM.wav")
	    elseif sValue == "disarmed" then
	      playFile(_directory.sounds.."SDISAR.wav")
	    elseif sValue == "maxWhReached" then
	      playFile(_directory.sounds.."ALARM3K.wav")
	    end
	  elseif sType == "FM" then
	    playFile(_directory.sounds.."AVFM"..sValue.."A.wav") -- old: AVFM"..(FmodeNr-1).."A.wav
	  elseif sType == "APM_STATUS" then
	    playFile(_directory.sounds.."SEV"..sValue..".wav")
	    playFile(_directory.sounds.."MSG"..sValue2..".wav") -- old: MSG"..apm_status_message.textnr..".wav
	  end
	end
end

--------------------------------------------------------------------------------
-- Get Telemetry data functions
--------------------------------------------------------------------------------
local function getTelemetry()

	local tmp = 0
	local gpsLatLon = {}
	local i = 0
	local cells = {}

	--local data = {}

	-- RPM Sensor Values
	data.t1          = getValue("T1")			-- (ap_sat_visible * 10) + ap_fixtype
	data.t2          = getValue("T2")			-- Armed Status + Severity + Statustext
	--data.rpm         = getValue("RPM")			-- ap_throttle * 200+ap_battery_remaining*2		-- currently not used

	-- FAS Sensor Values
	data.vfas        = getValue("VFAS")			-- Batt Voltage
	data.curr        = getValue("Curr")			-- Current (mA)

	-- FLVSS Sensor Values
	data.cells       = getValue("Cels")			-- Cells Voltage
	if (type(data.cells) == "table") then
		data.cmin = 10
		for index,value in pairs(data.cells) do
			if value < data.cmin then
				data.cmin = value
			end
			if value < data.cmin_min then
				data.cmin_min = value
			end
			--data.cells_num = index
		end
	end
	--data.c1          = getValue("Z1")			-- 1. Cell											 -- not needed anymore
	--data.c2          = getValue("Z2")			-- 2. Cell											 -- not needed anymore
	--data.c3          = getValue("Z3")			-- 3. Cell											 -- not needed anymore
	--data.c4          = getValue("Z4")			-- 4. Cell											 -- not needed anymore
	--data.c5          = getValue("Z5")			-- 5. Cell											 -- not needed anymore
	--data.c6          = getValue("Z6")			-- 6. Cell											 -- not needed anymore
	--data.c7          = getValue("Z7")			-- 7. Cell											 -- not needed anymore
	--data.c8          = getValue("Z8")			-- 8. Cell											 -- not needed anymore
	--data.cmin        = getValue("Cmin")		-- lowest current Cell Voltage	 -- not needed anymore
	--data.cmin_min    = getValue("Cmin-")	-- lowest Cell Voltage					 -- not needed anymore

	-- Consumtion Values
	data.mah         = getValue("mAh")			-- mAh
	data.watt        = getValue("Watt")			-- Watts

	-- GPS Sensor Values
	-- opentx2.1.3 lua support for latitude and longitude
	-- added on opentx commit c0dee366c0ae3f9776b3ba305cc3eb6bdeec593a
	gpsLatLon        = getValue("GPS")			-- GPS Data
	if (type(gpsLatLon) == "table") then
	  if gpsLatLon["lat"] ~= NIL then
	    data.lat = gpsLatLon["lat"]
	  end
	  if gpsLatLon["lon"] ~= NIL then
	    data.lon = gpsLatLon["lon"]
	  end
	end

	data.gps_heading = getValue("Hdg")			-- current heading
	data.gps_speed   = getValue("GSpd")			-- GPS Speed (m/s)
	--data.gps_alt     = getValue("GAlt")			-- GPS Alt						-- currently not used
	--data.gps_altmax  = getValue("GAltM")			-- max. Alt					-- currently not used
	--data.gps_altmax  = getValue("GAlt+")			-- max. GPS Alt			-- currently not used
	--data.distance    = getValue("distance")			-- GPS distance		-- not used
	data.hdop        = getValue("A2")/10			-- HDOP


	-- Angle Values
	--data.roll        = getValue("A3")			-- ap_roll_angle  + 180	-- currently not used
	--data.pitch       = getValue("A4")			-- ap_pitch_angle + 180	-- currently not used

	-- Vario Sensor Values
	data.alt         = getValue("Alt")			-- ap_bar_altitude
	--data.altmax      = getValue("AltM")			-- max altitude				-- currently not used
	data.altmax      = getValue("Alt+")			-- max altitude
	data.vario       = getValue("VSpd")			-- ap_climb_rate

	-- acceleration Sensor Values
	--data.accx        = getValue("AccX")			-- AccX g							-- currently not used
	--data.accy        = getValue("AccY")			-- AccY g							-- currently not used
	--data.accz        = getValue("AccZ")			-- AccZ g							-- currently not used

	-- Fuel Sensor Values
	data.FMod        = getValue("Fuel")			-- Flightmode

	-- Other Sensor Values
	data.rssi        = getValue("RSSI")			-- RSSI
	--data.rxbt        = getValue("RxVt")			-- RxBt								-- currently not used
	--data.swr         = getValue("SWR")			-- SWR								-- currently not used
	data.txbt        = getValue(189)			-- TX-Voltage

	--------------------------------------------------------------------------------
	-- combined values from teensy script
	--------------------------------------------------------------------------------

	data.fixtype     = data.t1%10				-- Number of Sats
	data.sats        = (data.t1 - data.fixtype)/10		-- 0 = no GPS, 1 = no Fix, 2 = 2D Fix, 3 = 3D Fix

	data.armed       = 0
	data.armed       = data.t2%0x02				-- 0 = disarmed, 1 = armed
	tmp = (data.t2 - data.armed)/0x02
	data.severity    = tmp%0x10				-- Severity
	tmp = (tmp - data.severity)/0x10
	data.textid      = tmp%0x400				-- Text ID

	--data.throttle    = data.rpm%200				-- Throttle in percent (0 = 0, 100, 100)							-- currently not used
	--data.battremain  = (data.rpm - data.throttle)/2		-- Remaining Bat. capacitiy in percent		-- currently not used


	--return data
	return 0
end

--------------------------------------------------------------------------------
-- Telemetry background tasks
--------------------------------------------------------------------------------
local function doTelemetry()
	local number_cells =  0				-- Cellcount. Used if no single cell voltage available

	if lastArmed ~= data.armed then
	  if data.armed == 1 then
	    if data.fixtype >= 3 then
	      home.set  = 1
	      home.lat  = data.lat
	      home.lon = data.lon
	      home.hdg  = data.gps_heading
	      home.time = getTime()
	    end
			if model.getGlobalVariable(6, used_flightmode) == 1 then
				model.setTimer(0,{ mode=1, start=0, value=SumFlightTime, countdownBeep=0, minuteBeep=true, persistent=1 })
			else
				model.setTimer(0,{ mode=1, start=0, value=SumFlightTime, countdownBeep=0, minuteBeep=false, persistent=1 })
			end
	    model.setTimer(1,{ mode=1, start=0, value=PersitentSumFlight, countdownBeep=0, minuteBeep=false, persistent=2 })
			playSound("txt", "armed", "")
	  else
	    SumFlightTime = model.getTimer(0).value
			if model.getGlobalVariable(6, used_flightmode) == 1 then
				model.setTimer(0,{ mode=0, start=0, value=model.getTimer(0).value, countdownBeep=0, minuteBeep=true, persistent=1 })
			else
				model.setTimer(0,{ mode=0, start=0, value=model.getTimer(0).value, countdownBeep=0, minuteBeep=false, persistent=1 })
			end
	    model.setTimer(1,{ mode=0, start=0, value=model.getTimer(1).value, countdownBeep=0, minuteBeep=false, persistent=2 })
			playSound("txt", "disarmed", "")
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
		playSound("FM", data.FMod, "")
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

	if apm_status_message.textid >0 then
	  if apm_status_message.last_played ~= apm_status_message.textid then
			playSound("APM_STATUS", apm_status_message.severity, apm_status_message.textid)
	    apm_status_message.last_played = apm_status_message.textid
	  end
	end
end

--------------------------------------------------------------------------------
-- play alarm wh reach maximum level
--------------------------------------------------------------------------------
local function playMaxWhReached()
	if maxconsume > 0 and (watthours  + ( watthours * ( model.getGlobalVariable(2, used_flightmode)/100) ) ) >= maxconsume then
	  localtimetwo = localtimetwo + (getTime() - oldlocaltimetwo)
	  if localtimetwo >=800 then --8s
			playSound("txt", "maxWhReached", "")
	    localtimetwo = 0
	  end
	  oldlocaltimetwo = getTime()
	end
end

--------------------------------------------------------------------------------
-- Round helper function
--------------------------------------------------------------------------------
local function round(num, idp)
	local mult
	mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

--------------------------------------------------------------------------------
-- Calculate watthours
--------------------------------------------------------------------------------
local function calcWattHs()
	localtime = localtime + (getTime() - oldlocaltime)
	if localtime >=10 then --100 ms
	  watthours = watthours + ( getValue("Watt") * (localtime/360000) )
	  localtime = 0
	end
	oldlocaltime = getTime()
	maxconsume = model.getGlobalVariable(3, used_flightmode)
end

--------------------------------------------------------------------------------
-- Draw Top Panel
--------------------------------------------------------------------------------
function toppanel()
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

--------------------------------------------------------------------------------
-- draw arrow
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- draw Wh Gauge
--------------------------------------------------------------------------------
local function drawWhGauge()
	whconsumed = watthours + ( watthours * ( model.getGlobalVariable(2, used_flightmode)/100) )
	if whconsumed >= maxconsume then
	  whconsumed = maxconsume
	end
	lcd.drawFilledRectangle(74,9,11,55,INVERS)
	lcd.drawFilledRectangle(75,9,9, (whconsumed - 0)* ( 55 - 0 ) / (maxconsume - 0) + 0, 0)

end

--------------------------------------------------------------------------------
-- Power Panel
--------------------------------------------------------------------------------
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

	lcd.drawNumber(1,33,consumption + ( consumption * ( model.getGlobalVariable(1, used_flightmode)/100 ) ),MIDSIZE+LEFT)
	xposCons=lcd.getLastPos()
	lcd.drawText(xposCons,32,"m",SMLSIZE)
	lcd.drawText(xposCons,38,"Ah",SMLSIZE)

	lcd.drawNumber(67,33,( watthours + ( watthours  * ( model.getGlobalVariable(2, used_flightmode)/100) ) ) ,MIDSIZE+PREC1)
	xposCons=lcd.getLastPos()
	lcd.drawText(xposCons,32,"w",SMLSIZE)
	lcd.drawText(xposCons,38,"h",SMLSIZE)

	lcd.drawNumber(42,47,data.cmin,DBLSIZE+PREC2)
	xposCons=lcd.getLastPos()
	lcd.drawText(xposCons,48,"V",SMLSIZE)
	lcd.drawText(xposCons,56,"C-min",SMLSIZE)

end

--------------------------------------------------------------------------------
-- Altitude Panel
--------------------------------------------------------------------------------
local function htsapanel()

	local htsapaneloffset = 11

	lcd.drawLine (htsapaneloffset + 154, 8, htsapaneloffset + 154, 63, SOLID, 0)
	--heading
	lcd.drawText(htsapaneloffset + 76,11,"Heading ",SMLSIZE)
	lcd.drawNumber(lcd.getLastPos(),9,data.gps_heading,MIDSIZE+LEFT)
	lcd.drawText(lcd.getLastPos(),9,"\64",MIDSIZE)

	--altitude
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

	--Alt max
	lcd.drawText(htsapaneloffset + 76,35,"Max",SMLSIZE)
	lcd.drawNumber(lcd.getLastPos()+8,35,data.altmax,SMLSIZE+LEFT)
	lcd.drawText(lcd.getLastPos(),35,"m",SMLSIZE)

	--Armed time
	lcd.drawTimer(htsapaneloffset + 83,42,model.getTimer(0).value,MIDSIZE)

	--Model Runtime
	lcd.drawNumber(lcd.getLastPos()+8,45,model.getTimer(1).value/3600.0,SMLSIZE+LEFT+PREC1)
	lcd.drawText(lcd.getLastPos()+3,45,"h",SMLSIZE)

	lcd.drawText(htsapaneloffset + 76,56,"Speed",SMLSIZE)
	lcd.drawNumber(lcd.getLastPos()+8, 53,data.gps_speed,MIDSIZE+LEFT)

end

--------------------------------------------------------------------------------
-- GPS Panel
--------------------------------------------------------------------------------
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
	elseif data.fixtype > 1 then
	  lcd.drawText (168, 10, "2D", 0)
	  lcd.drawNumber (195, 10, data.sats, 0+LEFT )
	  lcd.drawText (lcd.getLastPos(), 10, "S", 0)
	else
	  lcd.drawText (168, 10, "NO", 0+BLINK+INVERS)
	  lcd.drawText (195, 10, "--S",0)
	end

	if data.hdop < 20 then
	  lcd.drawNumber (180, 10, data.hdop, PREC1+LEFT+SMLSIZE )
	else
	  lcd.drawNumber (180, 10, data.hdop, PREC1+LEFT+BLINK+INVERS+SMLSIZE)
	end

	if home.lat~=0 and data.lat~=0 and home.lon~=0 and data.lon~=0 then
	  z1 = math.sin(data.lon - home.lon) * math.cos(data.lat)
	  z2 = math.cos(home.lat) * math.sin(data.lat) - math.sin(home.lat) * math.cos(data.lat) * math.cos(data.lon - home.lon)

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
	lcd.drawNumber(189, 57,hypdist, SMLSIZE)
	lcd.drawText(lcd.getLastPos(), 57, "m", SMLSIZE)
end

--------------------------------------------------------------------------------
-- INIT FUNCTION
--------------------------------------------------------------------------------
local function init()
	local i
	for i=1, 99 do
	  if FlightMode[i] == nil then
	    NumFlighModes = i-1
	  end
	end

	data.cmin = 10
	data.cmin_min = data.cmin

	if model.getGlobalVariable(6, used_flightmode) == 1 then
		model.setTimer(0,{ mode=0, start=0, value=0, countdownBeep=0, minuteBeep=true, persistent=1 })
	else
		model.setTimer(0,{ mode=0, start=0, value=0, countdownBeep=0, minuteBeep=false, persistent=1 })
	end

end

--------------------------------------------------------------------------------
-- BACKGROUND FUNCTION
--------------------------------------------------------------------------------
local function background()
	getTelemetry()
	doTelemetry()
	calcWattHs()
	playMaxWhReached()
end

--------------------------------------------------------------------------------
-- RUN FUNCTION
--------------------------------------------------------------------------------
local function run()

	lcd.clear()

	background()

	toppanel()

	powerpanel()

	htsapanel()

	gpspanel()

	drawArrow()

	drawWhGauge()

end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {init=init, run=run, background=background}
