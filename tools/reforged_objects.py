"""Reforged object data: Legendary Barracks (from wave 20) and its 6 summons + their abilities.

Idempotent: clones templates on first run, then (re)applies every field below.
  uv run python tools/reforged_objects.py
Conventions kept from the map: summon lumber cost = level * 20 (the no-send refund relies on it),
income ("points") ~ 5% of lumber cost.
"""
from objlib import Slk, Txt, move_new_sections

# how this map displays internal armor types in tooltips ("large" is shown as Heavy, "normal" as Fortified)
ARMOR_NAME = {"small": "Light", "medium": "Medium", "large": "Heavy", "normal": "Fortified", "fort": "Fortified",
              "none": "Unarmored", "hero": "Hero", "divine": "Divine"}
UNIT_SLKS = ["UnitBalance.slk", "UnitData.slk", "UnitWeapons.slk", "UnitAbilities.slk", "unitUI.slk"]
ICON = "ReplaceableTextures\\CommandButtons\\"
AURA_TARGETS_ALLY = "air,ground,friend,self,vuln,invu"
AURA_TARGETS_ENEMY = "air,ground,enemy,vuln,invu"

# ---------------------------------------------------------------- abilities (template -> new id)
ABILITIES = {
    "A9A0": ("AOae", "Infernal Endurance", "BTNPitLord", {"Area1": 900, "DataA1": 0.15, "DataB1": 0.15},
             "Nearby allied attackers move and attack 15% faster."),
    "A9A1": ("AHad", "Void Aura", "BTNFacelessOne", {"Area1": 900, "DataA1": -4, "targs1": AURA_TARGETS_ENEMY},
             "Nearby defenders have 4 less armor."),
    "A9A2": ("Afbk", "Mind Devour", "BTNFacelessOne", {"DataA1": 30},
             "Each attack burns 30 mana."),
    "A9A3": ("AEah", "Carapace Aura", "BTNHeroCryptLord", {"Area1": 900, "DataA1": 0.2},
             "Nearby allied attackers return 20% of melee damage taken."),
    "A9A4": ("AOae", "Nether Frost", "BTNNetherDragon",
             {"Area1": 900, "DataA1": -0.2, "DataB1": -0.2, "targs1": AURA_TARGETS_ENEMY},
             "Nearby defenders move and attack 20% slower."),
    "A9A5": ("ACac", "Command of the Legion", "BTNEredarRed", {"Area1": 900, "DataA1": 0.2},
             "Nearby allied attackers deal 20% more damage."),
    "A9A6": ("ANpi", "Fel Fire", "BTNEredarRed", {"Area1": 300, "DataA1": 25},
             "Burns nearby defenders for 25 damage per second."),
    "A9A7": ("AHad", "Legion Aura", "BTNMannoroth", {"Area1": 900, "DataA1": 5},
             "Nearby allied attackers have 5 more armor."),
    "A9A8": ("AUau", "Legion Vigor", "BTNMannoroth", {"Area1": 900, "DataA1": 0, "DataB1": 20},
             "Nearby allied attackers regenerate 20 HP per second."),
    "A9A9": ("AOre", "Undying", "BTNMannoroth", {"DataA1": 3, "Cool1": 999},
             "Revives once at full HP 3 seconds after dying."),
}

# ---------------------------------------------------------------- summons (template: Demon h0BR)
MELEE = {"weapTp1": "normal", "rangeN1": 128, "RngBuff1": 250}
SPLASH_CLEAVE = {"weapTp1": "msplash", "Farea1": 1, "Harea1": 200, "Hfact1": 0.3, "Qarea1": 250, "Qfact1": 0.15,
                 "splashTargs1": "enemies,ground"}
SPLASH_BREATH = {"weapTp1": "msplash", "Farea1": 50, "Harea1": 120, "Hfact1": 0.5, "Qarea1": 180, "Qfact1": 0.25,
                 "splashTargs1": "enemies,ground"}

