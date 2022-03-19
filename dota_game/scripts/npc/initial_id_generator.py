import vdf

heroes = vdf.load(open('_from_dota_npc_heroes.txt'))
items = vdf.load(open('_from_dota_items.txt'))
id_string = ["A", "a"]
print("SAD.SerializeIDToNameLookups = {")
for k, v in list(heroes["DOTAHeroes"].items()) + list(items["DOTAAbilities"].items()):
    print(f"\t{id_string[0]}{id_string[1]} = \"{k}\",")
    if id_string[1] == "z":
        id_string[1] = "A"
    elif id_string[1] == "Z":
        id_string[0] = chr(ord(id_string[0]) + 1)
        id_string[1] = "a"
    elif id_string[0] == "Z":
        print("TOO MANY STRINGS")
        exit()
    else:
        id_string[1] = chr(ord(id_string[1]) + 1)
print("}\n")

id_string = ["A", "a"]
print("SAD.SerializeNameToIDLookups = {")
for k, v in list(heroes["DOTAHeroes"].items()) + list(items["DOTAAbilities"].items()):
    print(f"\t[\"{k}\"] = \"{id_string[0]}{id_string[1]}\",")
    if id_string[1] == "z":
        id_string[1] = "A"
    elif id_string[1] == "Z":
        id_string[0] = chr(ord(id_string[0]) + 1)
        id_string[1] = "a"
    elif id_string[0] == "Z":
        print("TOO MANY STRINGS")
        exit()
    else:
        id_string[1] = chr(ord(id_string[1]) + 1)
print("}")
