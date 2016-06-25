--
-- coptr217 lua
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
--    Fixes for 2.1.7 compatibility (2016) Paul Atherton
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
-- Auxiliary files on github under dir BMP and SOUNDS/en
-- https://github.com/Clooney82/MavLink_FrSkySPort/tree/s-c-l-v-rc-opentx2.1/Lua_Telemetry/DisplayApmPosition
--

--Init Variables
local SumFlight = 0
local lastarmed = 0
local apmarmed = 0
local FmodeNr = 13 -- This is an invalid flight number when no data available
local last_flight_mode = 1
local last_apm_message_played = 0
local mult = 0
local consumption = 0
local vspd = 0
local xposCons = 0
local t2 = 0
local prearmheading = 0
local radarx = 0
local radary = 0
local radarxtmp = 0
local radarytmp = 0
local hdop = 0
local watthours = 0
local lastconsumption = 0
local localtime = 0
local oldlocaltime= 0
local localtimetwo = 0
local oldlocaltimetwo= 0
local pilotlat = 0
local pilotlon = 0
local curlat = 0
local curlon = 0
local telem_sats = 0
local telem_lock = 0
local telem_t1 = 0
local status_severity = 0
local status_textnr = 0
local hypdist = 0
local battWhmax = 0
local maxconsume = 0
local whconsumed = 0
local batteryreachmaxWH = 0

-- Temporary text attribute
local FORCE = 0x02 -- draw ??? line or rectangle
local X1 = 0
local Y1 = 0
local X2 = 0
local Y2 = 0
local sinCorr = 0
local cosCorr = 0
local radTmp = 0
local CenterXcolArrow = 189
local CenterYrowArrow = 41
local offsetX = 0
local offsetY = 0
local htsapaneloffset = 11
local divtmp = 1
local upppp = 20480
local divvv = 2048 --12 mal teilen

-- gps
local gpsLatLon = {}
local LocationLat = 0
local LocationLon = 0

--Timer 0 is time while vehicle is armed
model.setTimer(0, {mode=0, start=0, value=0, countdownBeep=0, minuteBeep=true, persistent=1})

--Timer 1 is accumulated time per flight mode
--model.setTimer(1, {mode=0, start=0, value=0, countdownBeep=0, minuteBeep=false, persistent=1})

--Init Flight Tables
local FlightMode = {
    "Stabilize",
    "Acro",
    "Altitude Hold",
    "Auto",
    "Guided",
    "Loiter",
    "Return to launch",
    "Circle",
    "Invalid Mode",
    "Land",
    "Optical Loiter",
    "Drift",
    "Invalid Mode",
    "Sport",
    "Flip Mode",
    "Auto Tune",
    "Position Hold",
    "Brake"
}

local apm_status_message = {severity = 0, textnr = 0, timestamp=0}

local arrowLine = {
    {-4, 5, 0, -4},
    {-3, 5, 0, -3},
    {3, 5, 0, -3},
    {4, 5, 0, -4}
}

-- Telemetry helper function
local function getTelemetryId(name)
    field = getFieldInfo(name)
    if field then
        return field.id
    else
        return -1
    end
end

-- draw arrow
local function drawArrow()
    sinCorr = math.sin(math.rad(getValue("Hdg")-prearmheading))
    cosCorr = math.cos(math.rad(getValue("Hdg")-prearmheading))
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

-- draw Wh Gauge
local function drawWhGauge()
    whconsumed = watthours + ( watthours * ( model.getGlobalVariable(8, 1)/100) )
    if whconsumed >= maxconsume then
        whconsumed = maxconsume
    end
    lcd.drawFilledRectangle(74,9,11,55,INVERS)
    lcd.drawFilledRectangle(75,9,9, (whconsumed - 0)* ( 55 - 0 ) / (maxconsume - 0) + 0, 0)
end

--Aux Display functions and panels
local function round(num, idp)
    mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- GPS Panel
local function gpspanel()
    telem_t1 = getValue("T1") -- Temp1
    telem_lock = 0
    telem_sats = 0
    telem_lock = telem_t1%10
    telem_sats = (telem_t1 - (telem_t1%10))/10
    if telem_lock >= 3 then
        lcd.drawText (168, 10, "3D",0)
        lcd.drawNumber (195, 10, telem_sats, 0+LEFT)
        lcd.drawText (lcd.getLastPos(), 10, "S", 0)
    elseif telem_lock>1 then
        lcd.drawText (168, 10, "2D", 0)
        lcd.drawNumber (195, 10, telem_sats, 0+LEFT )
        lcd.drawText (lcd.getLastPos(), 10, "S", 0)
    else
        lcd.drawText (168, 10, "NO", 0+BLINK+INVERS)
        lcd.drawText (195, 10, "--S",0)
    end
    hdop=round(getValue("A2"))/10
    if hdop <2.5 then
        lcd.drawNumber (180, 10, hdop*10, PREC1+LEFT+SMLSIZE )
    else
        lcd.drawNumber (180, 10, hdop*10, PREC1+LEFT+BLINK+INVERS+SMLSIZE)
    end
    curlat = math.rad(LocationLat)
    curlon = math.rad(LocationLon)
    if pilotlat~=0 and curlat~=0 and pilotlon~=0 and curlon~=0 then
        z1 = math.sin(curlon - pilotlon) * math.cos(curlat)
        z2 = math.cos(pilotlat) * math.sin(curlat) - math.sin(pilotlat) * math.cos(curlat) * math.cos(curlon - pilotlon)
        -- use prearmheading later to rotate cordinates relative to copter.
        radarx=z1*6358364.9098634 -- meters for x absolut to center(homeposition)
        radary=z2*6358364.9098634 -- meters for y absolut to center(homeposition)
        hypdist =  math.sqrt( math.pow(math.abs(radarx),2) + math.pow(math.abs(radary),2) )
        radTmp = math.rad( prearmheading )
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

