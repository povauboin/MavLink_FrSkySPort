-- Copyright Luis Vale Gonçalves.
-- 	  This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    A copy of the GNU General Public License is available at <http://www.gnu.org/licenses/>.
--    

--Auxiliary files on github under dir BMP and SOUNDS/en
-- https://github.com/lvale/MavLink_FrSkySPort/tree/DisplayAPMPosition/Lua_Telemetry/DisplayApmPosition

--------------------------------------
--This file is modified by wolkstein--
--------------------------------------


--Init Variables
	local eff=0
	local consumption_max=0
	local cell_nr=0
	local cellv=0
	local cap_est=0
	local battremaining=1
	local zerobattery=0
	local zerocap=1
	local SumFlight=0
	local repeatplay=0
	local SwitchFlag=0
	local lastarmed=0
	local apmarmed=0
	local LastSwitchPos=0
	local SwitchPos=0
	local FmodeNr=13 -- This is an invalid flight number when no data available
	local Engaged=0
	local last_flight_mode = 0
	local last_flight_mode_play = 0
	local last_apm_message_played = 0
	local vh1, vy1, mult, rangle, rx2, rx1, ry1, ry2
	local power, battremaining, throttle, tension, current, consumption
 	local watts, tension_min, current_max, watts_max, cellmin, xposCons, xposConsCell
	local t2, nameofsndfile, prearmheading, radarx, radary, radarxtmp,radarytmp 
	

	-- Temporary text attribute
	local FORCE = 0x02 -- draw ??? line or rectangle
	local X1, Y1, X2, Y2
	local sinCorr, cosCorr, radTmp
	local CenterXcolArrow = 189
	local CenterYrowArrow = 41
	local offsetX = 0
	local offsetY = 0
	local divtmp = 1
	local upppp = 20480
	local divvv = 2048 --12 mal teilen

	
	--Timer 0 is time while vehicle is armed
	
	model.setTimer(0, {mode=0, start=0, value= 0, countdownBeep=0, minuteBeep=1, persistent=1})
	
	--Timer 1 is accumulated time per flight mode
	
	model.setTimer(1, {mode=0, start=0, value= 0, countdownBeep=0, minuteBeep=0, persistent=1})

--Init Flight Tables
	FlightMode = {}
	for i=1, 17 do
	  FlightMode[i] = {}
	  FlightMode[i].Name=""
	  FlightMode[i].SoundActive1="/SOUNDS/en/AVFM"..(i-1).."A.wav"
	  FlightMode[i].SoundActive2="/SOUNDS/en/ALFM"..(i-1).."A.wav"
	  FlightMode[i].Repeat=1
	  FlightMode[i].Timer=0	  
	end
	
	FlightMode[1].Name="Stabilize"
	FlightMode[1].Repeat=300
	FlightMode[2].Name="Acro"
	FlightMode[2].Repeat=300
	FlightMode[3].Name="Altitude Hold"
	FlightMode[3].Repeat=300
	FlightMode[4].Name="Auto"
	FlightMode[4].Repeat=60
	FlightMode[5].Name="Guided"
	FlightMode[5].Repeat=60
	FlightMode[6].Name="Loiter"
	FlightMode[6].Repeat=300
	FlightMode[7].Name="Return to launch"
	FlightMode[7].Repeat=15
	FlightMode[8].Name="Circle"
	FlightMode[8].Repeat=300
	FlightMode[9].Name="Invalid Mode"
	FlightMode[9].Repeat=15
	FlightMode[10].Name="Land"
	FlightMode[10].Repeat=15
	FlightMode[11].Name="Optical Loiter"
	FlightMode[11].Repeat=300
	FlightMode[12].Name="Drift"
	FlightMode[12].Repeat=300
	FlightMode[13].Name="Invalid Mode"
	FlightMode[13].Repeat=15
	FlightMode[14].Name="Sport"
	FlightMode[14].Repeat=60
	FlightMode[15].Name="Flip Mode"
	FlightMode[15].Repeat=15
	FlightMode[16].Name="Auto Tune"
	FlightMode[16].Repeat=30
	FlightMode[17].Name="Position Hold"
	FlightMode[17].Repeat=300


