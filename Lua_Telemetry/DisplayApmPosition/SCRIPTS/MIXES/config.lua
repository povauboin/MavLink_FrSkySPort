--
-- config.lua part of of MavLink_FrSkySPort
--		https://github.com/Clooney82/MavLink_FrSkySPort
--
-- Copyright (C) 2015 Jochen Kielkopf
--	 https://github.com/Clooney82/MavLink_FrSkySPort
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

local inputs = {
	{"play sound", VALUE,   0,   1,   1},
	{"timer beep", VALUE,   0,   1,   1},
	{"cellinfo", VALUE,   0,   1,   1}
	}

-- Used Flight Mode for storeing config variables of telem script
local used_flightmode = 8

local old_playsound = 9
local old_timerbeep = 9
local old_cellinfo = 9

local function run_func(playsound, timerbeep, cellinfo)
	-- Write GLOBAL VARIABLE into Flightmode
	-- used for config of telemetry script
	if old_playsound ~= playsound then
	  model.setGlobalVariable(0, used_flightmode, playsound)
	  old_playsound = playsound
	end
	if old_timerbeep ~= timerbeep then
	  model.setGlobalVariable(6, used_flightmode, timerbeep)
	  old_timerbeep = timerbeep
	end
	if old_cellinfo ~= cellinfo then
	  model.setGlobalVariable(7, used_flightmode, cellinfo)
	  old_cellinfo = cellinfo
	end
end


return {run=run_func, input=inputs}
