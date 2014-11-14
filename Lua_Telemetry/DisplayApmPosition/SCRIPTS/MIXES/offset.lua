local inputs = { {"O-SET mAh% ", VALUE,-100,100,0}, {"O-SET Wh%", VALUE, -100, 100, 0}}

local oldoffsetmah=0
local oldoffsetwatth=0

local function run_func(offsetmah, offsetwatth)
  if oldoffsetmah ~= offsetmah or oldoffsetwatth ~= offsetwatth then
    model.setGlobalVariable(8, 0, offsetmah) --mA/h
    model.setGlobalVariable(8, 1, offsetwatth) --Wh
    oldoffsetmah = offsetmah
    oldoffsetwatth = offsetwatth
  end

end

return {run=run_func, input=inputs}