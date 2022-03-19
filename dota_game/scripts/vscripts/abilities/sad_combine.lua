sad_combine = class({})

function sad_combine:OnSpellStart()
	local SAD = GameRules.SAD
	for I = 2, SAD.LevelsPerStar do
		self:GetCursorTarget():HeroLevelUp(false)
	end
	self:GetCursorTarget():HeroLevelUp(true)
	self:GetCursorTarget():SetAbilityPoints(0)
	self:GetCursorTarget():GetAbilityByIndex(0):SetLevel(self:GetCursorTarget():GetAbilityByIndex(0):GetLevel() + 1)
	SAD.PrivateGameState.PlayerTeam[self:GetCursorTarget().ID].Stars = SAD.PrivateGameState.PlayerTeam[self:GetCursorTarget().ID].Stars + 1
	self:GetCursorTarget():SetMaxMana(self:GetCursorTarget():GetAbilityByIndex(0):GetManaCost(-1) * 1.1)
	if SAD.PrivateGameState.PlayerTeam[self:GetCursorTarget().ID].Stars == 3 then
		self:GetCursorTarget():FindAbilityByName("sad_combine"):SetActivated(false)
	end
	SAD:RemovePlayerHeroByID(self:GetCaster().ID)
end

function sad_combine:CastFilterResultTarget(Target)
	if self:GetCaster() == Target or Target:GetName() ~= self:GetCaster():GetName() or self:GetCaster():GetLevel() ~= Target:GetLevel() then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end
