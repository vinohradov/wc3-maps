// ===== Reforged: test commands (the original's -debug system was stripped from this release) =====
// Only work in test mode (Lx: exactly one human in the game; the map's anti-cheat is off then).
//   -debug      reveal the whole map
//   -gold X     set gold        -lumber X   set lumber
//   -level X    next wave becomes X (build phase only)
//   -start      start the next wave now (build phase only)
function Reforged_DebugCommand takes nothing returns nothing
local string msg=GetEventPlayerChatString()
local player who=GetTriggerPlayer()
local integer len=StringLength(msg)
local integer amount
if not Lx then
call DisplayTimedTextToPlayer(who,0,0,7.,"|cffFF0000Test commands only work when you are the only human player.|r")
set who=null
return
endif
if msg=="-debug" then
call FogEnable(false)
call FogMaskEnable(false)
call DisplayTimedTextToPlayer(who,0,0,15.,"|cffFFcc00Debug|r: map revealed. Commands: -gold X, -lumber X, -level X, -start")
elseif SubString(msg,0,6)=="-gold " then
set amount=S2I(SubString(msg,6,len))
call SetPlayerState(who,PLAYER_STATE_RESOURCE_GOLD,amount)
call DisplayTimedTextToPlayer(who,0,0,7.,"|cffFFcc00Debug|r: gold = "+I2S(amount))
elseif SubString(msg,0,8)=="-lumber " then
set amount=S2I(SubString(msg,8,len))
call SetPlayerState(who,PLAYER_STATE_RESOURCE_LUMBER,amount)
call DisplayTimedTextToPlayer(who,0,0,7.,"|cffFFcc00Debug|r: lumber = "+I2S(amount))
elseif SubString(msg,0,7)=="-level " then
set amount=S2I(SubString(msg,7,len))
if Vv or lr then
call DisplayTimedTextToPlayer(who,0,0,7.,"|cffFF0000-level only works between waves.|r")
elseif amount>=1 and amount<=30 then
set L=amount-1
call Reforged_UpdateShops()
call DisplayTimedTextToPlayer(who,0,0,7.,"|cffFFcc00Debug|r: next wave = "+I2S(amount))
endif
elseif msg=="-start" then
if Vv or lr then
call DisplayTimedTextToPlayer(who,0,0,7.,"|cffFF0000-start only works between waves.|r")
else
call StartTimerBJ(Q,false,1.)
endif
endif
set who=null
endfunction
function Reforged_InitDebug takes nothing returns nothing
local trigger t=CreateTrigger()
local integer i=0
loop
exitwhen i>7
call TriggerRegisterPlayerChatEvent(t,Player(i),"-debug",true)
call TriggerRegisterPlayerChatEvent(t,Player(i),"-start",true)
call TriggerRegisterPlayerChatEvent(t,Player(i),"-gold ",false)
call TriggerRegisterPlayerChatEvent(t,Player(i),"-lumber ",false)
call TriggerRegisterPlayerChatEvent(t,Player(i),"-level ",false)
set i=i+1
endloop
call TriggerAddAction(t,function Reforged_DebugCommand)
set t=null
endfunction
