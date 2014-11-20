local inputs = { {"O-SET mAh% ", VALUE,-100,100,0}, {"O-SET Wh%", VALUE, -100, 100, 0}, {"BatCap Wh", VALUE, 0, 250, 30} }

local oldoffsetmah=0
local oldoffsetwatth=0
local oldbatcapa=0

local function run_func(offsetmah, offsetwatth, batcapa)
  if oldoffsetmah ~= offsetmah or oldoffsetwatth ~= offsetwatth or oldbatcapa~=batcapa then
    model.setGlobalVariable(8, 0, offsetmah) --mA/h
    model.setGlobalVariable(8, 1, offsetwatth) --Wh
    model.setGlobalVariable(8, 2, batcapa) --Wh
    oldoffsetmah = offsetmah
    oldoffsetwatth = offsetwatth
    oldbatcapa = batcapa
  end

end

return {run=run_func, input=inputs}