--Init Severity Tables
	Severity={}
	Severity[1]={}
	Severity[1].Name=""
	
	for i=2,9 do
	  Severity[i]={}
	  Severity[i].Name=""
	  Severity[i].Sound="/SOUNDS/en/ER"..(i-2)..".wav"
	end
	Severity[2].Name="Emergency"
	Severity[3].Name="Alert"
	Severity[4].Name="Critical"
	Severity[5].Name="Error"
	Severity[6].Name="Warning"
	Severity[7].Name="Notice"
	Severity[8].Name="Info"
	Severity[9].Name="Debug"
	
	local apm_status_message = {severity = 0, textnr = 0, timestamp=0}

--Init A registers
	local A2 = model.getTelemetryChannel(1)
	if A2 .unit ~= 3 or A2 .range ~=1024 or A2 .offset ~=0 
	then
	  A2.unit = 3
	  A2.range = 1024
	  A2.offset = 0
	  model.setTelemetryChannel(1, A2)
	end
	
	local A3 = model.getTelemetryChannel(2)
	if A3.unit ~= 3 or A3.range ~=362 or A3.offset ~=-180 
	then
	  A3.unit = 3
	  A3.range = 362
	  A3.offset = -180
	  A3.alarm1 = -180
	  A3.alarm2 = -180
	  model.setTelemetryChannel(2, A3)
	end
	
	local A4 = model.getTelemetryChannel(3)
	if A4.unit ~= 3 or A4.range ~=362 or A4.offset ~=-180 
	then
	  A4.unit = 3
	  A4.range = 362
	  A4.offset = -180
	  A4.alarm1 = -180
	  A4.alarm2 = -180
	  model.setTelemetryChannel(3, A4)
	end
	
	local arrowLine = {
	  {-4, 5, 0, -4},
	  {-3, 5, 0, -3},
	  
	  --{0, 7, 0,-7},
	  
	  {3, 5, 0, -3},
	  {4, 5, 0, -4}
	}
	
-- draw arrow
	
	local function drawArrow()
	  	  
	  sinCorr = math.sin(math.rad(getValue(223)-prearmheading))
	  cosCorr = math.cos(math.rad(getValue(223)-prearmheading))
	  
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

--Aux Display functions and panels

	local function vgauge(vx, vy, vw, vh, value, vmax, look, max, min)  -- look use GREY_DEFAULT+FILL_WHITE
	  if value>vmax then
	    vmax=value
	  end
	  vh1 =(vh * value / vmax)
	  vy1 = (vy + (vh - vh1))
	  lcd.drawFilledRectangle(vx, vy1, vw, vh1, look)
	  lcd.drawRectangle(vx, vy ,vw, vh,SOLID,2)
	  
	  if max~=0 and max<=vmax then
	    vh1 =(vh * max / vmax)
	    vy1 = (vy + (vh - vh1))	
	    lcd.drawPixmap (vx+vw,vy1-3,"/SCRIPTS/BMP/larrow.bmp")
	    
	    --lcd.drawLine(vx,vy1,vx+vw,vy1,SOLID,2)
	    
	  end
	  
	  if min~=0 then
	    vh1 =(vh * min / vmax)
	    vy1 = (vy + (vh - vh1))	
	    lcd.drawPixmap (vx+vw,vy1-3,"/SCRIPTS/BMP/larrow.bmp")	
	    --lcd.drawLine(vx,vy1,vx+vw,vy1,SOLID,2)
	  end
	end

	local function round(num, idp)
		mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end
	
	
