--
-- config lua
--
-- Copyright (C) 2014 Michael Wolkstein
--
-- https://github.com/Clooney82/MavLink_FrSkySPort
--
-- (2015) Improved by:
--        Jochen Kielkopf
--        https://github.com/Clooney82/MavLink_FrSkySPort
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
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
--

local inputs = {
	{"play sounds", VALUE,   0,   1,   1},
	{"Warn,V/100",  VALUE, 310, 380, 350},
	{"Crit,V/100",  VALUE, 300, 350, 340},
	{"Use Horn",    VALUE,   0,   3,   0},
	{"Rep, Sec",    VALUE,   3,  40,   4},
	{"Drop, mV",    VALUE,   1, 500, 100}
	}

-- Used Flight Mode for storeing config variables of telem script
local used_flightmode   = 8

local old_playsound     = 9

local lasttimeplaysound = 0
local repeattime        = 400
local drop              = 0
local hornfile          = ""
local cellmin           = 0

local first_item        = 0
local mid_item          = 0
local last_item         = 0

local mult              = 0
local newtime           = 0

-- Math Helper
local function round(num, idp)
	mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end


local function init_func()
	lasttimeplaysound = getTime()
end


local function run_func(playsound, voltwarnlevel, voltcritcal, horn, repeattimeseconds, celldropmvolts)
	-- Write GLOBAL VARIABLE into Flightmode
	-- used for config of telemetry script
	if old_playsound ~= playsound then
	  model.setGlobalVariable(0, used_flightmode, playsound)
	  old_playsound = playsound
	end

	-- Script Part
	repeattime = repeattimeseconds*100
	drop = celldropmvolts/10
	if horn > 0 then
		hornfile="/SOUNDS/en/ALARM"..horn.."K.wav"
	end

	newtime=getTime()
	if newtime-lasttimeplaysound>=repeattime then
	  cellmin=getValue("Cmin") + 0.0001 --- 214 = cell-min
	  lasttimeplaysound = newtime

	  firstitem = math.floor(cellmin)
	  miditem = math.floor((cellmin-firstitem) * 10)
	  lastitem = round((((cellmin-firstitem) * 10)-math.floor(((cellmin-firstitem) * 10))) *10)

	  if cellmin<=2.0 then --silent
	  elseif cellmin<=voltcritcal/100 then --critical
	    if horn>0 then
	      playFile(hornfile)
	      playFile("/SOUNDS/en/CRICMK.wav")
	    else
	      playFile("/SOUNDS/en/CRICM.wav")
	    end
	    playNumber(firstitem, 0, 0)
	    playFile("/SOUNDS/en/POINT.wav")
	    playNumber(miditem, 0, 0)
	    if lastitem ~= 0 then
	      playNumber(lastitem, 0, 0)
	    end
	  elseif cellmin<=voltwarnlevel/100 then --warnlevel
	    playFile("/SOUNDS/en/WARNCM.wav")
	    playNumber(firstitem, 0, 0)
	    playFile("/SOUNDS/en/POINT.wav")
	    playNumber(miditem, 0, 0)
	    if lastitem ~= 0 then
	      playNumber(lastitem, 0, 0)
	    end
	  elseif cellmin<=4.2 then --info level
	    if oldcellvoltage < cellmin then -- temp cell drop during aggressive flight
	      oldcellvoltage = cellmin
	    end
	    if oldcellvoltage*100 - cellmin*100 >= drop then
	      playFile("/SOUNDS/en/CELLMIN.wav")
	      playNumber(firstitem, 0, 0)
	      playFile("/SOUNDS/en/POINT.wav")
	      playNumber(miditem, 0, 0)
	      if lastitem ~= 0 then
	        playNumber(lastitem, 0, 0)
	      end
	      oldcellvoltage = cellmin
	    end
	  end
	end
end


return {run=run_func, init=init_func, input=inputs}
