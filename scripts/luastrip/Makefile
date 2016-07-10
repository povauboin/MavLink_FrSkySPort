PATH_TELEM=../../Lua_Telemetry/DisplayApmPosition/SCRIPTS/TELEMETRY/
HUD=hud.lua
HUDPY=hud.py.lua
HUDSML=hudsml.lua

all: wget strip diet

wget: LuaSrcDiet-0.11.2/LuaSrcDiet.lua

LuaSrcDiet-0.11.2/LuaSrcDiet.lua:
	wget http://files.luaforge.net/releases/luasrcdiet/luasrcdiet/LuaSrcDiet-0.11.2/LuaSrcDiet-0.11.2.tar.gz
	tar xf LuaSrcDiet-0.11.2.tar.gz

strip:
	python2 luastrip.py ${PATH_TELEM}${HUD} ${PATH_TELEM}${HUDPY}

diet:
	cd LuaSrcDiet-0.11.2 ;\
	lua5.1 ./LuaSrcDiet.lua --maximum ../${PATH_TELEM}${HUDPY} -o ../${PATH_TELEM}${HUDSML}
	rm ${PATH_TELEM}${HUDPY}
