// ===== Reforged: computer players (lobby "Computer" slots 1-8) =====
// Difficulty from the lobby: Easy = random and slow, Normal = plays properly but unoptimized,
// Insane = best value per gold, keeps army just above a target that adapts to its own leaks,
// and puts the rest into income (wisps, lumber research, summons).
// Bots build and upgrade with real orders (so the map's gold anti-cheat stays happy) and send
// summons by paying lumber and creating the unit, which the normal purchase trigger (EG) handles.
// No new globals: state and data live in Reforged_HT (keys listed after endglobals).
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
local integer n=Reforged_HTI(21,0)
loop
exitwhen k>=n
if Reforged_HTI(8,k)==t then
return k
endif
set k=k+1
endloop
return -1
endfunction
function Reforged_BotFindUnit takes player p,integer t1,integer t2 returns unit
local group g=CreateGroup()
local unit u
local unit found=null
call GroupEnumUnitsOfPlayer(g,p,null)
loop
set u=FirstOfGroup(g)
exitwhen u==null
if found==null and GetWidgetLife(u)>0.405 and (GetUnitTypeId(u)==t1 or GetUnitTypeId(u)==t2) then
set found=u
endif
call GroupRemoveUnit(g,u)
endloop
call DestroyGroup(g)
set g=null
call SaveUnitHandle(Reforged_HT,22,0,found)
set found=null
return LoadUnitHandle(Reforged_HT,22,0)
endfunction
// army value the bot wants before investing in income (Insane only)
function Reforged_BotTarget takes integer pid returns integer
local integer n=L+1
return R2I(Reforged_HTR(3,pid)*I2R(200+60*n+4*n*n))
endfunction
function Reforged_BotSpotFree takes real posX,real posY returns boolean
local group g=CreateGroup()
local unit u
local boolean free=true
call GroupEnumUnitsInRange(g,posX,posY,100.,null)
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
if Reforged_HTI(2,pid)==2 and GetRandomInt(0,1)==0 then
call IssueImmediateOrderById(b,'u00T')
else
call IssueImmediateOrderById(b,Reforged_HTI(8,GetRandomInt(0,Reforged_HTI(21,0)-1)))
endif
set b=null
endfunction
// ---- building on a grid around the lane centre (11 columns x 15 rows, 128 apart)
function Reforged_BotTryBuild takes integer pid,integer i returns boolean
local unit b=N[pid+1]
local player p=Player(pid)
local integer s
local integer r
local real posX
local real posY
loop
set s=Reforged_HTI(4,pid)
exitwhen s>=165
set r=s/11
set posX=GetPlayerStartLocationX(p)+I2R(ModuloInteger(s,11)-5)*128.
if ModuloInteger(r,2)==1 then
set posY=GetPlayerStartLocationY(p)+I2R((r+1)/2)*128.
else
set posY=GetPlayerStartLocationY(p)-I2R(r/2)*128.
endif
call Reforged_HTSetI(4,pid,s+1)
if Reforged_BotSpotFree(posX,posY) then
if IssueBuildOrderById(b,Reforged_HTI(11,i),posX,posY) then
set b=null
return true
endif
// free spot but refused: probably a tech requirement -> skip this unit for the rest of the level
call Reforged_HTSetI(7,pid*600+i,L+1)
call Reforged_HTSetI(4,pid,s)
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
local integer last
local integer pick=-1
local integer best=0
local integer n=0
local integer v
local integer cost
call Reforged_HTSetI(21,4,0)
if k<0 then
return -1
endif
set i=Reforged_HTI(9,k)
set last=Reforged_HTI(10,k)
loop
exitwhen i>last
set cost=Reforged_HTI(12,i)
if cost<=gold and Reforged_HTI(7,pid*600+i)!=L+1 and GetPlayerTechMaxAllowed(p,Reforged_HTI(11,i))!=0 then
if Reforged_HTI(2,pid)==2 then
set v=Reforged_HTI(13,i)*1000/cost
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
call Reforged_HTSetI(21,4,best)
return pick
endfunction
// best (Insane) or random affordable upgrade among the bot's towers; stores the tower in HT(22,1); index or -1
function Reforged_BotChooseUpgrade takes integer pid,integer gold returns integer
local player p=Player(pid)
local group g=CreateGroup()
local unit u
local unit chosen=null
local integer j
local integer t
local integer pick=-1
local integer best=0
local integer n=0
local integer v
local integer cnt=Reforged_HTI(21,1)
local integer cost
call GroupEnumUnitsOfPlayer(g,p,null)
loop
set u=FirstOfGroup(g)
exitwhen u==null
if GetWidgetLife(u)>0.405 and IsUnitType(u,UNIT_TYPE_STRUCTURE) and not IsUnitInGroup(u,zx) and not IsUnitInGroup(u,Zx) then
set t=GetUnitTypeId(u)
set j=0
loop
exitwhen j>=cnt
if Reforged_HTI(14,j)==t then
set cost=Reforged_HTI(16,j)
if cost<=gold and GetPlayerTechMaxAllowed(p,Reforged_HTI(15,j))!=0 then
if Reforged_HTI(2,pid)==2 then
set v=Reforged_HTI(17,j)*1000/cost
if v>best then
set best=v
set pick=j
set chosen=u
endif
else
set n=n+1
if GetRandomInt(1,n)==1 then
set pick=j
set chosen=u
endif
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
call SaveUnitHandle(Reforged_HT,22,1,chosen)
set chosen=null
call Reforged_HTSetI(21,4,best)
return pick
endfunction
// spend gold on army once; returns true if an order was given
function Reforged_BotArmy takes integer pid,integer gold,boolean allowUpgrades returns boolean
local integer buildIdx=Reforged_BotChooseBuild(pid,gold)
local integer buildVal=Reforged_HTI(21,4)
local integer upIdx=-1
local integer upVal=0
local boolean idle=GetUnitCurrentOrder(N[pid+1])==0
local integer d=Reforged_HTI(2,pid)
if allowUpgrades then
set upIdx=Reforged_BotChooseUpgrade(pid,gold)
set upVal=Reforged_HTI(21,4)
endif
if upIdx>=0 and (buildIdx<0 or not idle or (d==2 and upVal>=buildVal) or (d!=2 and GetRandomInt(0,1)==0)) then
return IssueImmediateOrderById(LoadUnitHandle(Reforged_HT,22,1),Reforged_HTI(15,upIdx))
endif
if buildIdx>=0 and idle then
return Reforged_BotTryBuild(pid,buildIdx)
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
local unit shop=Reforged_BotFindUnit(p,'h05C','h9B1')
local integer st=0
local integer lt=0
local integer at=GetUnitTypeId(Vr[pid+1])
local integer i=0
local integer cnt=Reforged_HTI(21,2)
local integer pick=-1
local integer n=0
local integer sh
if shop!=null then
set st=GetUnitTypeId(shop)
endif
if L>=20 then
set lt='h9B0'
endif
loop
exitwhen i>=cnt
set sh=Reforged_HTI(18,i)
if (sh==st or sh==at or sh==lt) and Reforged_HTI(20,i)<=lumber then
if Reforged_HTI(2,pid)==2 then
if pick<0 or Reforged_HTI(20,i)>Reforged_HTI(20,pick) then
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
call AdjustPlayerStateBJ(-Reforged_HTI(20,pick),p,PLAYER_STATE_RESOURCE_LUMBER)
call CreateUnit(p,Reforged_HTI(19,pick),GetUnitX(shop),GetUnitY(shop)-200.,270.)
endif
set shop=null
endfunction
// ---- one decision per bot per tick
function Reforged_BotThink takes integer pid returns nothing
local player p=Player(pid)
local integer gold=GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)
local integer d=Reforged_HTI(2,pid)
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
if Reforged_HTI(6,pid)!=L then
call Reforged_HTSetI(6,pid,L)
if co[pid+1]>Reforged_HTI(5,pid) then
call Reforged_HTSetR(3,pid,RMinBJ(Reforged_HTR(3,pid)*1.3,4.))
elseif L>0 then
call Reforged_HTSetR(3,pid,RMaxBJ(Reforged_HTR(3,pid)*0.93,0.6))
endif
call Reforged_HTSetI(5,pid,co[pid+1])
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
if Reforged_IsBot(pid) and GetPlayerSlotState(Player(pid))==PLAYER_SLOT_STATE_PLAYING then
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
call Reforged_HTSetI(1,pid,1)
call Reforged_HTSetI(21,3,1)
set a=GetAIDifficulty(Player(pid))
if a==AI_DIFFICULTY_INSANE then
call Reforged_HTSetI(2,pid,2)
elseif a==AI_DIFFICULTY_NORMAL then
call Reforged_HTSetI(2,pid,1)
else
call Reforged_HTSetI(2,pid,0)
endif
call Reforged_HTSetR(3,pid,1.)
call Reforged_HTSetI(6,pid,-1)
endif
set pid=pid+1
endloop
if Reforged_HasBots() then
set t=CreateTrigger()
call TriggerRegisterTimerEvent(t,1.,true)
call TriggerAddAction(t,function Reforged_BotTick)
set t=null
call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS,15.,"|cffFFcc00Bots in game|r: this game is not ranked (no win/loss stats).")
endif
set a=null
endfunction
