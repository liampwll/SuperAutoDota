import vdf

out = {"DOTAHeroes": {}}
heroes = vdf.load(open('_from_dota_npc_heroes.txt'))
for k, v in heroes["DOTAHeroes"].items():
    if k == "Version" or k == "npc_dota_hero_base":
        continue
    out["DOTAHeroes"][k] = {}
    out["DOTAHeroes"][k]["Ability1"] = v["Ability1"] + " OR " + v["Ability2"] + " OR " + v["Ability3"] + " OR " + v["Ability4"] + " OR " + v["Ability5"] + " OR " + v["Ability6"]
    out["DOTAHeroes"][k]["Ability2"] = "sad_combine"
    out["DOTAHeroes"][k]["Ability3"] = "sad_sell"
    out["DOTAHeroes"][k]["SADCost"] = "0"
    for x in range(4, 40):
        if "Ability" + str(x) in v:
            out["DOTAHeroes"][k]["Ability" + str(x)] = "generic_hidden"
vdf.dump(out, open('_hero_templates.txt','w'), pretty=True)