-- GPS Panel
	local function gpspanel()
	  
	  telem_t1 = getValue(209) -- Temp1
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
	  
	  hdop=round(getValue(203))
	  if hdop <20 then
	    lcd.drawNumber (180, 10, hdop, PREC1+LEFT+SMLSIZE )
	  else
	    lcd.drawNumber (180, 10, hdop, PREC1+LEFT+BLINK+INVERS+SMLSIZE)
	  end
	
	  -- pilot lat  52.027536, 8.513764
	  
	  -- flieger   52.027522, 8.515386
	  -- 110,75 mm
	  --pilotlat = math.rad(52.027536) --getValue("pilot-latitude")
	  --pilotlon = math.rad(8.513764)--getValue("pilot-longitude")
	  --curlat = math.rad(52.027522)--getValue("latitude")
	  --curlon = math.rad(8.515386)--getValue("longitude")
	  
	  pilotlat = math.rad(getValue("pilot-latitude"))
	  pilotlon = math.rad(getValue("pilot-longitude"))
	  curlat = math.rad(getValue("latitude"))
	  curlon = math.rad(getValue("longitude"))
	  
	  if pilotlat~=0 and curlat~=0 and pilotlon~=0 and curlon~=0 then 
	    
	    z1 = math.sin(curlon - pilotlon) * math.cos(curlat)
	    z2 = math.cos(pilotlat) * math.sin(curlat) - math.sin(pilotlat) * math.cos(curlat) * math.cos(curlon - pilotlon)
	    headfromh =  math.floor(math.deg(math.atan2(z1, z2)) + 0.5) % 360
	    headtoh = (headfromh - 180) % 360

	    -- use prearmheading later to rotate cordinates relative to copter.
	    radarx=z1*6358364.9098634 -- meters for x absolut to center(homeposition)
	    radary=z2*6358364.9098634 -- meters for y absolut to center(homeposition)	    
	    
	    radTmp = math.rad( headfromh - getValue(223) % 360 )
	    radarxtmp = radarx * math.cos(radTmp) - radary * math.sin(radTmp)
	    radarytmp =  radarx* math.sin(radTmp) + radary * math.cos(radTmp)
	    
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

--	    if apmarmed ~= 1 then
--	      offsetX =0
--	      offsetY =0
--	    else
	      offsetX = radarxtmp / divtmp
	      offsetY = (radarytmp / divtmp)*-1
--	    end
	  else
	    headfromh = 0
	    headtoh = 0
	  end
	  --lcd.drawText(171,25,"X=",SMLSIZE )
	  --lcd.drawNumber(lcd.getLastPos(),25,radarxtmp,SMLSIZE + LEFT)
	  --lcd.drawText(171,47,"Y=", SMLSIZE)
	  --lcd.drawNumber(lcd.getLastPos(),47,radarytmp,SMLSIZE + LEFT)
	  --lcd.drawText(190,57,"",SMLSIZE )
	  --lcd.drawNumber(lcd.getLastPos(),57,headtoh,SMLSIZE + LEFT)
	  
	  lcd.drawText(187,37,"o",0)	    
	  lcd.drawRectangle(167, 19, 45, 45)
	  for j=169, 209, 4 do
	    lcd.drawPoint(j, 19+22) 
	  end
	  for j=21, 61, 4 do
	    lcd.drawPoint(167+22, j) 
	  end
	  lcd.drawNumber(180, 57, getValue(212), SMLSIZE)
	  lcd.drawText(lcd.getLastPos(), 57, "m", SMLSIZE)
	end

-- Speed Panel
	local function speedpanel()
	  
	  lcd.drawTimer(106,42,model.getTimer(0).value,MIDSIZE)
	  
	  lcd.drawNumber(132, 53,getValue(211),MIDSIZE)
	  
	end

-- Pitch Panel
	local function pitchpanel()
	  
	  
	  lcd.drawLine (153, 15, 153, 63, SOLID, 0)
	  
	  for w=6, 0, -1 do
	    
	    lcd.drawLine (151, 58-w*48/7+3, 155, 58-w*48/7+3, SOLID, 0)
	    lcd.drawNumber (156,58-w*48/7, math.abs(w*15-45), LEFT+SMLSIZE)
	    
	  end
	  
	  --ypitch
	  
	  local pitch= getValue(205)*10
	  if math.abs(pitch)<=45 then
	    
	    --lcd.drawPixmap (146,58-(pitch+45)*42/90,"/SCRIPTS/BMP/rarrow.bmp")
	    lcd.drawText(146,58-(pitch+45)*42/90,">", 0)
	    -- elseif pitch<45 then lcd.drawPixmap(144,39,"/SCRIPTS/BMP/darrow3.bmp")
	    -- elseif pitch>45 then lcd.drawPixmap(144,17,"/SCRIPTS/BMP/uarrow3.bmp")
	  elseif pitch<45 then
	    lcd.drawText(144,39,">>", SMLSIZE)
	  elseif pitch>45 then
	    lcd.drawText(144,17,">>", SMLSIZE )
	  end
	end

