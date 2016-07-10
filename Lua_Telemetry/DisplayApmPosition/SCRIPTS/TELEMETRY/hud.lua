-- Pierre-Olivier Vauboin <povauboin@gmail.com>
-- 2016 - Telemetry HUD
-- OpenTX Taranis 2.1.8 - EEPR 217 - Teensy 3.2 MavLink_FrSkySPort

local SIZE_STATUSBAR_W = 212
local SIZE_STATUSBAR_H = 8

local POS_FLIGHTMODE_X = 0
local POS_FLIGHTTIMER_X = 104

local POS_SIGNALDB_X = 135
local ICO_SIGNALDB_N = 5

local POS_TXVOLTAGE_X = 176
local ICO_TXVOLTAGE_N = 5

local POS_FPS_X = 86
local POS_FPS_Y = 0

local SIZE_INSTRUMENTS_W = 94
local SIZE_INSTRUMENTS_H = 56

local SCALE_STEP = 5
local SCALE_SPACE = 12
local SCALE_SIZE = MIDSIZE

local SIZE_AIRSPEED_W = 16
local SIZE_AIRSPEED_H = SIZE_INSTRUMENTS_H
local POS_AIRSPEED_X = 16
local POS_AIRSPEED_Y = 0

local SIZE_ALTIMETER_W = 17
local SIZE_ALTIMETER_H = SIZE_INSTRUMENTS_H
local POS_ALTIMETER_X = SIZE_INSTRUMENTS_W - SIZE_ALTIMETER_W
local POS_ALTIMETER_Y = 0

local POS_COMPASS_X = 0
local POS_COMPASS_Y = 0

local SIZE_HORIZON_W = SIZE_INSTRUMENTS_W - SIZE_AIRSPEED_W - SIZE_ALTIMETER_W
local SIZE_HORIZON_H = SIZE_INSTRUMENTS_H
local POS_HORIZON_X = SIZE_INSTRUMENTS_W / 2
local POS_HORIZON_Y = SIZE_INSTRUMENTS_H / 2

local SIZE_POWERBAR_W = 118
local SIZE_POWERBAR_H = 20

local SIZE_NAVBAR_W = 118
local SIZE_NAVBAR_H = 36

local SIZE_SPEEDAREA_W = SIZE_NAVBAR_W / 3
local SIZE_SPEEDAREA_H = SIZE_NAVBAR_H

local SIZE_HEADINGAREA_W = SIZE_NAVBAR_W / 3
local SIZE_HEADINGAREA_H = SIZE_NAVBAR_H

local SIZE_GPSAREA_W = SIZE_NAVBAR_W / 3
local SIZE_GPSAREA_H = SIZE_NAVBAR_H

local SIZE_GPSBAR_W = SIZE_GPSAREA_W
local SIZE_GPSBAR_H = 9

local BATTERY_TX_CELLS = 6 -- NiMH 6 cells
local BATTERY_TX_LOW = 1.1 * BATTERY_TX_CELLS
local BATTERY_TX_HIGH = 1.5 * BATTERY_TX_CELLS

local BATTERY_CELLS = 3 -- LiPo 3S - Max 6S
local BATTERY_LOW = 3.3 * BATTERY_CELLS
local BATTERY_HIGH = 4.2 * BATTERY_CELLS
local BATTERY_CELL_WARN = 3.5
local BATTERY_CELL_CRIT = 3.3