SUMMONS = [
    # id, name, hotkey, pos, lumber, hp, armor, defType, atkType, dmg+, dice, sides, cool, weapon, model, scale, icon,
    # abilities, missile, flavour
    ("h9A0", "Pit Lord", "Q", "0,0", 500, 1500, 4, "large", "normal", 105, 2, 10, 1.0, {**MELEE, **SPLASH_CLEAVE},
     "units\\demon\\PitLord\\PitLord.mdl", 1.0, "BTNPitLord", ["A9A0"], None,
     "Brutal demon lord whose cleaving blows hit everything around him."),
    ("h9A1", "Faceless One", "W", "1,0", 750, 2100, 4, "medium", "magic", 125, 2, 10, 0.9, MELEE,
     "Units\\Creeps\\FacelessOne\\FacelessOne.mdl", 1.2, "BTNFacelessOne", ["A9A1", "A9A2"], None,
     "Horror from the void that strips defenders of their armor."),
    ("h9A2", "Anub'arak", "E", "2,0", 1000, 2800, 9, "large", "normal", 150, 2, 10, 1.0, MELEE,
     "Units\\Undead\\Anubarak\\Anubarak.mdl", 1.4, "BTNHeroCryptLord", ["A9A3"], None,
     "Ancient crypt lord with a spiked shell that punishes melee defenders."),
    ("h9A3", "Nether Dragon", "R", "3,0", 1500, 3300, 4, "normal", "magic", 180, 2, 10, 1.1,
     {"rangeN1": 450, **SPLASH_BREATH},
     "Units\\Creeps\\NetherDragon\\NetherDragon.mdl", 0.9, "BTNNetherDragon", ["A9A4"],
     "Abilities\\Weapons\\GreenDragonMissile\\GreenDragonMissile.mdl",
     "Its nether breath splashes defenders and chills everyone nearby."),
    ("h9A4", "Eredar Warlock", "A", "0,1", 2000, 4200, 5, "medium", "chaos", 240, 2, 10, 1.0,
     {"weapTp1": "missile", "rangeN1": 600},
     "Units\\Demon\\EredarWarlock\\EredarWarlock.mdl", 1.4, "BTNEredarRed", ["A9A5", "A9A6"],
     "Abilities\\Weapons\\FireBallMissile\\FireBallMissile.mdl",
     "Warlock of the Burning Legion; empowers attackers and burns defenders."),
    ("h9A5", "Mannoroth", "S", "1,1", 3000, 6000, 8, "large", "chaos", 330, 3, 10, 0.9, MELEE,
     "Units\\Demon\\Mannoroth\\Mannoroth.mdl", 1.0, "BTNMannoroth", ["A9A7", "A9A8", "A9A9"], None,
     "The Destructor. Shields and heals the whole wave, and rises again once."),
]

BARRACKS = "h9B0"
LOCKED_BARRACKS = "h9B1"  # h05C twin selling max-stock-0 copies (h9D0..) on no-send levels
LOCKED_LEGENDARY = "h9B2"  # h9B0 twin selling max-stock-0 copies (h9E0..)

# ---------------------------------------------------------------- Challenge (sold in each player's Town, h023)
CHALLENGE = "h9C0"  # dummy "unit" bought from the Town; the script removes it and toggles the challenge
CHALLENGE_ACTIVE = "h9C1"  # same, shown instead of h9C0 while a challenge is queued (click = cancel)
CHAMPION_AURAS = {  # one is picked at random for each Champion
    "A9B0": ("AHad", "Champion: Shatter", "BTNHelmutPurple",
             {"Area1": 700, "DataA1": -3, "targs1": AURA_TARGETS_ENEMY}, "Nearby defenders have 3 less armor."),
    "A9B1": ("AOae", "Champion: Frenzy", "BTNHelmutPurple", {"Area1": 700, "DataA1": 0.1, "DataB1": 0.1},
             "Nearby attackers move and attack 10% faster."),
    "A9B2": ("AEah", "Champion: Spikes", "BTNHelmutPurple", {"Area1": 700, "DataA1": 0.25},
             "Nearby attackers return 25% of melee damage taken."),
}
# hidden +max HP abilities in binary steps (A9C0 = +100 ... A9C9 = +51200); the script adds a subset
HP_ABILITIES = {f"A9C{i}": 100 * 2 ** i for i in range(10)}


def ability_text(aid):
    return ABILITIES[aid][1]


# The game reads each profile .txt into a 512 KB buffer; CampaignUnitFunc.txt was ~508 KB already and our
# additions overflowed it (crash on map select). So all new [h9xx]/[A9xx] sections live in two small files that
# the game also reads: Units\CampaignUnitStrings.txt and Units\CampaignAbilityFunc.txt.
UNIT_EXTRA = "CampaignUnitStrings.txt"
ABIL_EXTRA = "CampaignAbilityFunc.txt"