-- Altitude Panel
	local function altpanel()
	  
	  altitude = getValue(206)
	  galtitude= getValue(213)
	  aspd=getValue(225)
	  lcd.drawLine (90, 15, 90, 63, SOLID, 0)
	  
	  if math.abs(altitude) <= 10 then 
	    yinc=1
	  elseif math.abs(altitude) <=30 then
	    yinc=5
	  else
	    yinc=10
	  end
	  
	  for az=3, -3, -1 do
	    lcd.drawLine (88, 58-az*48/7-21+3, 92, 58-az*48/7-21+3, SOLID, 0)
	    
	    if az~=0 then
	      
	      lcd.drawNumber (75,58-az*48/7-24+3,(((math.ceil(altitude/yinc))*yinc)+az*yinc), LEFT+SMLSIZE)
	      
	    else
	      
	      lcd.drawNumber (75,58-az*48/7-24+3,(altitude+az*yinc), LEFT+SMLSIZE+INVERS)
	      
	    end
	    
	  end
	  
	  --Alt max
	  lcd.drawText(92,10,getValue(237),SMLSIZE)
	end

--Vertical Speed Panel
	local function vspeedpanel()
	  
	  vspd= getValue(224)
	  if vspd == 0 then
	    lcd.drawText(93, 37,"==",SMLSIZE)
	    lcd.drawNumber(94, 30,vspd,LEFT+SMLSIZE)
	  elseif vspd >0 then
	    lcd.drawText(93, 37-vspd,"++",SMLSIZE)
	    lcd.drawNumber(94, 45,vspd,LEFT+SMLSIZE)
	  elseif vspd <0 then
	    lcd.drawText(93, 37-vspd,"--",SMLSIZE)
	    lcd.drawNumber(94, 30,vspd,LEFT+SMLSIZE)
	  end
	end

-- Roll Panel
	local function rollpanel()
	  
	  rangle=math.rad(getValue(204)*10)
	  rx2=145
	  rx1=100
	  ry1=round(32-20*math.sin(rangle))
	  ry2=round(32+20*math.sin(rangle))
	  
	  lcd.drawLine (rx1,ry1-1 ,rx2, ry2-1, SOLID, 2)
	  lcd.drawLine (rx1,ry1 ,rx2, ry2, SOLID, 2)
	  lcd.drawLine (rx1,ry1+1 ,rx2, ry2+1, SOLID, 2)
	end

--Heading Panel
	local function headingpanel()	  
	  lcd.drawNumber(129, 9,getValue(223),MIDSIZE)
	  lcd.drawText(lcd.getLastPos(),9,"\64",MIDSIZE)
	end

-- Top Panel
	local function toppanel()
	  
	  lcd.drawFilledRectangle(0, 0, 212, 9, 0)
	  
	  if apmarmed==1 then
	    lcd.drawText(1, 0, (FlightMode [FmodeNr].Name), INVERS)
	  else
	    lcd.drawText(1, 0, (FlightMode [FmodeNr].Name), INVERS+BLINK)
	  end
	  lcd.drawText(94, 0, " T:", INVERS)
	  lcd.drawTimer(lcd.getLastPos(),0,model.getTimer(1).value,INVERS)
	  
	  lcd.drawText(134, 0, "TX:", INVERS)
	  lcd.drawNumber(160, 0, getValue(189)*10,0+PREC1+INVERS)
	  lcd.drawText(lcd.getLastPos(), 0, "v", INVERS)
	  
	  lcd.drawText(172, 0, "rssi:", INVERS)
	  lcd.drawNumber(lcd.getLastPos()+10, 0, getValue(200),0+INVERS)
	end