local FLIGHTMODE_INVALID = 8
local FLIGHTMODES = {
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

local UNIT_MODE_METRIC = 0x01
local UNIT_MODE_IMPERIAL = 0x02
local _unit_mode = UNIT_MODE_METRIC
local function unit_mode_toggle()
    if _unit_mode == UNIT_MODE_METRIC then
        _unit_mode = UNIT_MODE_IMPERIAL
    else
        _unit_mode = UNIT_MODE_METRIC
    end
end

local GPS_MODE_NORTH = 0x01
local GPS_MODE_PILOT = 0x02
local _gps_mode = GPS_MODE_NORTH
local function gps_mode_toggle()
    if _gps_mode == GPS_MODE_NORTH then
        _gps_mode = GPS_MODE_PILOT
    else
        _gps_mode = GPS_MODE_NORTH
    end
end

local _gps_prv = {lat = 0, lon = 0}
local _gps_fix = {lat = 0, lon = 0, fixtype = 0, nsat = 0, hdop = 0}
local _gps_home = {lat = 0, lon = 0, hdg = 0, dst = 0}
local function gps_set_home()
    if _gps_fix.fixtype < 2 then
        return
    end
    _gps_home.lat = _gps_fix.lat
    _gps_home.lon = _gps_fix.lon
    _gps_home.hdg = getValue("Hdg")
    _gps_home.dst = 0
end

local function gps_get_relative_hdg(hdg)
    if _gps_mode == GPS_MODE_NORTH then
        return hdg
    else
        return (hdg - _gps_home.hdg + 360) % 360
    end
end

local function gps_get_mode()
    return _gps_mode == GPS_MODE_NORTH and "N" or "R"
end

local function gps_latlon_distance(p0_lat, p0_lon, p1_lat, p1_lon)
    -- http://www.movable-type.co.uk/scripts/latlong.html
    local d_lamdba = math.rad(p1_lon - p0_lon)
    local d_phi = math.rad(p1_lat - p0_lat)
    local phi_m = math.rad(p1_lat + p0_lat) / 2
    local x = d_lamdba * math.cos(phi_m)
    local y = d_phi
    local r = 6371000
    local ro = r * math.sqrt(math.pow(x, 2) + math.pow(y, 2))
    local theta = (-math.deg(math.atan2(y, x)) + 90 + 360) % 360
    return ro, theta
end

local _gps_speed = {hdg = 0}
local _gps_radar = {hdg = 0}
local _gps_init = false
local function process_gps()
    -- GPS status = ap_sat_visible*10 + ap_fixtype
    _gps_fix.fixtype = getValue("Tmp1") % 10
    _gps_fix.nsat = (getValue("Tmp1") - _gps_fix.fixtype) / 10
    -- HDOP value * 25 - 8 bit resolution
    _gps_fix.hdop = getValue("A2") / 25
    if _gps_fix.fixtype < 2 then
        return
    end
    local gps = getValue("GPS")
    if type(gps) ~= "table" then
        return
    end
    if gps.lat ~= _gps_fix.lat or gps.lon ~= _gps_fix.lon then
        _gps_prv.lat = _gps_fix.lat
        _gps_prv_lon = _gps_fix.lon
        _gps_fix.lat = gps.lat
        _gps_fix.lon = gps.lon
    end
    if not _gps_init then
        gps_set_home()
        _gps_init = true
    end

    _gps_home.dst, _gps_radar.hdg = gps_latlon_distance(
        _gps_home.lat, _gps_home.lon,
        _gps_fix.lat, _gps_fix.lon
    )
    null, _gps_speed.hdg = gps_latlon_distance(
        _gps_prv.lat, _gps_prv_lon,
        _gps_fix.lat, _gps_fix.lon
    )
end

local _timer_value = 0
local function timer_reset()
    _timer_value = 0
    model.setTimer(0, {
        mode=0, start=0, value=0, countdownBeep=0, minuteBeep=true, persistent=1
    })
end

local function timer_start()
    model.setTimer(0, {
        mode=1, start=0, value=_timer_value, countdownBeep=0, minuteBeep=true, persistent=1
    })
end

local function timer_stop()
    _timer_value = model.getTimer(0).value
    model.setTimer(0, {
        mode=0, start=0, value=_timer_value, countdownBeep=0, minuteBeep=true, persistent=1
    })
end

local function action_arm()
    playFile("/SOUNDS/en/engarm.wav")
    timer_start()
    gps_set_home()
end

local function action_disarm()
    playFile("/SOUNDS/en/engdisa.wav")
    timer_stop()
end

local _apm_flightmode = FLIGHTMODE_INVALID
local function process_flightmode()
    -- Current Flight Mode reported by Mavlink
    local fm = getValue("Fuel")
    if fm < 0 or fm > 17 then
        fm = FLIGHTMODE_INVALID
    end
    if fm ~= _apm_flightmode then
        playFile("/SOUNDS/en/TELEM/AVFM" .. fm .. "A.wav")
        _apm_flightmode = fm
    end
end

local _apm_armed = false
local _apm_msg = {n = 0, ts = 0}
local function process_messages()
    -- Armed Status and Mavlink Messages: 16 bit value
    -- bit 1: armed
    -- bit 2-5: severity +1 (0 means no message)
    -- bit 6-15: number representing a specific text
    local raw = getValue("Tmp2")
    local armed = bit32.extract(raw, 0) == 1
    local severity = bit32.extract(raw, 1, 4)
    local msg = bit32.extract(raw, 5, 10)

    if armed ~= _apm_armed then
        _apm_armed = armed
        if _apm_armed then
            action_arm()
        else
            action_disarm()
        end
    end

    if severity > 0 and msg ~= _apm_msg.n then
        _apm_msg.n = msg
        _apm_msg.ts = getTime()
    end
    if getTime() - _apm_msg.ts > 200 then
        _apm_msg.n = 0
    end
end

local _alert_ts = 0
local function process_voltage()
    local cell_all = getValue("Cels") -- XXX this is duplicated code
    if type(cell_all) ~= "table" then
        return
    end
    local play_crit = false
    local play_warn = false
    for i, cell_v in ipairs(cell_all) do
        if cell_v <= BATTERY_CELL_CRIT then
            play_crit = true
        elseif cell_v <= BATTERY_CELL_WARN then
            play_warn = true
        end
    end
    local ts = getTime()
    if play_crit and (ts - _alert_ts > 500) then
        _alert_ts = ts
        playFile("/SOUNDS/en/TELEM/ALARM3K.wav")
        playFile("/SOUNDS/en/batcrit.wav")
    elseif play_warn and (ts - _alert_ts > 1000) then
        _alert_ts = ts
        playFile("/SOUNDS/en/batlow.wav")
    end
end

local function process_event(event)
    if event == EVT_ENTER_BREAK then
        gps_mode_toggle()
    elseif event == EVT_PLUS_BREAK then
        unit_mode_toggle()
    end
end

local function convert_angle(alpha)
    return -180 + alpha * 360 / 256
end

local function draw_shape(x, y, shape, alpha)
    local sin_a = math.sin(math.rad(alpha))
    local cos_a = math.cos(math.rad(alpha))
    for index, point in pairs(shape) do
        lcd.drawLine(
            x + point[1] * cos_a - point[2] * sin_a,
            y + point[1] * sin_a + point[2] * cos_a,
            x + point[3] * cos_a - point[4] * sin_a,
            y + point[3] * sin_a + point[4] * cos_a,
            SOLID, FORCE
        )
    end
end

local function draw_circle(x, y, r)
    local p0_x = r
    local p0_y = 0
    for alpha = 10, 90, 10 do
        local p1_x = math.floor(r * math.cos(math.rad(alpha)) + 0.5)
        local p1_y = math.floor(r * math.sin(math.rad(alpha)) + 0.5)
        lcd.drawLine(x + p0_x, y + p0_y, x + p1_x, y + p1_y, SOLID, SOLID + GREY(5))
        lcd.drawLine(x + p0_x, y - p0_y, x + p1_x, y - p1_y, SOLID, SOLID + GREY(5))
        lcd.drawLine(x - p0_x, y + p0_y, x - p1_x, y + p1_y, SOLID, SOLID + GREY(5))
        lcd.drawLine(x - p0_x, y - p0_y, x - p1_x, y - p1_y, SOLID, SOLID + GREY(5))
        p0_x = p1_x
        p0_y = p1_y
    end
end

local _lm_x0 = 0
local _lm_y0 = 0
local _lm_x1 = 0
local _lm_y1 = 0
local function set_draw_limits(x0, y0, x1, y1)
    _lm_x0 = x0
    _lm_y0 = y0
    _lm_x1 = x1
    _lm_y1 = y1
end

local function get_draw_limits(x, y, alpha)
    if x < _lm_x0 then
        y = y + (_lm_x0 - x) * math.tan(math.rad(alpha))
        x = _lm_x0
    end
    if x > _lm_x1-1 then
        y = y - (x - _lm_x1+1) * math.tan(math.rad(alpha))
        x = _lm_x1-1
    end
    if y < _lm_y0 then
        x = x + (_lm_y0 - y) / math.tan(math.rad(alpha)) -- tan != 0
        y = _lm_y0
    end
    if y > _lm_y1-1 then
        x = x - (y - _lm_y1+1) / math.tan(math.rad(alpha)) -- tan != 0
        y = _lm_y1-1
    end
    return x, y
end

local function draw_ground(x0, y0, x1, y1)
    local b0_x = 0
    local b0_y = 0
    local b1_x = 0
    local b1_y = 0
    if x0 <= x1 and y0 <= y1 then
        -- XXX FIXME
        b0_x, b0_y = x0, y0
        b1_x, b1_y = x1, y1
    elseif x0 <= x1 and y0 > y1 then
        -- XXX FIXME
        b0_x, b0_y = x0, y1
        b1_x, b1_y = x1, y0
    elseif x0 > x1 and y0 <= y1 then
        -- XXX FIXME
    else
        -- XXX FIXME
        b0_x, b0_y = x0, y1
        b1_x, b1_y = x1, y0
    end
    for xi = b0_x, b1_x do
        local c = (y1 - y0) / (x1 - x0)
        local hi = math.floor((xi - b0_x) * c + 1)
        local yi = y0 + hi
        local syi = c < 0 and -hi or (b1_y - b0_y) - hi
        lcd.drawFilledRectangle(xi, yi, 1, syi, GREY(4), FORCE)
    end
    lcd.drawFilledRectangle(b0_x, b1_y, b1_x - b0_x + 1, _lm_y1 - b1_y + 1, GREY(4), FORCE)
    lcd.drawFilledRectangle(b1_x, b0_y, _lm_x1 - b1_x + 1,  b1_y - b0_y + 1, GREY(4), FORCE)
end

local function draw_angle(x, y, ro, alpha, ground)
    local p0_x = x - ro / 2 * math.cos(math.rad(alpha))
    local p0_y = y - ro / 2 * math.sin(math.rad(alpha))
    local p1_x = x + ro / 2 * math.cos(math.rad(alpha))
    local p1_y = y + ro / 2 * math.sin(math.rad(alpha))

    p0_x, p0_y = get_draw_limits(p0_x, p0_y, alpha)
    p1_x, p1_y = get_draw_limits(p1_x, p1_y, alpha)

    if ground then
        draw_ground(p0_x, p0_y, p1_x, p1_y)
    end
    lcd.drawLine(p0_x, p0_y, p1_x, p1_y, SOLID, FORCE)
end

local function draw_scale(x, y, w, h, value, mirror)
    lcd.drawLine(x, y, x, y-1 + SIZE_INSTRUMENTS_H, SOLID, FORCE)

    if mirror ~= -1 then
        mirror = 1
    end

    local value_mod = value % SCALE_STEP
    local value_round = value - value_mod
    local value_dy = value_mod * SCALE_SPACE / SCALE_STEP
    for i = -3, 3 do
        local value_n = value_round + i * SCALE_STEP
        local off_y = h / 2 - i * SCALE_SPACE + value_dy
        local off_x = mirror == 1 and 0 or w-1
        lcd.drawNumber(x + off_x, y + off_y - 3, value_n, 0)
        lcd.drawLine(x, y + off_y, x + 5 * mirror, y + off_y, SOLID, FORCE)
        lcd.drawLine(x, y + off_y + SCALE_SPACE/2, x + 3 * mirror, y + off_y + SCALE_SPACE/2, SOLID, FORCE)
    end

    if SCALE_SIZE == MIDSIZE then
        local off_x = mirror == 1 and 0 or w
        lcd.drawFilledRectangle(x - w + off_x, y + h / 2 - 7, w, 14, INVERS)
        lcd.drawNumber(x + off_x, y + h / 2 - 6, value, INVERS + MIDSIZE)
    else
        lcd.drawFilledRectangle(x - w, y + h / 2 - 6, w, 11, INVERS)
        lcd.drawNumber(x, y + h / 2 - 4, value, INVERS)
    end
end

local function draw_flightmode(x, y)
    local flightmode_attr = INVERS
    if not _apm_armed then
        flightmode_attr = flightmode_attr + BLINK
    end
    lcd.drawText(x + 1, y, FLIGHTMODES[_apm_flightmode + 1], flightmode_attr)
end

local _fps_time = getTime()
local function draw_fps(x, y)
    local ts = getTime()
    local dt = (ts - _fps_time) * 10
    if dt <= 0 then
        return
    end
    lcd.drawNumber(x, y, 1000 / dt, INVERS)
    _fps_time = ts
    lcd.drawText(x, y + 1, "Hz", SMLSIZE + INVERS)
end

local function draw_flighttimer(x, y)
    lcd.drawTimer(x, y, model.getTimer(0).value, INVERS)
end

local function draw_signaldb_icon(x, y, n)
    -- lcd.drawPixmap(x, y, "/SCRIPTS/BMP/sig1.bmp")
    if n < 0 then
        n = 0
    elseif n > ICO_SIGNALDB_N then
        n = ICO_SIGNALDB_N
    end
    for i = 1, n do
        lcd.drawFilledRectangle(x + 1 + 3 * (i-1), y + 1 + (5-i), 2, 1 + i, 0)
    end
    for i = n+1, ICO_SIGNALDB_N do
        lcd.drawFilledRectangle(x + 1 + 3 * (i-1), y + 1 + (5-i), 2, 1 + i, GREY(14))
    end
end

local function draw_signaldb(x, y)
    local low = 50
    local high = 99
    local step = (high - low) / ICO_SIGNALDB_N
    local n = math.ceil((getValue("RSSI") - low) / step)
    draw_signaldb_icon(x, y, n)
    lcd.drawNumber(x + 28, y, getValue("RSSI"), INVERS)
    lcd.drawText(lcd.getLastPos(), y + 1, "dB", SMLSIZE + INVERS)
end

local function draw_txvoltage_icon(x, y, n)
    -- lcd.drawPixmap(212 - 20, y, "/SCRIPTS/BMP/bat0.bmp")
    if n < 0 then
        n = 0
    elseif n > ICO_TXVOLTAGE_N then
        n = ICO_TXVOLTAGE_N
    end
    lcd.drawRectangle(x + 1, y + 1, 13, 6)
    lcd.drawLine(x + 14, y + 2, x + 14, y + 5, SOLID, 0)
    for i = 1, n do
        lcd.drawLine(x + 1 + 2 * i, y + 3, x + 1 + 2 * i, y + 4, SOLID, 0)
    end
end

local function draw_txvoltage(x, y)
    local step = (BATTERY_TX_HIGH - BATTERY_TX_LOW) / ICO_TXVOLTAGE_N
    local n = math.ceil((getValue("tx-voltage") - BATTERY_TX_LOW) / step)
    draw_txvoltage_icon(x, y, n)
    lcd.drawNumber(x + 30, y, getValue("tx-voltage") * 10, INVERS + PREC1)
    lcd.drawText(lcd.getLastPos(), y + 1, "V", SMLSIZE + INVERS)
end

local function draw_statusbar(x, y)
    lcd.drawFilledRectangle(x, y, SIZE_STATUSBAR_W, SIZE_STATUSBAR_H, FORCE)
    draw_flightmode(POS_FLIGHTMODE_X, y)
    draw_flighttimer(POS_FLIGHTTIMER_X, y)
    draw_signaldb(POS_SIGNALDB_X, y)
    draw_txvoltage(POS_TXVOLTAGE_X, y)
    draw_fps(POS_FPS_X, POS_FPS_Y)
end

local function draw_message(x, y)
    if _apm_msg.n > 0 then
        lcd.drawNumber(x - 1, y + 1, _apm_msg.n, 0)
    end
end

local function draw_airspeed(x, y)
    local airspeed = getValue("GSpd")
    if _unit_mode == UNIT_MODE_METRIC then
        airspeed = airspeed * 1.852
    end
    draw_scale(x, y, SIZE_AIRSPEED_W, SIZE_AIRSPEED_H, airspeed, 1)
    -- lcd.drawText(x + 1, y + 1, "kmh", SMLSIZE) -- XXX
end

local function draw_compass(x, y)
    -- XXX
end

local function draw_altimeter(x, y)
    local altitude = getValue("Alt")
    if _unit_mode == UNIT_MODE_IMPERIAL then
        altitude = altitude / 0.3048
    end
    draw_scale(x, y, SIZE_ALTIMETER_W, SIZE_ALTIMETER_H, altitude, -1)
    -- lcd.drawText(x + 1, y + 1, "m", SMLSIZE) -- XXX
end

local function draw_horizon(x, y)
    local roll = -convert_angle(getValue("A3"))
    local pitch = -convert_angle(getValue("A4"))
    -- draw_circle(x, y, 23)
    local r_x = 5 * math.sin(math.rad(roll))
    local r_y = -5 * math.cos(math.rad(roll))
    local p_x = 0.5 * pitch * math.sin(math.rad(roll))
    local p_y = -0.5 * pitch * math.cos(math.rad(roll))
    draw_angle(x + p_x, y + p_y, 2 * SIZE_HORIZON_W, roll, false) -- XXX
    for i = -8, 8, 2 do
        draw_angle(x + r_x * i + p_x, y + r_y * i + p_y, SIZE_HORIZON_W/20 * math.abs(i), roll)
    end
    lcd.drawLine(x - 2, y + 3, x, y, SOLID, SOLID)
    lcd.drawLine(x, y, x + 2, y + 3, SOLID, SOLID)
    lcd.drawNumber(x - 13, y + 20, roll, SMLSIZE + INVERS)
    lcd.drawNumber(x + 24, y + 20, -pitch, SMLSIZE + INVERS)
end

local function draw_instruments(x, y)
    lcd.drawLine(x-1 + SIZE_INSTRUMENTS_W, y, x-1 + SIZE_INSTRUMENTS_W, y-1 + SIZE_INSTRUMENTS_H, SOLID, 0)
    set_draw_limits(x + SIZE_AIRSPEED_W, y, x + SIZE_AIRSPEED_W + SIZE_HORIZON_W, y + SIZE_HORIZON_H)
    draw_horizon(x + POS_HORIZON_X, y + POS_HORIZON_Y)
    draw_airspeed(x + POS_AIRSPEED_X, y + POS_AIRSPEED_Y)
    draw_compass(x, y)
    draw_altimeter(x + POS_ALTIMETER_X, y + POS_ALTIMETER_Y)
end

local function draw_power_cells(x, y)
    lcd.drawLine(x, y-1 + SIZE_POWERBAR_H / 2, x + SIZE_POWERBAR_W - 1, y-1 + SIZE_POWERBAR_H / 2, SOLID, 0)
    local cell_x = x + SIZE_POWERBAR_W / 6.0
    local cell_all = getValue("Cels")
    if type(cell_all) ~= "table" then
        return
    end
    for i, cell_v in ipairs(cell_all) do
        lcd.drawLine(cell_x + 1, y, cell_x + 1, y-1 + SIZE_POWERBAR_H / 2, SOLID, SOLID)
        local cell_attr = PREC1
        if cell_v <= BATTERY_CELL_WARN then
            cell_attr = cell_attr + BLINK
        end
        lcd.drawNumber(cell_x - 2, y + 1, cell_v * 10, cell_attr)
        cell_x = cell_x + SIZE_POWERBAR_W / 6.0
    end
end

local function draw_power_gauge(x, y)
    local vfas = getValue("VFAS")
    local percent = (vfas - BATTERY_LOW) * 100.0 / (BATTERY_HIGH - BATTERY_LOW)
    if percent < 0 then
        percent = 0
    elseif percent > 100 then
        percent = 100
    end
    lcd.drawFilledRectangle(x, y, percent / 100.0 * SIZE_POWERBAR_W, SIZE_POWERBAR_H / 2)
    lcd.drawLine(x, y-1 + SIZE_POWERBAR_H/2, x-1 + SIZE_POWERBAR_W, y-1 + SIZE_POWERBAR_H/2, SOLID, SOLID)

    local limit_x = x + percent / 100.0 * SIZE_POWERBAR_W
    local v_x = limit_x - 8
    local v_attr = INVERS
    local p_x = limit_x + 13
    local p_attr = 0
    if percent < 22 then
        v_x = limit_x + 20
        v_attr = 0
        p_x = limit_x + 42
    elseif percent > 84 then
        v_x = limit_x - 30
        p_x = limit_x - 8
        p_attr = INVERS
    end
    lcd.drawNumber(v_x, y + 1, getValue("VFAS") * 10, v_attr + PREC1)
    lcd.drawText(v_x, y + 2, "V", v_attr + SMLSIZE)
    lcd.drawNumber(p_x, y + 1, percent, p_attr)
    lcd.drawText(p_x, y + 2, "%", p_attr + SMLSIZE)
end

local function draw_powerbar(x, y)
    draw_power_cells(x, y)
    draw_power_gauge(x, y + SIZE_POWERBAR_H / 2)
end

local function draw_vario_icon(x, y, vspd)
    if vspd < 0 then
        lcd.drawPixmap(x, y, "/SCRIPTS/BMP/arrowdown.bmp")
    elseif vspd > 0 then
        lcd.drawPixmap(x, y, "/SCRIPTS/BMP/arrowup.bmp")
    else
    end
end

local function draw_vario_vspeed(x, y)
    local vspd = getValue("VSpd")
    local legend = "ms"
    if _unit_mode == UNIT_MODE_IMPERIAL then
        vspd = vspd / 0.3048
        legend = "ft"
    end
    draw_vario_icon(x + 1, y + 3, vspd)
    if vspd > 10.0 or vspd < -10.0 then
        lcd.drawNumber(x + 28, y + 3, math.abs(vspd), MIDSIZE)
    else
        lcd.drawNumber(x + 28, y + 3, math.abs(vspd) * 10, MIDSIZE + PREC1)
    end
    lcd.drawText(x + 28, y + 8, legend, SMLSIZE)
end

local function draw_ground_speed(x, y)
    local gspd = getValue("GSpd")
    local legend = "ms"
    if _unit_mode == UNIT_MODE_METRIC then
        gspd = gspd * 1.852 / 3.6
    else
        gspd = gspd * 6076 / 3600
        legend = "ft"
    end
    lcd.drawNumber(x + 28, y + 3, gspd * 10, MIDSIZE + PREC1)
    lcd.drawText(x + 28, y + 8, legend, SMLSIZE)
end

local function draw_navbar_speed(x, y)
    lcd.drawLine(x + SIZE_SPEEDAREA_W, y, x + SIZE_SPEEDAREA_W, y-1 + SIZE_SPEEDAREA_H, SOLID, SOLID)
    draw_vario_vspeed(x, y)
    draw_ground_speed(x, y + SIZE_SPEEDAREA_H / 2)
end

local function draw_orientation_arrow(x, y)
    local shape_orientation_arrow = {
        {-8, 6, 0, -10},
        {-7, 6, 0, -9},
        {8, 6, 0, -10},
        {7, 6, 0, -9},
        {-8, 6, 0, 2},
        {-7, 6, 0, 3},
        {8, 6, 0, 2},
        {7, 6, 0, 3},
    }
    local hdg = getValue("Hdg")
    draw_shape(x, y, shape_orientation_arrow, gps_get_relative_hdg(hdg))
end

local function draw_move_direction(x, y)
    local size = 12
    local gspd = getValue("GSpd")
    -- draw_circle(x, y, size)
    local shape_move_arrow = {
        {0, -size - 0, 0, -size - 5},
        {0, -size - 5, 2, -size - 3},
        {0, -size - 5, -2, -size - 3},
    }
    if gspd > 0 then
        draw_shape(x, y, shape_move_arrow, gps_get_relative_hdg(_gps_speed.hdg))
    end
end

local function draw_navbar_heading(x, y)
    lcd.drawLine(x + SIZE_HEADINGAREA_W, y, x + SIZE_HEADINGAREA_W, y-1 + SIZE_SPEEDAREA_H, SOLID, SOLID)
    lcd.drawText(x-5 + SIZE_HEADINGAREA_W, y + 1, gps_get_mode(), SMLSIZE)
    local hdg_str = string.format("%02d", gps_get_relative_hdg(getValue("Hdg")) / 10)
    lcd.drawText(x + 2, y + 1, hdg_str, SMLSIZE)
    draw_orientation_arrow(x + SIZE_HEADINGAREA_W / 2, y + SIZE_SPEEDAREA_H / 2)
    draw_move_direction(x + SIZE_HEADINGAREA_W / 2, y + SIZE_SPEEDAREA_H / 2)
end

local function draw_gps_status(x, y)
    lcd.drawFilledRectangle(x + 1, y, SIZE_GPSBAR_W, SIZE_GPSBAR_H, 0, 0)
    local gps_fixattr = 0
    local gps_fixlabel = " No GPS "
    if _gps_fix.fixtype == 5 then
        gps_fixlabel = " GPS RT "
    elseif _gps_fix.fixtype == 4 then
        gps_fixlabel = " GPS DF "
    elseif _gps_fix.fixtype == 3 then
        gps_fixlabel = " GPS 3D "
    elseif _gps_fix.fixtype == 2 then
        gps_fixlabel = " GPS 2D "
    else
        gps_fixattr = BLINK
    end
    lcd.drawText(x + 4, y + 1, gps_fixlabel, INVERS + SMLSIZE + gps_fixattr)
end

local function draw_home_icon(x, y)
    lcd.drawPixmap(x, y, "/SCRIPTS/BMP/home.bmp")
end

local function draw_gps_distance(x, y)
    draw_home_icon(x + 2, y + 0)
    lcd.drawNumber(x + 28, y + 1, _gps_home.dst, 0)
    lcd.drawText(x + 29, y + 2, "m", SMLSIZE)
end

local function draw_gps_direction(x, y)
    local size = -8
    -- draw_circle(x, y, 8)
    local shape_move_arrow = {
        {0, -size - 0, 0, -size - 15},
        {0, -size - 15, 4, -size - 11},
        {0, -size - 15, -4, -size - 11},
    }
    local shape_no_move = {
        {0, -2, 0, 2},
        {-2, 0, 2, 0},
    }
    if _gps_home.dst > 0 then
        draw_shape(x, y, shape_move_arrow, gps_get_relative_hdg(_gps_radar.hdg))
    else
        draw_shape(x, y, shape_no_move, 0)
    end
end

local function draw_navbar_gps(x, y)
    lcd.drawLine(x + SIZE_GPSAREA_W, y, x + SIZE_GPSAREA_W, y-1 + SIZE_GPSAREA_H, SOLID, SOLID)
    draw_gps_status(x, y)
    draw_gps_direction(x+2 + SIZE_GPSAREA_W / 2, y + 5 + (SIZE_GPSAREA_H-SIZE_GPSBAR_H) / 2)
    lcd.drawNumber(x + 14, y + SIZE_GPSBAR_H + 1, _gps_fix.hdop * 10 , PREC1 + SMLSIZE)
    lcd.drawText(x-5 + SIZE_GPSAREA_W, y + SIZE_GPSBAR_H + 1, gps_get_mode(), SMLSIZE)
    draw_gps_distance(x + 2, y + SIZE_GPSAREA_H - 9)
end

local function draw_navbar(x, y)
    draw_navbar_speed(x, y)
    draw_navbar_heading(x + SIZE_SPEEDAREA_W, y)
    draw_navbar_gps(x + SIZE_SPEEDAREA_W + SIZE_HEADINGAREA_W, y)
end

local function background()
    process_gps()
    process_flightmode()
    process_voltage()
    process_messages()
end

local function run(event)
    lcd.clear()
    -- background() -- Auto call
    process_event(event)

    draw_instruments(0, SIZE_STATUSBAR_H)
    draw_powerbar(SIZE_INSTRUMENTS_W, SIZE_STATUSBAR_H)
    draw_navbar(SIZE_INSTRUMENTS_W, SIZE_STATUSBAR_H + SIZE_POWERBAR_H)
    draw_statusbar(0, 0)
    draw_message(SIZE_STATUSBAR_W, SIZE_STATUSBAR_H)
end

local function init()
    timer_reset()
end

return {init=init, run=run, background=background}
