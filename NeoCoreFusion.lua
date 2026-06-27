-- NeoCore Fusion
-- A fusion UI library for the "Fusion Jokers" engine.
--   * Replaces the per-Joker FUSE button with ONE button above the deck.
--   * Highlight 2+ Jokers (works for 2-, 3-, 4-, 5-component recipes), then fuse.
--   * Shows the names of the highlighted Jokers above the button.
-- When this mod is present it overrides Fusion Jokers' per-card button for
-- ALL fusions. Without it, Fusion Jokers keeps its original per-card button.
-- (Manifest lives in NeoCoreFusion.json)

NeoCoreFusion = NeoCoreFusion or {}

-- The fusion engine (Fusion Jokers) must be present.
if not (FusionJokers and FusionJokers.fusions) then
	sendWarnMessage("Fusion Jokers is not loaded — NeoCore Fusion UI disabled.", "NeoCoreFusion")
	return
end

SMODS.load_file('fusion_ui.lua')()
