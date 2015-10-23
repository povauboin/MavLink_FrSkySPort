--
-- offset.lua part of of MavLink_FrSkySPort
--		https://github.com/Clooney82/MavLink_FrSkySPort
--
-- Copyright (C) 2014 Michael Wolkstein
--	 https://github.com/Clooney82/MavLink_FrSkySPort
--
-- modified by
--	(c) 2015 Jochen Kielkopf
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
	{"O-SET mAh% ", VALUE,-100, 100,   0},
	{"O-SET Wh%",   VALUE,-100, 100,   0},
	{"BatCap Wh",   VALUE,   0, 250,  30}
--	{"BatCap mAh",  VALUE,   0,15000,2700}
	}

local oldoffsetmah=0
local oldoffsetwatth=0
local oldbatcapwh=0
--local oldbatcapmah=0
local used_flightmode=8

--local function run_func(offsetmah, offsetwatth, batcapwh, batcapmah)
local function run_func(offsetmah, offsetwatth, batcapwh)
	--if oldoffsetmah ~= offsetmah or oldoffsetwatth ~= offsetwatth or oldbatcapwh ~= batcapwh or oldbatcapmah ~= batcapmah then
	if oldoffsetmah ~= offsetmah or oldoffsetwatth ~= offsetwatth or oldbatcapwh ~= batcapwh then
	  --batcapmah = batcapmah / 100
	  model.setGlobalVariable(1, used_flightmode, offsetmah)   --mA/h
    model.setGlobalVariable(2, used_flightmode, offsetwatth) --Wh
    model.setGlobalVariable(3, used_flightmode, batcapwh)    --Wh
		--model.setGlobalVariable(4, used_flightmode, batcapmah)   --mAh
		--model.setGlobalVariable(4, used_flightmode, batcapmah/1000)   --mAh
		--model.setGlobalVariable(5, used_flightmode, batcapmah-(batcapmah/1000))   --mAh
	  oldoffsetmah   = offsetmah
	  oldoffsetwatth = offsetwatth
	  oldbatcapwh    = batcapwh
	  --oldbatcapmah   = oldbatcapmah
	end
end

return {run=run_func, input=inputs}