--Power Panel
	local function powerpanel()
	  --Used on power panel -- still to check if all needed
	  
	  power=getValue(207) 
	  battremaining = (power%100)*cap_est/zerocap  --battery % remaining reported adjusted to initial reading
	  throttle = (power-(power%100))/100 --throttle reported
	  tension=getValue(216) --
	  current=getValue(217) ---
	  consumption=getValue(218)---
	  watts=getValue(219) ---
	  tension_min=getValue(246) ---
	  current_max=getValue(247) ---
	  watts_max=getValue(248)  ---
	  cellmin=getValue(214) --- 214 = cell-min
	  
	  if battremaining~=consumption_max then
	    eff=battremaining*model.getTimer(0).value/(zerocap-battremaining)
	    consumption_max=battremaining
	  end					
	  if (eff-model.getTimer(0).value)<0 then
	    lcd.drawText(0,9,"calc",MIDSIZE+BLINK)
	  else
	    lcd.drawTimer(0,9,eff-model.getTimer(0).value,MIDSIZE)
	  end
	  lcd.drawNumber(lcd.getLastPos()+25,9,round(battremaining),MIDSIZE)
	  lcd.drawText(lcd.getLastPos(),9,"%",MIDSIZE)
	  
	  lcd.drawNumber(28,21,consumption,MIDSIZE)
	  xposCons=lcd.getLastPos()
	  lcd.drawText(xposCons,20,"m",SMLSIZE)
	  lcd.drawText(xposCons,26,"Ah",SMLSIZE)
	  
	  lcd.drawNumber(57,21,watts,MIDSIZE)
	  lcd.drawText(lcd.getLastPos(),22,"W",0)
	  
	  lcd.drawNumber(28,32,tension*10,MIDSIZE+PREC1)
	  lcd.drawText(lcd.getLastPos(),33,"V",0)
	  
	  lcd.drawNumber(57,32,current*10,MIDSIZE+PREC1)
	  lcd.drawText(lcd.getLastPos(),33,"A",0)
	  
	  lcd.drawNumber(28,47,cellmin*100,MIDSIZE+PREC2)
	  xposConsCell=lcd.getLastPos()
	  lcd.drawText(xposConsCell,47,"Cell",SMLSIZE)
	  lcd.drawText(xposConsCell,54,"min",SMLSIZE)
	  
	  -- lcd.drawNumber(lcd.getLastPos() +2,56,apm_status_message.textnr,SMLSIZE)
	  -- lcd.drawNumber(lcd.getLastPos() +15,47,oldcellvoltage*100,SMLSIZE)
	  -- lcd.drawNumber(lcd.getLastPos() ,54,cellmin*100,SMLSIZE)
	  
	  vgauge(64,19,8,45,throttle,100,GREY_DEFAULT+FILL_WHITE,0,0)
	  lcd.drawText(65,11,"T%",SMLSIZE)
	end
	
--Battery status
	local function batstatus()
	  cell_nr = math.ceil(getValue(216) / 4.2)
	  cellv=(getValue(216)/ cell_nr)
	  cap_est=0
	  if cellv>=4.2 then cap_est=100
	  elseif cellv>=4.00 then cap_est=84
	  elseif cellv>=3.96 then cap_est=77
	  elseif cellv>=3.93 then cap_est=70
	  elseif cellv>=3.90 then cap_est=63
	  elseif cellv>=3.86 then cap_est=56
	  elseif cellv>=3.83 then cap_est=48
	  elseif cellv>=3.80 then cap_est=43
	  elseif cellv>=3.76 then cap_est=35
	  elseif cellv>=3.73 then cap_est=27
	  elseif cellv>=3.70 then cap_est=21
	  elseif cellv>=3.67 then cap_est=14
	  cap_est=0
	  end
	  return cellv, cell_nr, cap_est
	end
	
