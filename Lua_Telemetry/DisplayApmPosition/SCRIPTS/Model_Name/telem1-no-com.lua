
	local SumFlight=0
	local lastarmed=0
	local apmarmed=0
	local FmodeNr=13
	local last_flight_mode = 1
	local last_apm_message_played = 0
	local mult, tension, current, consumption, vspd
 	local watts, tension_min, current_max, watts_max, cellmin, xposCons, xposConsCell
	local t2, nameofsndfile, prearmheading, radarx, radary, radarxtmp, radarytmp, hdop
	local watthours = 0
	local lastconsumption =0
	local localtime =0
	local oldlocaltime=0
	local localtimetwo =0
	local oldlocaltimetwo=0	
	local pilotlat, pilotlon, curlat, curlon, telem_sats, telem_lock, telem_t1
	local status_severity, status_textnr, hypdist, battWhmax, maxconsume, whconsumed
	local batteryreachmaxWH = 0
	
	local FORCE = 0x02
	local X1, Y1, X2, Y2
	local sinCorr, cosCorr, radTmp
	local CenterXcolArrow = 189
	local CenterYrowArrow = 41
	local offsetX = 0
	local offsetY = 0
	local htsapaneloffset = 11
	local divtmp = 1
	local upppp = 20480
	local divvv = 2048
	
	model.setTimer(0, {mode=0, start=0, value= 0, countdownBeep=0, minuteBeep=1, persistent=1})
	model.setTimer(1, {mode=0, start=0, value= 0, countdownBeep=0, minuteBeep=0, persistent=1})
	
	FlightMode = {}
	for i=1, 17 do
	  FlightMode[i] = {}
	  FlightMode[i].Name=""
	  FlightMode[i].SoundActive1="/SOUNDS/en/AVFM"..(i-1).."A.wav" 
	end
	
	FlightMode[1].Name="Stabilize"
	FlightMode[2].Name="Acro"
	FlightMode[3].Name="Altitude Hold"
	FlightMode[4].Name="Auto"
	FlightMode[5].Name="Guided"
	FlightMode[6].Name="Loiter"
	FlightMode[7].Name="Return to launch"
	FlightMode[8].Name="Circle"
	FlightMode[9].Name="Invalid Mode"
	FlightMode[10].Name="Land"
	FlightMode[11].Name="Optical Loiter"
	FlightMode[12].Name="Drift"
	FlightMode[13].Name="Invalid Mode"
	FlightMode[14].Name="Sport"
	FlightMode[15].Name="Flip Mode"
	FlightMode[16].Name="Auto Tune"
	FlightMode[17].Name="Position Hold"
	
	
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
	  
	  {3, 5, 0, -3},
	  {4, 5, 0, -4}
	}
	
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
	
	local function drawWhGauge()
	   
	   whconsumed = watthours + ( watthours * ( model.getGlobalVariable(8, 1)/100) ) 
	   if whconsumed >= maxconsume then
	      whconsumed = maxconsume
	   end
	   
	   lcd.drawFilledRectangle(74,9,11,55,INVERS)
	   lcd.drawFilledRectangle(75,9,9, (whconsumed - 0)* ( 55 - 0 ) / (maxconsume - 0) + 0, 0)
	end
	
	local function round(num, idp)
		mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end
	
	
	local function gpspanel()
	  
	  telem_t1 = getValue(209)
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
	
	  curlat = math.rad(getValue("latitude"))
	  curlon = math.rad(getValue("longitude"))
	  
	  
	  if pilotlat~=0 and curlat~=0 and pilotlon~=0 and curlon~=0 then
	  
	    z1 = math.sin(curlon - pilotlon) * math.cos(curlat)
	    z2 = math.cos(pilotlat) * math.sin(curlat) - math.sin(pilotlat) * math.cos(curlat) * math.cos(curlon - pilotlon)
	    radarx=z1*6358364.9098634
	    radary=z2*6358364.9098634
	    hypdist =  math.sqrt( math.pow(math.abs(radarx),2) + math.pow(math.abs(radary),2) )
	    
	    radTmp = math.rad( prearmheading )
	    radarxtmp = radarx * math.cos(radTmp) - radary * math.sin(radTmp)
	    radarytmp = radarx * math.sin(radTmp) + radary * math.cos(radTmp)
	    
	    if math.abs(radarxtmp) >= math.abs(radarytmp) then
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
	    divvv = 2048  
	    
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
	
	
	local function htsapanel()
	
	  lcd.drawLine (htsapaneloffset + 154, 8, htsapaneloffset + 154, 63, SOLID, 0)
	  lcd.drawText(htsapaneloffset + 76,11,"Heading ",SMLSIZE)
	  lcd.drawNumber(lcd.getLastPos(),9,getValue(223),MIDSIZE+LEFT)
	  lcd.drawText(lcd.getLastPos(),9,"\64",MIDSIZE)
	  lcd.drawText(htsapaneloffset + 76,25,"Alt ",SMLSIZE)
	  lcd.drawNumber(lcd.getLastPos()+3,22,getValue(206),MIDSIZE+LEFT)
	  lcd.drawText(lcd.getLastPos(),22,"m",MIDSIZE)
	  vspd= getValue(224)
	  if vspd == 0 then
	    lcd.drawText(lcd.getLastPos(), 25,"==",0)
	  elseif vspd >0 then
	    lcd.drawText(lcd.getLastPos(), 25,"++",0)
	  elseif vspd <0 then
	    lcd.drawText(lcd.getLastPos(), 25,"-",0)
	  end
	  lcd.drawNumber(lcd.getLastPos(),25,vspd,0+LEFT)
	 
	  lcd.drawText(htsapaneloffset + 76,35,"Max",SMLSIZE)
	  lcd.drawNumber(lcd.getLastPos()+8,35,getValue(237),SMLSIZE+LEFT)
	  lcd.drawText(lcd.getLastPos(),35,"m",SMLSIZE)
	  
	  lcd.drawTimer(htsapaneloffset + 106,42,model.getTimer(0).value,MIDSIZE)
	  
	  lcd.drawText(htsapaneloffset + 76,56,"Speed",SMLSIZE)
	  lcd.drawNumber(lcd.getLastPos()+8, 53,getValue(211),MIDSIZE+LEFT)
	  
	end
	
	
	local function toppanel()
	  
	  lcd.drawFilledRectangle(0, 0, 212, 9, 0)
	  
	  if apmarmed==1 then
	    lcd.drawText(1, 0, (FlightMode [FmodeNr].Name), INVERS)
	  else
	    lcd.drawText(1, 0, (FlightMode [FmodeNr].Name), INVERS+BLINK)
	  end
	  
	  lcd.drawText(134, 0, "TX:", INVERS)
	  lcd.drawNumber(160, 0, getValue(189)*10,0+PREC1+INVERS)
	  lcd.drawText(lcd.getLastPos(), 0, "v", INVERS)
	  
	  lcd.drawText(172, 0, "rssi:", INVERS)
	  lcd.drawNumber(lcd.getLastPos()+10, 0, getValue(200),0+INVERS)
	end

	local function powerpanel()
	  tension=getValue(216)
	  current=getValue(217)
	  consumption=getValue(218)
	  watts=getValue(219)
	  tension_min=getValue(246)
	  current_max=getValue(247)
	  watts_max=getValue(248)
	  cellmin=getValue(214)
	  
	  lcd.drawNumber(30,13,tension*10,DBLSIZE+PREC1)
	  lcd.drawText(lcd.getLastPos(),14,"V",0)
	  
	  lcd.drawNumber(67,9,current*10,MIDSIZE+PREC1)
	  lcd.drawText(lcd.getLastPos(),10,"A",0)
	 
	  
	  lcd.drawNumber(67,21,watts,MIDSIZE)
	  lcd.drawText(lcd.getLastPos(),22,"W",0)
	  
	  lcd.drawNumber(1,33,consumption + ( consumption * ( model.getGlobalVariable(8, 0)/100 ) ),MIDSIZE+LEFT)
	  xposCons=lcd.getLastPos()
	  lcd.drawText(xposCons,32,"m",SMLSIZE)
	  lcd.drawText(xposCons,38,"Ah",SMLSIZE)
	  
	  lcd.drawNumber(67,33,( watthours + ( watthours * ( model.getGlobalVariable(8, 1)/100) ) ) *10 ,MIDSIZE+PREC1)
	  xposCons=lcd.getLastPos()
	  lcd.drawText(xposCons,32,"w",SMLSIZE)
	  lcd.drawText(xposCons,38,"h",SMLSIZE)
	  
	  
	  lcd.drawNumber(42,47,cellmin*100,DBLSIZE+PREC2)
	  xposConsCell=lcd.getLastPos()
	  lcd.drawText(xposConsCell,48,"V",SMLSIZE)
	  lcd.drawText(xposConsCell,56,"C-min",SMLSIZE)
	end
	
	
	local function calcWattHs()
	  
	  localtime = localtime + (getTime() - oldlocaltime)
	  if localtime >=10 then
	    watthours = watthours + ( getValue(219) * (localtime/360000) )
	    localtime = 0
	  end  
	  oldlocaltime = getTime()
	  maxconsume = model.getGlobalVariable(8, 2)
	end
	
	
	local function armed_status()
	  
	  t2 = getValue(210)
	  apmarmed = t2%0x02
	 
	  if apmarmed ~=1 then
	    prearmheading=getValue(223)
	    pilotlat = math.rad(getValue("latitude"))
	    pilotlon = math.rad(getValue("longitude"))
	  end
	  
	  if lastarmed~=apmarmed then
	    lastarmed=apmarmed
	    if apmarmed==1 then
	      model.setTimer(0,{ mode=1, start=0, value= SumFlight, countdownBeep=0, minuteBeep=1, persistent=1 })
	      playFile("SOUNDS/en/SARM.wav")
	      playFile(FlightMode[FmodeNr].SoundActive1)
	      
	    else
	      
	      SumFlight = model.getTimer(0).value
	      model.setTimer(0,{ mode=0, start=0, value= model.getTimer(0).value, countdownBeep=0, minuteBeep=1, persistent=1 })
	      
	      playFile("SOUNDS/en/SDISAR.wav")
	    end
	    
	  end
	  
	  t2 = (t2-apmarmed)/0x02
	  status_severity = t2%0x10
	  
	  t2 = (t2-status_severity)/0x10
	  status_textnr = t2%0x400
	  
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
	 
	  if apm_status_message.textnr >0 then
	    if last_apm_message_played ~= apm_status_message.textnr then
	      nameofsndfile = "SOUNDS/en/MSG"..apm_status_message.textnr..".wav"
	      playFile(nameofsndfile)
	      last_apm_message_played = apm_status_message.textnr
	    end
	  end
	end
	
	
	local function Flight_modes()
	  FmodeNr=getValue(208)+1
	  if FmodeNr<1 or FmodeNr>17 then
	    FmodeNr=13
	  end
	  
	  if FmodeNr~=last_flight_mode then
	    playFile(FlightMode[FmodeNr].SoundActive1)
	    last_flight_mode=FmodeNr
	  end
	end
	
	
	local function playMaxWhReached()
	  
	  if (watthours  + ( watthours * ( model.getGlobalVariable(8, 1)/100) ) ) >= maxconsume then
	    localtimetwo = localtimetwo + (getTime() - oldlocaltimetwo)
	    if localtimetwo >=800 then
	      playFile("/SOUNDS/en/ALARM3K.wav")
	      localtimetwo = 0
	    end
	    oldlocaltimetwo = getTime()	        
	  end
	  
	end
	
	local function background()
	  
	  armed_status()
	  
	  Flight_modes()
	  
	  calcWattHs()
	  
	  playMaxWhReached()
	  
	end
	
	local function run(event)
	  
	  lcd.clear()
	  
	  armed_status()
	  
	  Flight_modes()
	  
	  toppanel()
	  
	  powerpanel()
	    
	  htsapanel()
	  
	  gpspanel()
	  
	  drawArrow()
	  
	  calcWattHs()
	  
	  drawWhGauge()
	  
	  playMaxWhReached()

	end

	return {run=run, background=background}
	