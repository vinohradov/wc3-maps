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
// army value Insane wants before investing in income: table HT(41,level) x its leak-adaptive ratio
function Reforged_BotTarget takes integer pid returns integer
local integer lvl=L+1
if lvl>30 then
set lvl=30
endif
return R2I(Reforged_HTR(3,pid)*I2R(Reforged_HTI(41,lvl)))
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
// ---- matchups: damage table HT(30, atk*8+def) in percent; next wave's types HT(31/32, level)
function Reforged_BotMatchup takes integer unitAtk,integer unitDef returns integer
local integer lvl=L+1
local integer dealt
local integer taken
if lvl>30 then
set lvl=30
endif
set dealt=Reforged_HTI(30,unitAtk*8+Reforged_HTI(32,lvl))
set taken=Reforged_HTI(30,Reforged_HTI(31,lvl)*8+unitDef)
return dealt*(200-taken)/100
endfunction
// ---- placement: melee rows in front (towards the creep spawn), ranged rows behind them by about their range.
// Even player ids have creeps coming from the north, odd ids from the south. 13 rows x 11 columns, 128 apart.
function Reforged_BotTryBuild takes integer pid,integer i returns boolean
local unit b=N[pid+1]
local player p=Player(pid)
local integer range=Reforged_HTI(26,i)
local integer row=0
local integer col
local integer off
local real dir=1.
local real posX
local real posY
if ModuloInteger(pid,2)==1 then
set dir=-1.
endif
if range>=200 then
set row=(range-100)/128
if row<2 then
set row=2
endif
if row>8 then
set row=8
endif
endif
loop
exitwhen row>12
set posY=GetPlayerStartLocationY(p)+dir*(512.-128.*I2R(row))
set col=0
loop
exitwhen col>10
if ModuloInteger(col,2)==1 then
set off=(col+1)/2
else
set off=-col/2
endif
set posX=GetPlayerStartLocationX(p)+128.*I2R(off)
if Reforged_BotSpotFree(posX,posY) then
if IssueBuildOrderById(b,Reforged_HTI(11,i),posX,posY) then
if range>=200 then
call Reforged_HTSetI(28,pid,Reforged_HTI(28,pid)+Reforged_HTI(12,i))
else
call Reforged_HTSetI(27,pid,Reforged_HTI(27,pid)+Reforged_HTI(12,i))
endif
set b=null
return true
endif
// free spot but refused: probably a tech requirement -> skip this unit for the rest of the level
call Reforged_HTSetI(7,pid*600+i,L+1)
set b=null
return false
endif
set col=col+1
endloop
set row=row+1
endloop
set b=null
return false
endfunction
// Pick a unit to build. Easy: random. Normal: random among the good ones (>=70% of the best value vs the next
// wave), keeping gold split about evenly between melee and ranged. Insane: the best one.
function Reforged_BotChooseBuild takes integer pid,integer gold returns integer
local player p=Player(pid)
local integer k=Reforged_BotBuilderIndex(GetUnitTypeId(N[pid+1]))
local integer d=Reforged_HTI(2,pid)
local boolean wantRanged=Reforged_HTI(28,pid)<Reforged_HTI(27,pid)
local integer pass=0
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
set last=Reforged_HTI(10,k)
// pass 0: find the best value (wanted class only, unless Easy); pass 1: choose
loop
exitwhen pass>1
set i=Reforged_HTI(9,k)
loop
exitwhen i>last
set cost=Reforged_HTI(12,i)
if cost<=gold and Reforged_HTI(7,pid*600+i)!=L+1 and GetPlayerTechMaxAllowed(p,Reforged_HTI(11,i))!=0 then
if d==0 or (Reforged_HTI(26,i)>=200)==wantRanged or best==0 then
set v=Reforged_HTI(13,i)*10*Reforged_BotMatchup(Reforged_HTI(33,i),Reforged_HTI(34,i))/cost
if pass==0 then
if (d==0 or (Reforged_HTI(26,i)>=200)==wantRanged) and v>best then
set best=v
endif
elseif d==2 then
if pick<0 or v>n then
set n=v
set pick=i
endif
elseif d==0 or v*10>=best*7 then
set n=n+1
if GetRandomInt(1,n)==1 then
set pick=i
endif
endif
endif
endif
set i=i+1
endloop
set pass=pass+1
endloop
if d==2 then
call Reforged_HTSetI(21,4,n)
else
call Reforged_HTSetI(21,4,best)
endif
return pick
endfunction
// best (Insane) or random good (Normal) / any (Easy) upgrade among the bot's towers; tower goes to HT(22,1)
function Reforged_BotChooseUpgrade takes integer pid,integer gold returns integer
local player p=Player(pid)
local group g=CreateGroup()
local unit u
local unit chosen=null
local integer d=Reforged_HTI(2,pid)
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
set v=Reforged_HTI(17,j)*10*Reforged_BotMatchup(Reforged_HTI(35,j),Reforged_HTI(36,j))/cost
if d==0 then
set n=n+1
if GetRandomInt(1,n)==1 then
set pick=j
set chosen=u
endif
elseif v>best then
set best=v
set pick=j
set chosen=u
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
if upIdx>=0 and (buildIdx<0 or not idle or (d!=0 and upVal>=buildVal) or (d==0 and GetRandomInt(0,1)==0)) then
if IssueImmediateOrderById(LoadUnitHandle(Reforged_HT,22,1),Reforged_HTI(15,upIdx)) then
if Reforged_HTI(29,upIdx)==1 then
call Reforged_HTSetI(28,pid,Reforged_HTI(28,pid)+Reforged_HTI(16,upIdx))
else
call Reforged_HTSetI(27,pid,Reforged_HTI(27,pid)+Reforged_HTI(16,upIdx))
endif
return true
endif
return false
endif
if buildIdx>=0 and idle then
return Reforged_BotTryBuild(pid,buildIdx)
endif
return false
endfunction
// ---- Insane: mass one proven "core" unit (HT 43-45). Returns true if an order was given.
function Reforged_BotCoreIndex takes integer pid,integer baseType returns integer
local integer k=Reforged_BotBuilderIndex(GetUnitTypeId(N[pid+1]))
local integer i
local integer last
if k<0 then
return -1
endif
set i=Reforged_HTI(9,k)
set last=Reforged_HTI(10,k)
loop
exitwhen i>last
if Reforged_HTI(11,i)==baseType and GetPlayerTechMaxAllowed(Player(pid),baseType)!=0 then
return i
endif
set i=i+1
endloop
return -1
endfunction
function Reforged_BotPickCore takes integer pid returns nothing
local integer c=0
local integer cnt=Reforged_HTI(21,5)
local integer n=0
local integer pick=-1
loop
exitwhen c>=cnt
if Reforged_BotCoreIndex(pid,Reforged_HTI(43,c))>=0 then
set n=n+1
if GetRandomInt(1,n)==1 then
set pick=c
endif
endif
set c=c+1
endloop
if pick>=0 then
call Reforged_HTSetI(42,pid,pick+1)
else
call Reforged_HTSetI(42,pid,-1)
endif
endfunction
function Reforged_BotCoreArmy takes integer pid,integer gold returns boolean
local player p=Player(pid)
local integer core=Reforged_HTI(42,pid)
local group g
local unit u
local integer j
local integer t
local integer cnt=Reforged_HTI(21,1)
local integer unitIdx
local boolean done=false
if core==0 then
call Reforged_BotPickCore(pid)
set core=Reforged_HTI(42,pid)
endif
if core<0 then
return false
endif
// carry cores: once more gold sits in ranged than in melee, let the general logic add melee tanks
if Reforged_HTI(44,core-1)==2 and Reforged_HTI(28,pid)>Reforged_HTI(27,pid) then
return false
endif
// upgrades of core units: always for upgrade-first cores, from level 6 for mass/carry cores
if Reforged_HTI(44,core-1)==1 or L>=5 then
set g=CreateGroup()
call GroupEnumUnitsOfPlayer(g,p,null)
loop
set u=FirstOfGroup(g)
exitwhen u==null
if not done and GetWidgetLife(u)>0.405 and Reforged_HTI(45,GetUnitTypeId(u))==core and not IsUnitInGroup(u,zx) and not IsUnitInGroup(u,Zx) then
set t=GetUnitTypeId(u)
set j=0
loop
exitwhen j>=cnt or done
if Reforged_HTI(14,j)==t and Reforged_HTI(45,Reforged_HTI(15,j))==core and Reforged_HTI(16,j)<=gold then
set done=IssueImmediateOrderById(u,Reforged_HTI(15,j))
endif
set j=j+1
endloop
endif
call GroupRemoveUnit(g,u)
endloop
call DestroyGroup(g)
set g=null
if done then
return true
endif
endif
set unitIdx=Reforged_BotCoreIndex(pid,Reforged_HTI(43,core-1))
if unitIdx>=0 and Reforged_HTI(12,unitIdx)<=gold and GetUnitCurrentOrder(N[pid+1])==0 then
return Reforged_BotTryBuild(pid,unitIdx)
endif
return false
endfunction
// ---- Insane: aura supports (HT 46-52). Built behind the melee rows: first at column -3, second at +3
// (6 squares apart for slow auras), third in the middle. Returns true if an order was given.
function Reforged_BotBuildAt takes integer pid,integer i,integer off returns boolean
local player p=Player(pid)
local real dir=1.
local integer row=2
local real posX=GetPlayerStartLocationX(p)+128.*I2R(off)
local real posY
if ModuloInteger(pid,2)==1 then
set dir=-1.
endif
loop
exitwhen row>6
set posY=GetPlayerStartLocationY(p)+dir*(512.-128.*I2R(row))
if Reforged_BotSpotFree(posX,posY) then
return IssueBuildOrderById(N[pid+1],Reforged_HTI(11,i),posX,posY)
endif
set row=row+1
endloop
return false
endfunction
function Reforged_BotSupport takes integer pid,integer gold returns boolean
local player p=Player(pid)
local integer s=0
local integer cnt=Reforged_HTI(21,6)
local integer ups=Reforged_HTI(21,1)
local integer unitIdx
local integer nBase
local integer nFinal
local integer j
local integer off
local group g
local unit u
local unit baseUnit
local boolean done=false
loop
exitwhen s>=cnt or done
set unitIdx=Reforged_BotCoreIndex(pid,Reforged_HTI(46,s))
if unitIdx>=0 and Bo[pid+1]>=Reforged_HTI(50,s) and (Reforged_HTI(52,s)==0 or Reforged_HTI(28,pid)*2>=Reforged_HTI(27,pid)) then
set nBase=0
set nFinal=0
set baseUnit=null
set g=CreateGroup()
call GroupEnumUnitsOfPlayer(g,p,null)
loop
set u=FirstOfGroup(g)
exitwhen u==null
if GetWidgetLife(u)>0.405 and Reforged_HTI(51,GetUnitTypeId(u))==s+1 then
if GetUnitTypeId(u)==Reforged_HTI(47,s) then
set nFinal=nFinal+1
else
set nBase=nBase+1
if not IsUnitInGroup(u,zx) and not IsUnitInGroup(u,Zx) then
set baseUnit=u
endif
endif
endif
call GroupRemoveUnit(g,u)
endloop
call DestroyGroup(g)
set g=null
if nBase+nFinal<Reforged_HTI(48,s) then
if Reforged_HTI(12,unitIdx)<=gold and GetUnitCurrentOrder(N[pid+1])==0 then
set off=0
if nBase+nFinal==0 then
set off=-3
elseif nBase+nFinal==1 then
set off=3
endif
set done=Reforged_BotBuildAt(pid,unitIdx,off)
endif
elseif nFinal<Reforged_HTI(49,s) and baseUnit!=null then
set j=0
loop
exitwhen j>=ups or done
if Reforged_HTI(14,j)==Reforged_HTI(46,s) and Reforged_HTI(15,j)==Reforged_HTI(47,s) and Reforged_HTI(16,j)<=gold then
set done=IssueImmediateOrderById(baseUnit,Reforged_HTI(15,j))
endif
set j=j+1
endloop
endif
set baseUnit=null
endif
set s=s+1
endloop
return done
endfunction
// ---- income: wisps (max 9) and Lumberjack research R003, up to the given caps
function Reforged_BotIncome takes integer pid,integer gold,integer maxWisps,integer maxResearch returns boolean
local player p=Player(pid)
local unit town=Reforged_BotFindUnit(p,'h023',0)
local integer wisps=Qx[pid+1]
local integer res=GetPlayerTechCountSimple('R003',p)
local boolean done=false
if town!=null then
if wisps<maxWisps and gold>=50 and (wisps<5 or wisps-5<=res or res>=maxResearch) then
set done=IssueImmediateOrderById(town,'e003')
endif
if not done and res<maxResearch then
set done=IssueImmediateOrderById(town,'R003')
endif
if not done and wisps<maxWisps and gold>=50 then
set done=IssueImmediateOrderById(town,'e003')
endif
endif
set town=null
return done
endfunction
// ---- sends: counter the most common armor type among the enemy team's towers, never trash units
function Reforged_BotEnemyArmor takes integer pid returns integer
local group g=CreateGroup()
local unit u
local integer e=0
local integer a
local integer best=7
local integer bestCount=0
local integer array tally
loop
exitwhen e>7
if IsPlayerEnemy(Player(e),Player(pid)) and GetPlayerSlotState(Player(e))==PLAYER_SLOT_STATE_PLAYING then
call GroupEnumUnitsOfPlayer(g,Player(e),null)
loop
set u=FirstOfGroup(g)
exitwhen u==null
set a=Reforged_HTI(38,GetUnitTypeId(u))
if a>0 then
set tally[a-1]=tally[a-1]+1
if tally[a-1]>bestCount then
set bestCount=tally[a-1]
set best=a-1
endif
endif
call GroupRemoveUnit(g,u)
endloop
endif
set e=e+1
endloop
call DestroyGroup(g)
set g=null
return best
endfunction
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
local integer best=0
local integer sh
local integer v
local integer minCost=10*(L+1)
local integer armor
if minCost>600 then
set minCost=600
endif
if shop==null or lumber<minCost or lumber<40 then
set shop=null
return
endif
set st=GetUnitTypeId(shop)
if L>=20 then
set lt='h9B0'
endif
set armor=Reforged_BotEnemyArmor(pid)
loop
exitwhen i>=cnt
set sh=Reforged_HTI(18,i)
if (sh==st or sh==at or sh==lt) and Reforged_HTI(20,i)<=lumber and Reforged_HTI(20,i)>=minCost then
// counter factor first, then the most expensive
set v=Reforged_HTI(30,Reforged_HTI(39,i)*8+armor)*10000+Reforged_HTI(20,i)
if v>best then
set best=v
set pick=i
endif
endif
set i=i+1
endloop
if pick>=0 then
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
local integer next=L+1
local integer res
local integer allowance
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
// wave running: send summons (they join the next wave); keep lumber for the next Lumberjack research
if d!=0 and not Reforged_IsNoSendWave(next) then
set res=GetPlayerTechCountSimple('R003',p)
if res<7 then
call Reforged_BotSend(pid,60+20*(res+1))
else
call Reforged_BotSend(pid,0)
endif
endif
return
endif
if lr then
return
endif
// new build phase: remember whether the last wave leaked
if Reforged_HTI(6,pid)!=L then
call Reforged_HTSetI(6,pid,L)
call Reforged_HTSetI(37,pid,0)
if co[pid+1]>Reforged_HTI(5,pid) then
call Reforged_HTSetI(40,pid,1)
call Reforged_HTSetR(3,pid,RMinBJ(Reforged_HTR(3,pid)*1.3,4.))
else
call Reforged_HTSetI(40,pid,0)
if L>0 then
call Reforged_HTSetR(3,pid,RMaxBJ(Reforged_HTR(3,pid)*0.95,0.7))
endif
endif
call Reforged_HTSetI(5,pid,co[pid+1])
endif
if d==0 then
if GetRandomInt(0,1)==0 then
call Reforged_BotArmy(pid,gold*7/10,L>=5)
endif
elseif d==1 then
// Normal economy: level 1 all-in on defense; no income spending before the hard levels 5 and 7 or after a
// leak; 9 wisps / research 4 until level 7, then up to 9 / 7 while it holds. Everything else goes to defense.
set allowance=0
if next>=2 and next!=5 and next!=7 and Reforged_HTI(40,pid)==0 then
if next<=4 then
set allowance=1
else
set allowance=3
endif
endif
if Reforged_HTI(37,pid)<allowance then
if next<=7 then
set res=4
else
set res=7
endif
if Reforged_BotIncome(pid,gold,9,res) then
call Reforged_HTSetI(37,pid,Reforged_HTI(37,pid)+1)
return
endif
endif
call Reforged_BotArmy(pid,gold,true)
else
// Insane: army value just above the (leak-adaptive) target, everything else into income
if Reforged_BotSupport(pid,gold) then
return
endif
if Bo[pid+1]>=Reforged_BotTarget(pid) then
if Reforged_BotIncome(pid,gold,9,8) then
return
endif
// income maxed or not affordable: keep the gold unless it piles up
if gold<600 then
return
endif
endif
if not Reforged_BotCoreArmy(pid,gold) then
// no core unit available for this builder, or out of room: general best-value logic
if Reforged_HTI(42,pid)<0 or gold>=300 or Reforged_HTI(44,Reforged_HTI(42,pid)-1)==2 then
call Reforged_BotArmy(pid,gold,true)
endif
endif
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
