// ===== Reforged: computer players (lobby "Computer" slots 1-8) =====
// Difficulty from the lobby: Easy = random and slow, Normal = plays properly but unoptimized,
// Insane = best value per gold, keeps army just above a target that adapts to its own leaks,
// and puts the rest into income (wisps, lumber research, summons).
// Bots build and upgrade with real orders (so the map's gold anti-cheat stays happy) and send
// summons by paying lumber and creating the unit, which the normal purchase trigger (EG) handles.
function Reforged_IsBotPlayer takes player p returns boolean
return GetPlayerId(p)<8 and GetPlayerController(p)==MAP_CONTROL_COMPUTER and GetPlayerSlotState(p)==PLAYER_SLOT_STATE_PLAYING
endfunction
function Reforged_CountHumansInGame takes nothing returns integer
local integer i=0
local integer n=0
loop
exitwhen i>7
if GetPlayerController(Player(i))==MAP_CONTROL_USER and GetPlayerSlotState(Player(i))==PLAYER_SLOT_STATE_PLAYING then
set n=n+1
endif
set i=i+1
endloop
return n
endfunction
function Reforged_BotBuilderIndex takes integer t returns integer
local integer k=0
loop
exitwhen k>=Reforged_BotBuilderCount
if Reforged_BotBuilder[k]==t then
return k
endif
set k=k+1
endloop
return -1
endfunction
function Reforged_BotFindUnit takes player p,integer t1,integer t2 returns unit
local group g=CreateGroup()
local unit u
set Reforged_BotFound=null
call GroupEnumUnitsOfPlayer(g,p,null)
loop
set u=FirstOfGroup(g)
exitwhen u==null
if Reforged_BotFound==null and GetWidgetLife(u)>0.405 and (GetUnitTypeId(u)==t1 or GetUnitTypeId(u)==t2) then
set Reforged_BotFound=u
endif
call GroupRemoveUnit(g,u)
endloop
call DestroyGroup(g)
set g=null
return Reforged_BotFound
endfunction
// army value the bot wants before investing in income (Insane only)
function Reforged_BotTarget takes integer pid returns integer
local integer n=L+1
return R2I(Reforged_BotRatio[pid]*I2R(200+60*n+4*n*n))
endfunction
function Reforged_BotSpotFree takes real x,real y returns boolean
local group g=CreateGroup()
local unit u
local boolean free=true
call GroupEnumUnitsInRange(g,x,y,100.,null)
loop
set u=FirstOfGroup(g)
exitwhen u==null
if IsUnitType(u,UNIT_TYPE_STRUCTURE) then
set free=false
endif
call GroupRemoveUnit(g,u)
endloop
call DestroyGroup(g)
set g=null
return free
endfunction
// ---- picking a builder
function Reforged_BotIsPicker takes integer t returns boolean
return t=='e000' or t=='e002' or t=='e004' or t=='e005' or t=='e006' or t=='e007'
endfunction
function Reforged_BotPick takes integer pid returns nothing
local unit b=N[pid+1]
if Reforged_BotDiff[pid]==2 and GetRandomInt(0,1)==0 then
call IssueImmediateOrderById(b,'u00T')
else
call IssueImmediateOrderById(b,Reforged_BotBuilder[GetRandomInt(0,Reforged_BotBuilderCount-1)])
endif
set b=null
endfunction
// ---- building on a grid around the lane centre (11 columns x 15 rows, 128 apart)
function Reforged_BotTryBuild takes integer pid,integer i returns boolean
local unit b=N[pid+1]
local player p=Player(pid)
local integer s
local integer r
local real x
local real y
loop
set s=Reforged_BotSlot[pid]
exitwhen s>=165
set r=s/11
set x=GetPlayerStartLocationX(p)+I2R(ModuloInteger(s,11)-5)*128.
if ModuloInteger(r,2)==1 then
set y=GetPlayerStartLocationY(p)+I2R((r+1)/2)*128.
else
set y=GetPlayerStartLocationY(p)-I2R(r/2)*128.
endif
set Reforged_BotSlot[pid]=s+1
if Reforged_BotSpotFree(x,y) then
if IssueBuildOrderById(b,Reforged_BotUnit[i],x,y) then
set b=null
return true
endif
// free spot but refused: probably a tech requirement -> skip this unit for the rest of the level
set Reforged_BotBlocked[pid*600+i]=L+1
set Reforged_BotSlot[pid]=s
set b=null
return false
endif
endloop
set b=null
return false
endfunction
// best (Insane) or random affordable unit of the bot's builder; -1 if none
function Reforged_BotChooseBuild takes integer pid,integer gold returns integer
local player p=Player(pid)
local integer k=Reforged_BotBuilderIndex(GetUnitTypeId(N[pid+1]))
local integer i
local integer pick=-1
local integer best=0
local integer n=0
local integer v
if k<0 then
return -1
endif
set i=Reforged_BotBStart[k]
loop
exitwhen i>Reforged_BotBEnd[k]
if Reforged_BotCost[i]<=gold and Reforged_BotBlocked[pid*600+i]!=L+1 and GetPlayerTechMaxAllowed(p,Reforged_BotUnit[i])!=0 then
if Reforged_BotDiff[pid]==2 then
set v=Reforged_BotScore[i]*1000/Reforged_BotCost[i]
if v>best then
set best=v
set pick=i
endif
else
set n=n+1
if GetRandomInt(1,n)==1 then
set pick=i
endif
endif
endif
set i=i+1
endloop
set Reforged_BotPickValue=best
return pick
endfunction
// best (Insane) or random affordable upgrade among the bot's towers; sets Reforged_BotUpUnit / returns index or -1
function Reforged_BotChooseUpgrade takes integer pid,integer gold returns integer
local player p=Player(pid)
local group g=CreateGroup()
local unit u
local integer j
local integer t
local integer pick=-1
local integer best=0
local integer n=0
local integer v
set Reforged_BotUpUnit=null
call GroupEnumUnitsOfPlayer(g,p,null)
loop
set u=FirstOfGroup(g)
exitwhen u==null
if GetWidgetLife(u)>0.405 and IsUnitType(u,UNIT_TYPE_STRUCTURE) and not IsUnitInGroup(u,zx) and not IsUnitInGroup(u,Zx) then
set t=GetUnitTypeId(u)
set j=0
loop
exitwhen j>=Reforged_BotUpCount
if Reforged_BotUpFrom[j]==t and Reforged_BotUpCost[j]<=gold and GetPlayerTechMaxAllowed(p,Reforged_BotUpTo[j])!=0 then
if Reforged_BotDiff[pid]==2 then
set v=Reforged_BotUpGain[j]*1000/Reforged_BotUpCost[j]
if v>best then
set best=v
set pick=j
set Reforged_BotUpUnit=u
endif
else
set n=n+1
if GetRandomInt(1,n)==1 then
set pick=j
set Reforged_BotUpUnit=u
endif
endif
endif
set j=j+1
endloop
endif
call GroupRemoveUnit(g,u)
endloop
call DestroyGroup(g)
set g=null
set Reforged_BotPickValue=best
return pick
endfunction
// spend gold on army once; returns true if an order was given
function Reforged_BotArmy takes integer pid,integer gold,boolean allowUpgrades returns boolean
local integer bi=Reforged_BotChooseBuild(pid,gold)
local integer bv=Reforged_BotPickValue
local integer ui=-1
local integer uv2=0
local boolean idle=GetUnitCurrentOrder(N[pid+1])==0
if allowUpgrades then
set ui=Reforged_BotChooseUpgrade(pid,gold)
set uv2=Reforged_BotPickValue
endif
if ui>=0 and (bi<0 or not idle or (Reforged_BotDiff[pid]==2 and uv2>=bv) or (Reforged_BotDiff[pid]!=2 and GetRandomInt(0,1)==0)) then
return IssueImmediateOrderById(Reforged_BotUpUnit,Reforged_BotUpTo[ui])
endif
if bi>=0 and idle then
return Reforged_BotTryBuild(pid,bi)
endif
return false
endfunction
// ---- income
function Reforged_BotIncome takes integer pid,integer gold,integer maxWisps,boolean research returns boolean
local player p=Player(pid)
local unit town=Reforged_BotFindUnit(p,'h023',0)
local boolean done=false
if town!=null then
if Qx[pid+1]<maxWisps and gold>=50 then
set done=IssueImmediateOrderById(town,'e003')
endif
if not done and research then
set done=IssueImmediateOrderById(town,'R003')
if not done then
set done=IssueImmediateOrderById(town,'R00H')
endif
endif
endif
set town=null
return done
endfunction
// ---- sending summons during a wave (they join the next wave)
function Reforged_BotSend takes integer pid,integer reserve returns nothing
local player p=Player(pid)
local integer lumber=GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER)-reserve
local unit shop=Reforged_BotFindUnit(p,'h05C','h9B0')
local integer st=0
local integer at=GetUnitTypeId(Vr[pid+1])
local integer i=0
local integer pick=-1
local integer n=0
if shop!=null then
set st=GetUnitTypeId(shop)
endif
loop
exitwhen i>=Reforged_BotSumCount
if (Reforged_BotSumShop[i]==st or Reforged_BotSumShop[i]==at) and Reforged_BotSumCost[i]<=lumber then
if Reforged_BotDiff[pid]==2 then
if pick<0 or Reforged_BotSumCost[i]>Reforged_BotSumCost[pick] then
set pick=i
endif
else
set n=n+1
if GetRandomInt(1,n)==1 then
set pick=i
endif
endif
endif
set i=i+1
endloop
if pick>=0 and shop!=null then
call AdjustPlayerStateBJ(-Reforged_BotSumCost[pick],p,PLAYER_STATE_RESOURCE_LUMBER)
call CreateUnit(p,Reforged_BotSumUnit[pick],GetUnitX(shop),GetUnitY(shop)-200.,270.)
endif
set shop=null
endfunction
// ---- one decision per bot per tick
function Reforged_BotThink takes integer pid returns nothing
local player p=Player(pid)
local integer gold=GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)
local integer d=Reforged_BotDiff[pid]
if N[pid+1]==null then
return
endif
if Reforged_BotIsPicker(GetUnitTypeId(N[pid+1])) then
call Reforged_BotPick(pid)
return
endif
if Reforged_BotBuilderIndex(GetUnitTypeId(N[pid+1]))<0 then
return
endif
if Vv then
// wave running: send summons
if not Reforged_IsNoSendWave(L+1) then
if d==2 then
call Reforged_BotSend(pid,120)
elseif d==1 and GetRandomInt(1,4)==1 and GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER)>=150 then
call Reforged_BotSend(pid,0)
endif
endif
return
endif
if lr then
return
endif
// new build phase: Insane adapts its target to last wave's leaks
if Reforged_BotLastLevel[pid]!=L then
set Reforged_BotLastLevel[pid]=L
if co[pid+1]>Reforged_BotLastLeak[pid] then
set Reforged_BotRatio[pid]=RMinBJ(Reforged_BotRatio[pid]*1.3,4.)
elseif L>0 then
set Reforged_BotRatio[pid]=RMaxBJ(Reforged_BotRatio[pid]*0.93,0.6)
endif
set Reforged_BotLastLeak[pid]=co[pid+1]
endif
if d==0 then
if GetRandomInt(0,1)==0 then
call Reforged_BotArmy(pid,gold*7/10,L>=5)
endif
elseif d==1 then
if L>=2 and GetRandomInt(1,5)==1 and Reforged_BotIncome(pid,gold,4,false) then
return
endif
call Reforged_BotArmy(pid,gold,true)
else
if Bo[pid+1]>=Reforged_BotTarget(pid) and Reforged_BotIncome(pid,gold,9,true) then
return
endif
call Reforged_BotArmy(pid,gold,true)
endif
endfunction
function Reforged_BotTick takes nothing returns nothing
local integer pid=0
loop
exitwhen pid>7
if Reforged_IsBot[pid] and GetPlayerSlotState(Player(pid))==PLAYER_SLOT_STATE_PLAYING then
call Reforged_BotThink(pid)
endif
set pid=pid+1
endloop
endfunction
function Reforged_InitBots takes nothing returns nothing
local integer pid=0
local trigger t
local aidifficulty a
call Reforged_BotData()
loop
exitwhen pid>7
if Reforged_IsBotPlayer(Player(pid)) then
set Reforged_IsBot[pid]=true
set Reforged_HasBots=true
set a=GetAIDifficulty(Player(pid))
if a==AI_DIFFICULTY_INSANE then
set Reforged_BotDiff[pid]=2
elseif a==AI_DIFFICULTY_NORMAL then
set Reforged_BotDiff[pid]=1
else
set Reforged_BotDiff[pid]=0
endif
set Reforged_BotRatio[pid]=1.
set Reforged_BotLastLevel[pid]=-1
endif
set pid=pid+1
endloop
if Reforged_HasBots then
set t=CreateTrigger()
call TriggerRegisterTimerEvent(t,1.,true)
call TriggerAddAction(t,function Reforged_BotTick)
set t=null
call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS,15.,"|cffFFcc00Bots in game|r: this game is not ranked (no win/loss stats).")
endif
set a=null
endfunction
