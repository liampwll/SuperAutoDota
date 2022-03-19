import vdf

items = vdf.load(open('_from_dota_items.txt'))
for k, v in items["DOTAAbilities"].items():
    if k == "Version":
        continue
    print(k + "\t" + v["ItemCost"])