-- Altitude Panel
local function htsapanel()
    lcd.drawLine (htsapaneloffset + 154, 8, htsapaneloffset + 154, 63, SOLID, 0)
    --heading
    lcd.drawText(htsapaneloffset + 76,11,"Heading ",SMLSIZE)
    lcd.drawNumber(lcd.getLastPos(),9,getValue("Hdg"),MIDSIZE+LEFT)
    lcd.drawText(lcd.getLastPos(),9,"\64",MIDSIZE)
    --altitude
    --Alt max
    lcd.drawText(htsapaneloffset + 76,25,"Alt ",SMLSIZE)
    lcd.drawNumber(lcd.getLastPos()+3,22,getValue("Alt"),MIDSIZE+LEFT)
    lcd.drawText(lcd.getLastPos(),22,"m",MIDSIZE)
    --vspeed
    vspd= getValue("VSpd")
    if vspd == 0 then
        lcd.drawText(lcd.getLastPos(), 25,"==",0)
    elseif vspd >0 then
        lcd.drawText(lcd.getLastPos(), 25,"++",0)
    elseif vspd <0 then
        lcd.drawText(lcd.getLastPos(), 25,"-",0)
    end
    lcd.drawNumber(lcd.getLastPos(),25,vspd,0+LEFT)
    lcd.drawText(htsapaneloffset + 76,35,"Max",SMLSIZE)
    lcd.drawNumber(lcd.getLastPos()+8,35,getValue("AltM"),SMLSIZE+LEFT)
    lcd.drawText(lcd.getLastPos(),35,"m",SMLSIZE)
    --Armed time
    lcd.drawTimer(htsapaneloffset + 83,42,model.getTimer(0).value,MIDSIZE)
    --Model Runtime
    lcd.drawNumber(lcd.getLastPos()+8,45,model.getTimer(1).value/360,SMLSIZE+LEFT+PREC1)
    lcd.drawText(lcd.getLastPos()+3,45,"h",SMLSIZE)
    lcd.drawText(htsapaneloffset + 76,56,"Speed",SMLSIZE)
    lcd.drawNumber(lcd.getLastPos()+8, 53,getValue("GSpd")*3.6,MIDSIZE+LEFT)
end

-- Top Panel
local function toppanel()
    lcd.drawFilledRectangle(0, 0, 212, 9, 0)
    if apmarmed==1 then
        lcd.drawText(1, 0, (FlightMode[FmodeNr]), INVERS)
    else
        lcd.drawText(1, 0, (FlightMode[FmodeNr]), INVERS+BLINK)
    end
    lcd.drawText(134, 0, "TX:", INVERS)
    lcd.drawNumber(160, 0, getValue(189)*10,0+PREC1+INVERS)
    lcd.drawText(lcd.getLastPos(), 0, "v", INVERS)
    lcd.drawText(172, 0, "rssi:", INVERS)
    lcd.drawNumber(lcd.getLastPos()+10, 0, getValue("RSSI"),0+INVERS)
end

--Power Panel
local function powerpanel()
    consumption=getValue("mAh")---

    lcd.drawNumber(30,13,getValue("VFAS")*10,DBLSIZE+PREC1)
    lcd.drawText(lcd.getLastPos(),14,"V",0)

    lcd.drawNumber(67,9,getValue("Curr")*10,MIDSIZE+PREC1)
    lcd.drawText(lcd.getLastPos(),10,"A",0)

    lcd.drawNumber(67,21,getValue("Watt"),MIDSIZE)
    lcd.drawText(lcd.getLastPos(),22,"W",0)

    lcd.drawNumber(1,33,consumption + ( consumption * ( model.getGlobalVariable(8, 0)/100 ) ),MIDSIZE+LEFT)
    xposCons=lcd.getLastPos()
    lcd.drawText(xposCons,32,"m",SMLSIZE)
    lcd.drawText(xposCons,38,"Ah",SMLSIZE)

    lcd.drawNumber(67,33,( watthours + ( watthours * ( model.getGlobalVariable(8, 1)/100) ) )*10,MIDSIZE+PREC1)
    xposCons=lcd.getLastPos()
    lcd.drawText(xposCons,32,"w",SMLSIZE)
    lcd.drawText(xposCons,38,"h",SMLSIZE)

    lcd.drawNumber(42,47,getValue("Cmin")*100,DBLSIZE+PREC2)
    xposCons=lcd.getLastPos()
    lcd.drawText(xposCons,48,"V",SMLSIZE)
    lcd.drawText(xposCons,56,"C-min",SMLSIZE)
