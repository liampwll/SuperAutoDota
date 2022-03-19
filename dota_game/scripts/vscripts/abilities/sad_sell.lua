sad_sell = class({})

function sad_sell:OnSpellStart()
	local SAD = GameRules.SAD
	SAD:RemovePlayerHeroByID(self:GetCaster().ID)
	SAD:GameStateNettableSetAndPush({Gold = SAD.GameStateNettable.Gold + 1})
end
