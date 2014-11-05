
local inputs = { {"Crit., mV", VALUE,3000,3500,3400}, {"Use Horn", VALUE, 0, 3, 0}, {"Warn, mV", VALUE, 3100, 3800, 3500}, {"Rep, Sec", VALUE, 3, 30, 4},{"Drop, mV", VALUE, 1, 500, 100} }

local lastimeplaysound=0
local repeattime=400 -- 4 sekunden
local oldcellvoltage=4.2

local function init_func()
	lastimeplaysound=getTime()
end

-- Math Helper
local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function run_func(voltcritcal, horn, voltwarnlevel, repeattimeseconds, celldropmvolts)
	repeattime = repeattimeseconds*100
	local drop = celldropmvolts/10
	local hornfile=""
	if horn>0 then
		hornfile="SOUNDS/en/ALARM"..horn.."K.wav"
	end

	local newtime=getTime()
	if newtime-lastimeplaysound>=repeattime then
		local cellmin=getValue(214) + 0.0001 --- 214 = cell-min
		lastimeplaysound = newtime
		
		local firstitem = math.floor(cellmin)
		local miditem = math.floor((cellmin-firstitem) * 10)
		local lastitem = round((((cellmin-firstitem) * 10)-math.floor(((cellmin-firstitem) * 10))) *10)
	  
		if cellmin<=2.0 then --silent
		elseif cellmin<=voltcritcal/1000 then --critical
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
		elseif cellmin<=voltwarnlevel/1000 then --warnlevel
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