def main():
    ad, astr = Slk("AbilityData.slk"), Txt("CampaignAbilityStrings.txt")
    move_new_sections(Txt(ABIL_EXTRA), astr)
    for aid, (tpl, name, icon, fields, tip) in ABILITIES.items():
        ad.clone(tpl, aid)
        ad.set(aid, "levels", 1)
        for k, v in fields.items():
            ad.set(aid, k, v)
        astr.clone(tpl, aid)
        for k, v in {"Name": name, "Tip": name, "Ubertip": f'"{tip}"', "Art": ICON + icon + ".blp",
                     "Researchtip": "", "Researchubertip": ""}.items():
            astr.set(aid, k, v)
    ad.save()
    astr.save()

    slks = {n: Slk(n) for n in UNIT_SLKS}
    func = Txt("CampaignUnitFunc.txt")
    move_new_sections(Txt(UNIT_EXTRA), func)
    for (uid, name, hotkey, pos, lumber, hp, armor, dtype, atype, dmg, dice, sides, cool, weapon, model, scale,
         icon, abils, missile, flavour) in SUMMONS:
        for s in slks.values():
            s.clone("h0BR", uid)
        b, d, w, a, ui = (slks[n] for n in UNIT_SLKS)
        income = lumber * 5 // 100
        for k, v in {"level": lumber // 20, "lumbercost": lumber, "HP": hp, "def": armor, "realdef": armor,
                     "defType": dtype}.items():
            b.set(uid, k, v)
        d.set(uid, "points", income)
        for k, v in {"atkType1": atype, "dmgplus1": dmg, "dice1": dice, "sides1": sides, "cool1": cool,
                     **weapon}.items():
            w.set(uid, k, v)
        a.set(uid, "abilList", ",".join(abils))
        for k, v in {"file": model, "modelScale": scale, "scale": 1.5, "name": f"reforged_{uid}"}.items():
            ui.set(uid, k, v)
        func.clone("h0BR", uid)
        abil_lines = "".join(f"|n|cff33BBBB{ability_text(x)}|r: {ABILITIES[x][4]}" for x in abils)
        atk = "Ranged" if weapon.get("rangeN1", 128) > 200 else "Melee"
        for k, v in {"Name": name, "Hotkey": hotkey, "Buttonpos": pos, "Requires": "",
                     "Tip": f"Summon {name} (|cffFFcc00{hotkey}|r)",
                     "Ubertip": f'"{flavour}|n|n|cffFFcc00+{income} income|r|n|cffCCCCCC{atk}, '
                                f'{atype.capitalize()} damage, {ARMOR_NAME[dtype]} armor.|r{abil_lines}"',
                     "Art": ICON + icon + ".blp", "Missileart": missile or ""}.items():
            func.set(uid, k, v)

    # Legendary Barracks: clone of the cheap Barracks h05C, swapped in at wave 20 by the script
    for s in slks.values():
        if "h05C" in s.rows:
            s.clone("h05C", BARRACKS)
    slks["unitUI.slk"].set(BARRACKS, "file", "Buildings\\Demon\\DemonGate\\DemonGate.mdl")
    slks["unitUI.slk"].set(BARRACKS, "modelScale", 0.4)
    slks["unitUI.slk"].set(BARRACKS, "name", f"reforged_{BARRACKS}")
    func.clone("h05C", BARRACKS)
    func.set(BARRACKS, "Name", "Legendary Barracks")
    func.set(BARRACKS, "Art", ICON + "BTNMannoroth.blp")
    func.set(BARRACKS, "Sellunits", ",".join(s[0] for s in SUMMONS))
    # Locked shops for no-send levels (like the map's own h05D): same buttons, but every unit has max stock 0
    func.set(BARRACKS, "Sellunits", ",".join(s[0] for s in SUMMONS))
    for shop, locked_shop, prefix in (("h05C", LOCKED_BARRACKS, "h9D"), (BARRACKS, LOCKED_LEGENDARY, "h9E")):
        s0, e0 = func._section(shop)
        sells = next(l for l in func.lines[s0:e0] if l.startswith("Sellunits=")).split("=", 1)[1].split(",")
        locked_ids = []
        for i, src in enumerate(sells):
            lid = f"{prefix}{'0123456789ABCDEF'[i]}"
            locked_ids.append(lid)
            for s in slks.values():
                if src in s.rows:
                    s.clone(src, lid)
            slks["UnitBalance.slk"].set(lid, "stockMax", 0)
            slks["unitUI.slk"].set(lid, "name", f"reforged_{lid}")
            func.clone(src, lid)
            t0, t1 = func._section(src)
            tip = next((l.split("=", 1)[1] for l in func.lines[t0:t1] if l.startswith("Tip=")), "")
            uber = next((l.split("=", 1)[1] for l in func.lines[t0:t1] if l.startswith("Ubertip=")), None)
            if uber is not None:
                func.set(lid, "Ubertip", uber)
            note = "(from level 21; locked on boss levels)" if prefix == "h9E" else "(locked this level)"
            func.set(lid, "Tip", tip + " |cffFF0000" + note + "|r")
        for s in slks.values():
            if shop in s.rows:
                s.clone(shop, locked_shop)
        slks["unitUI.slk"].set(locked_shop, "name", f"reforged_{locked_shop}")
        func.clone(shop, locked_shop)
        func.set(locked_shop, "Sellunits", ",".join(locked_ids))

    # Challenge: clone of the King HP upgrade u008 (type "undead", so the summon purchase trigger ignores it)
    for s in slks.values():
        if "u008" in s.rows:
            s.clone("u008", CHALLENGE)
    for k, v in {"lumbercost": 0, "stockMax": 1, "stockRegen": 1}.items():
        slks["UnitBalance.slk"].set(CHALLENGE, k, v)
    slks["unitUI.slk"].set(CHALLENGE, "name", f"reforged_{CHALLENGE}")
    func.clone("u008", CHALLENGE)
    for k, v in {"Name": "Challenge", "Hotkey": "C", "Buttonpos": "3,0",
                 "Tip": "|cffFFcc00C|rhallenge the next wave",
                 "Ubertip": '"One creep of your next wave becomes a Champion: 10x HP, bigger, with a random aura.'
                            '|n|nKill it for |cffFFcc00(wave+1) x 15|r gold +|cffFFcc0010|r per streak. '
                            'A leak resets the streak.|n|nBuy again before the wave to cancel. '
                            'Not available for levels 10, 20, 30."',
                 "Art": ICON + "BTNHelmutPurple.blp"}.items():
        func.set(CHALLENGE, k, v)
    for s in slks.values():
        if CHALLENGE in s.rows:
            s.clone(CHALLENGE, CHALLENGE_ACTIVE)
    slks["unitUI.slk"].set(CHALLENGE_ACTIVE, "name", f"reforged_{CHALLENGE_ACTIVE}")
    func.clone(CHALLENGE, CHALLENGE_ACTIVE)
    for k, v in {"Name": "Challenge: ACTIVE", "Buttonpos": "3,1",
                 "Tip": "|cff00ff00Challenge ACTIVE|r - click to |cffFF0000cancel|r",
                 "Ubertip": '"Your next wave will contain a |cffFF4040Champion|r (10x HP, aura, marked with a red ring).'
                            '|n|nKill it for |cffFFcc00(wave+1) x 15|r gold +|cffFFcc0010|r per streak.'
                            '|n|nClick to cancel the challenge."',
                 "Art": ICON + "BTNSacrifice.blp"}.items():
        func.set(CHALLENGE_ACTIVE, k, v)
    func.set("h023", "Sellunits", "u008,u009,u00A," + CHALLENGE + "," + CHALLENGE_ACTIVE)

    ad, astr = Slk("AbilityData.slk"), Txt("CampaignAbilityStrings.txt")
    for aid, (tpl, name, icon, fields, tip) in CHAMPION_AURAS.items():
        ad.clone(tpl, aid)
        ad.set(aid, "levels", 1)
        for k, v in fields.items():
            ad.set(aid, k, v)
        astr.clone(tpl, aid)
        for k, v in {"Name": name, "Tip": name, "Ubertip": f'"{tip}"', "Art": ICON + icon + ".blp"}.items():
            astr.set(aid, k, v)
    for aid, amount in HP_ABILITIES.items():
        ad.clone("AIl2", aid)  # AIml: max life bonus while the unit has the ability
        ad.set(aid, "levels", 1)
        ad.set(aid, "DataA1", amount)
    ad.save()
    abil_extra = Txt(ABIL_EXTRA)
    moved_a = move_new_sections(astr, abil_extra)
    astr.save()
    abil_extra.save()

    for s in slks.values():
        s.save()
    unit_extra = Txt(UNIT_EXTRA)
    moved_u = move_new_sections(func, unit_extra)
    func.save()
    unit_extra.save()
    print(f"moved {moved_u} unit / {moved_a} ability sections into {UNIT_EXTRA} / {ABIL_EXTRA}")
    print("ok:", ", ".join(ABILITIES), "|", ", ".join(s[0] for s in SUMMONS), "|", BARRACKS, CHALLENGE,
          "|", ", ".join(CHAMPION_AURAS), ", ".join(HP_ABILITIES))


if __name__ == "__main__":
    main()
