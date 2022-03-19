let globalPanels = {};
let gameStateNettable = {};

let itemShop = {};
let heroShop = {};

class HeroShopItem {
    constructor(index) {
        this.index = index;
        this.panel = $.CreatePanel("Panel", globalPanels.heroShopPanel, "");
        this.panel.BLoadLayoutSnippet("HeroShopItem");
        this.panel.hittest = true;
        this.panel.SetPanelEvent(
            "onactivate",
            () => {
                GameEvents.SendCustomGameEventToServer("SADTryBuyHero", { "Index": this.index });
            }
        )
    }

    update(heroName, heroCost, abilityName, sold) {
        this.heroName = heroName;
        this.heroCost = heroCost;
        this.panel.FindChildTraverse("HeroImage").heroname = heroName;
        this.panel.FindChildTraverse("AbilityImage").abilityname = abilityName;
        this.panel.FindChildTraverse("HeroName").text = $.Localize("#" + heroName);
        this.panel.FindChildTraverse("HeroCost").text = "" + heroCost + " Gold";
        if (sold) {
            this.panel.enabled = false;
        } else {
            this.panel.enabled = true;
        }
    }
}

class ItemShopItem {
    constructor(index) {
        this.index = index;
        this.panel = $.CreatePanel("Panel", globalPanels.itemShopPanel, "");
        this.panel.BLoadLayoutSnippet("ItemShopItem");
        this.panel.hittest = true;
        this.panel.SetPanelEvent(
            "onactivate",
            () => {
                GameEvents.SendCustomGameEventToServer("SADTryBuyItem", { "Index": this.index });
            }
        )
    }

    update(itemName, itemCost, sold) {
        this.itemName = itemName;
        this.itemCost = itemCost;
        this.panel.FindChildTraverse("ItemImage").itemname = itemName;
        this.panel.FindChildTraverse("ItemName").text = $.Localize("#DOTA_Tooltip_Ability_" + itemName);
        this.panel.FindChildTraverse("ItemCost").text = "" + itemCost + " Gold";
        if (sold) {
            this.panel.enabled = false;
        } else {
            this.panel.enabled = true;
        }
    }
}

GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false);

function onGameStateNettableUpdate(tableName, key, data) {
    data = data["value"];
    //$.Msg(key + ": " + data);
    gameStateNettable[key] = data;
    switch (key) {
        case "IsLoaded":
        case "IsInMatch":
        case "OfflineMode":
            if (!gameStateNettable["IsLoaded"]) {
                globalPanels.mainMenuConnectingPanel.style.visibility = "visible";
                globalPanels.mainMenuPanel.style.visibility = "collapse";
                globalPanels.shopsPanel.style.visibility = "collapse";
            } else {
                globalPanels.mainMenuConnectingPanel.style.visibility = "collapse";
                if (gameStateNettable["OfflineMode"]) {
                    globalPanels.mainMenuPanel.style.visibility = "visible";
                    globalPanels.mainMenuOfflinePanel.style.visibility = "visible";
                    globalPanels.mainMenuOfflinePopupPanel.style.visibility = "visible";
                    globalPanels.mainMenuPanel.FindChild("ResumeSaved").enabled = false;
                }
                if (gameStateNettable["IsInMatch"]) {
                    globalPanels.shopsPanel.style.visibility = "visible";
                    globalPanels.mainMenuPanel.style.visibility = "collapse";
                } else {
                    globalPanels.mainMenuPanel.style.visibility = "collapse";
                    globalPanels.mainMenuPanel.style.visibility = "visible";
                }
            }
            break;
        case "ResumeAvailable":
            if (data) {
                globalPanels.mainMenuPanel.FindChild("ResumeSaved").enabled = true;
            } else {
                globalPanels.mainMenuPanel.FindChild("ResumeSaved").enabled = false;
            }
            break;
        case "IsBattleRunning":
            if (data || !gameStateNettable["IsInMatch"]) {
                globalPanels.shopsPanel.style.visibility = "collapse";
            } else {
                globalPanels.shopsPanel.style.visibility = "visible";
            }
            break;
        case "EnemyID":
            globalPanels.opponentPanel.steamid = data;
            break;
        case "Gold":
            globalPanels.goldPanel.text = "Gold: " + data;
            break;
        case "Life":
            globalPanels.lifePanel.text = "Life: " + data;
            break;
        case "Round":
            globalPanels.roundPanel.text = "Round: " + data;
            break;
        case "UnitsInArena":
        case "MaxUnitsInArena":
            globalPanels.unitPanel.text = "Units in arena: " + gameStateNettable["UnitsInArena"] + "/" + gameStateNettable["MaxUnitsInArena"];
            break;
        case "HeroShop":
            for (const [k, v] of Object.entries(data)) {
                heroShop[parseInt(k)].update(v["Name"], v["Cost"], v["Ability"], v["IsSold"]);
            }
            break;
        case "ItemShop":
            for (const [k, v] of Object.entries(data)) {
                itemShop[parseInt(k)].update(v["Name"], v["Cost"], v["IsSold"]);
            }
            break;
    }
}

