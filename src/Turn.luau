local Turn = {}
Turn.attribute = "CampaignLedgerTurn"
function Turn.isActive(value)
	return value == "party" or value == "enemy"
end
function Turn.view(value)
	if value == "party" then return "Party turn", "Your party can act.", "mana" end
	if value == "enemy" then return "Enemy turn", "Wait while the enemies act.", "hp" end
	if value == nil or value == "idle" then return "No active combat", "Waiting for the DM to begin.", "muted" end
	return "Turn unavailable", "Ask the DM to set Party turn or Enemy turn.", "muted"
end
return Turn