--APM Armed and errors		
	local function armed_status()
	  
	  t2 = getValue(210)
	  apmarmed = t2%0x02;
	  
	  if apmarmed ~=1 then -- report last heading bevor arming. this can used for display position relative to copter
	    prearmheading=getValue(223)--( 0 * 3.1415926) / 180 --in radien getValue(223) 90 ist test
	  end
	  
	  if lastarmed~=apmarmed then
	    lastarmed=apmarmed
	    if apmarmed==1 then
	      model.setTimer(0,{ mode=1, start=0, value= SumFlight, countdownBeep=0, minuteBeep=1, persistent=1 })
	      model.setTimer(1,{ mode=1, start=0, value= FlightMode[FmodeNr].Timer, countdownBeep=0, minuteBeep=0, persistent=1 })
	      playFile("SOUNDS/en/SARM.wav")
	      playFile(FlightMode[FmodeNr].SoundActive1)
	      
	      batstatus()
	      playNumber(cell_nr, 0, 0)
	      playFile("/SOUNDS/en/battc.wav")
	      playFile("/SOUNDS/en/att.wav")
	      playNumber(cap_est,8,0)
	      zerobattery=cap_est
	      zerocap=getValue(207)%100
	      
	    else
	      
	      SumFlight = model.getTimer(0).value
	      model.setTimer(0,{ mode=0, start=0, value= model.getTimer(0).value, countdownBeep=0, minuteBeep=1, persistent=1 })
	      
	      FlightMode[FmodeNr].Timer=model.getTimer(1).value
	      model.setTimer(1,{ mode=0, start=0, value= FlightMode[FmodeNr].Timer, countdownBeep=0, minuteBeep=0, persistent=1 })
	      
	      playFile("SOUNDS/en/SDISAR.wav")
	    end
	    
	  end
	  
	  t2 = (t2-apmarmed)/0x02;
	  status_severity = t2%0x10;
	  
	  t2 = (t2-status_severity)/0x10;
	  status_textnr = t2%0x400;
	  
	  if(status_severity > 0)
	  then
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
	      nameofsndfile = "SOUNDS/en/MSG"..apm_status_message.textnr..".wav"
	      playFile(nameofsndfile)
	      last_apm_message_played = apm_status_message.textnr
	    end
	  end
	end


--FlightModes
	local function Flight_modes()
	  FmodeNr=getValue(208)+1
	  if FmodeNr<1 or FmodeNr>17 then
	    FmodeNr=13
	  end
	  
	  
	  if FmodeNr~=last_flight_mode then
	    
	    playFile(FlightMode[FmodeNr].SoundActive1)
	    last_flight_mode_play=(100*FlightMode[FmodeNr].Repeat)+getTime()
	    
	    if apmarmed==1 then
	      
	      FlightMode[last_flight_mode].Timer=model.getTimer(1).value
	      model.setTimer(1,{ mode=1, start=0, value= FlightMode[FmodeNr].Timer, countdownBeep=0, minuteBeep=0, persistent=1 })
	      
	    else
	      model.setTimer(1,{ mode=0, start=0, value= FlightMode[FmodeNr].Timer, countdownBeep=0, minuteBeep=0, persistent=1 })
	    end
	    
	    last_flight_mode=FmodeNr
	    
	    
	  elseif getTime()>last_flight_mode_play
	  then
	    playFile(FlightMode[FmodeNr].SoundActive1)
	    last_flight_mode_play=(100*FlightMode[FmodeNr].Repeat)+getTime()
	  end
	end
	

--Background
	local function background()
	  
	  armed_status()
	  
	  Flight_modes()
	  
	end


--Main
	local function run(event)
	  
	  --lcd.lock()
	  lcd.clear()
	  
	  armed_status()
	  
	  Flight_modes()
	  
	  toppanel()
	  
	  powerpanel()
	  
	  altpanel()
	  
	  vspeedpanel()
	  
	  rollpanel()
	  
	  headingpanel()
	  
	  pitchpanel()
	  
	  speedpanel()
	  
	  gpspanel()
	  
	  drawArrow()
	  
	end

	return {run=run, background=background}