function setup() {
    if (!Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_STRATEGY_TIME)) {
        $.Schedule(1.0, setup);
    } else {
        GameUI.SetCameraTargetPosition([0, -200, 0], 1);
        globalPanels.basePanel = $.GetContextPanel();
        globalPanels.shopsPanel = globalPanels.basePanel.FindChild("Shops");
        globalPanels.heroShopPanel = globalPanels.shopsPanel.FindChild("HeroShop");
        globalPanels.itemShopPanel = globalPanels.shopsPanel.FindChild("ItemShop");
        globalPanels.goldPanel = globalPanels.shopsPanel.FindChild("Gold");
        globalPanels.opponentPanel = globalPanels.shopsPanel.FindChild("Opponent");
        globalPanels.lifePanel = globalPanels.shopsPanel.FindChild("Life");
        globalPanels.roundPanel = globalPanels.shopsPanel.FindChild("Round");
        globalPanels.unitPanel = globalPanels.shopsPanel.FindChild("UnitCount");
        globalPanels.opponentPanel = globalPanels.shopsPanel.FindChild("OpponentName");
        globalPanels.startBattlePanel = globalPanels.shopsPanel.FindChild("StartBattle");
        globalPanels.mainMenuPanel = globalPanels.basePanel.FindChild("MainMenu");
        globalPanels.mainMenuOfflinePopupPanel = globalPanels.basePanel.FindChild("MainMenuOfflinePopup");
        globalPanels.mainMenuOfflinePanel = globalPanels.mainMenuPanel.FindChild("MainMenuOfflineMode");
        globalPanels.mainMenuConnectingPanel = globalPanels.basePanel.FindChild("MainMenuConnecting");
        globalPanels.mainMenuConnectingPanel.style.visibility = "visible";
        globalPanels.mainMenuPanel.style.visibility = "collapse";
        globalPanels.mainMenuOfflinePanel.style.visibility = "collapse";
        globalPanels.shopsPanel.style.visibility = "collapse";
        globalPanels.mainMenuOfflinePopupPanel.style.visibility = "collapse";
        $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("inventory_list2").style.visibility = "collapse";
        $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("inventory_slot_1").style.visibility = "collapse";
        $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("inventory_slot_2").style.visibility = "collapse";
        $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("inventory_backpack_list").style.visibility = "collapse";
        $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("inventory_composition_layer_container").style.visibility = "collapse";

        for (let i = 1; i <= 5; i++) {
            heroShop[i] = new HeroShopItem(i);
        }

        for (let i = 1; i <= 3; i++) {
            itemShop[i] = new ItemShopItem(i);
        }

        CustomNetTables.SubscribeNetTableListener("GameState", onGameStateNettableUpdate);

        for (const [k, v] of Object.entries(CustomNetTables.GetAllTableValues("GameState"))) {
            onGameStateNettableUpdate("GameState", k, v);
        }
    }
}

setup();