end

-- Calculate watthours
local function calcWattHs()
    localtime = localtime + (getTime() - oldlocaltime)
    if localtime >=10 then --100 ms
        watthours = watthours + ( getValue("Watt") * (localtime/360000) )
        localtime = 0
    end
    oldlocaltime = getTime()
    maxconsume = model.getGlobalVariable(8, 2)
end

--APM Armed and errors
local function armed_status()
    t2 = getValue("T2")
    apmarmed = t2%0x02
    -- opentx2.1.3 lua support for latitude and longitude
    -- added on opentx commit c0dee366c0ae3f9776b3ba305cc3eb6bdeec593a
    gpsLatLon = getValue("GPS")
    if (type(gpsLatLon) == "table") then
        if gpsLatLon["lat"] ~= NIL then
            LocationLat = gpsLatLon["lat"]
        end
        if gpsLatLon["lon"] ~= NIL then
            LocationLon = gpsLatLon["lon"]
        end
    end
    if apmarmed ~=1 then -- report last heading bevor arming. this can used for display position relative to copter
        prearmheading=getValue("Hdg")
        pilotlat = math.rad(LocationLat)
        pilotlon = math.rad(LocationLon)
    end
    if lastarmed~=apmarmed then
        lastarmed=apmarmed
        if apmarmed==1 then
            model.setTimer(0,{ mode=1, start=0, value=SumFlight, countdownBeep=0, minuteBeep=true, persistent=1 })
            model.setTimer(1,{ mode=1, start=0, value=PersitentSumFlight, countdownBeep=0, minuteBeep=false, persistent=2 })
            playFile("/SOUNDS/en/TELEM/SARM.wav")
            playFile("/SOUNDS/en/TELEM/AVFM"..(FmodeNr-1).."A.wav")
        else
            SumFlight = model.getTimer(0).value
            model.setTimer(0,{ mode=0, start=0, value=model.getTimer(0).value, countdownBeep=0, minuteBeep=true, persistent=1 })
            model.setTimer(1,{ mode=0, start=0, value=model.getTimer(1).value, countdownBeep=0, minuteBeep=false, persistent=2 })
            playFile("/SOUNDS/en/TELEM/SDISAR.wav")
        end
    end
    t2 = (t2-apmarmed)/0x02
    status_severity = t2%0x10
    t2 = (t2-status_severity)/0x10
    status_textnr = t2%0x400
    if(status_severity > 0) then
        if status_severity ~= apm_status_message.severity or status_textnr ~= apm_status_message.textnr then
            apm_status_message.severity = status_severity
            apm_status_message.textnr = status_textnr
            apm_status_message.timestamp = getTime()
        end
    end
    if apm_status_message.timestamp > 0 and (apm_status_message.timestamp + 2*100) < getTime() then
        apm_status_message.severity = 0
        apm_status_message.textnr = 0
        apm_status_message.timestamp = 0
        last_apm_message_played = 0
    end
    -- play sound
    if apm_status_message.textnr >0 then
        if last_apm_message_played ~= apm_status_message.textnr then
            playFile("/SOUNDS/en/TELEM/MSG"..apm_status_message.textnr..".wav")
            last_apm_message_played = apm_status_message.textnr
        end
    end
end

--FlightModes
local function Flight_modes()
    FmodeNr = getValue("Fuel")+1
    if FmodeNr<1 or FmodeNr>18 then
        FmodeNr=13
    end
    if FmodeNr~=last_flight_mode then
        playFile("/SOUNDS/en/TELEM/AVFM"..(FmodeNr-1).."A.wav")
        last_flight_mode=FmodeNr
    end
end

-- play alarm wh reach maximum level
local function playMaxWhReached()
    if maxconsume > 0 and (watthours  + ( watthours * ( model.getGlobalVariable(8, 1)/100) ) ) >= maxconsume then
        localtimetwo = localtimetwo + (getTime() - oldlocaltimetwo)
        if localtimetwo >=800 then --8s
            playFile("/SOUNDS/en/TELEM/ALARM3K.wav")
            localtimetwo = 0
        end
        oldlocaltimetwo = getTime()
    end
end

--Init
local function init()
end

--Background
local function background()
    armed_status()
    Flight_modes()
    calcWattHs()
    playMaxWhReached()
end

--Main
local function run(event)
    lcd.clear()
    background()
    toppanel()
    powerpanel()
    htsapanel()
    gpspanel()
    drawArrow()
    drawWhGauge()
end

return {init=init, run=run, background=background}
