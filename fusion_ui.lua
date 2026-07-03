-- ========================================================================
-- NeoCore Fusion — global FUSE button + highlighted-set fusion system.
--
-- Reads the Fusion Jokers engine (FusionJokers.fusions, Card:fuse_card and
-- the cost-discount tables) and ONLY drives the UI:
--   * one button floating above the deck (GOLD/clickable when the highlighted
--     Jokers exactly match a registered recipe and you can afford it),
--   * a short label above it listing the highlighted Jokers ("Runner + Shortcut"),
--   * prunes Fusion Jokers' per-card FUSE button so this one replaces it.
-- Works for 2-, 3-, 4- and 5-component recipes (exact multiset match).
-- ========================================================================

NeoCoreFusion = NeoCoreFusion or {}

-- Tunables ---------------------------------------------------------------
NeoCoreFusion.BUTTON_Y_OFFSET = -2.6    -- vertical gap above the deck (negative = up)
NeoCoreFusion.LABEL_Y_OFFSET  = -0.55   -- gap between the label pill and the button
NeoCoreFusion.LABEL_MAX_W     = 3.6     -- label text shrinks to fit this width
NeoCoreFusion.fuse_cost_label = ""      -- live "$6" text on the button (read by the UI)
NeoCoreFusion.selected_label  = ""      -- live "Runner + Shortcut" text above the button
NeoCoreFusion.PILL = { 0, 0, 0, 0.55 }  -- background behind the selected-Jokers label

-- Small helpers ----------------------------------------------------------
local function ncf_deep_copy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do copy[k] = ncf_deep_copy(v) end
    return copy
end

local function ncf_joker_name(card)
    if card.config and card.config.center_key then
        local name = localize{ type = 'name_text', key = card.config.center_key, set = 'Joker' }
        if type(name) == "string" and name ~= "" and name ~= "ERROR" then return name end
    end
    return (card.ability and card.ability.name) or "?"
end

-- Apply the same discount logic Fusion Jokers uses in get_card_fusion.
function NeoCoreFusion.discounted_cost(fusion)
    local cost = fusion.cost
    if type(cost) ~= "number" then return cost end
    if G.GAME.fujo_fusion_discount then
        if G.GAME.fujo_fusion_discount[fusion.result_joker] then
            cost = cost - G.GAME.fujo_fusion_discount[fusion.result_joker]
        end
        cost = cost - (G.GAME.fujo_fusion_discount.universal or 0)
    end
    if G.GAME.fujo_fusion_discountpercent then
        if G.GAME.fujo_fusion_discountpercent[fusion.result_joker] then
            cost = cost * (1 - G.GAME.fujo_fusion_discountpercent[fusion.result_joker])
        end
        cost = cost * (1 - (G.GAME.fujo_fusion_discountpercent.universal or 0))
    end
    return math.max(math.floor(cost), 1)
end

-- Does the CURRENT highlighted-joker set exactly match a registered recipe?
-- Returns { recipe = <fusion or nil>, cost = <number or nil>, fuseable = <bool> }.
function NeoCoreFusion.get_highlighted_fusion()
    local result = { recipe = nil, cost = nil, fuseable = false }
    if not (FusionJokers and FusionJokers.fusions) then return result end
    if not (G.jokers and G.jokers.highlighted) then return result end

    local hcount, htotal = {}, 0
    for _, card in ipairs(G.jokers.highlighted) do
        if card.ability and card.ability.set == 'Joker' and card.config and card.config.center_key then
            local k = card.config.center_key
            hcount[k] = (hcount[k] or 0) + 1
            htotal = htotal + 1
        end
    end
    if htotal < 2 then return result end   -- need at least two jokers to fuse

    for _, fusion in ipairs(FusionJokers.fusions) do
        local rcount, rtotal = {}, 0
        for _, comp in ipairs(fusion.jokers) do
            rcount[comp.name] = (rcount[comp.name] or 0) + 1
            rtotal = rtotal + 1
        end
        if rtotal == htotal then
            local match = true
            for name, c in pairs(rcount) do
                if (hcount[name] or 0) ~= c then match = false break end
            end
            if match then
                local cost = NeoCoreFusion.discounted_cost(fusion)
                local reqok = true
                if type(fusion.requirement) == "function" then reqok = fusion.requirement() end
                local affordable = (to_big(cost) + to_big(G.GAME.bankrupt_at or 0)) <= to_big(G.GAME.dollars)
                result.recipe = fusion
                result.cost = cost
                result.fuseable = affordable and reqok
                return result
            end
        end
    end
    return result
end

-- Fuse the highlighted jokers. Reuses Fusion Jokers' Card:fuse_card by picking
-- a highlighted component as the "primary" and feeding it our exact recipe
-- (so its own get_card_fusion heuristics can't pick another).
function NeoCoreFusion.perform_highlighted_fusion()
    if G.CONTROLLER and G.CONTROLLER.locks and G.CONTROLLER.locks.selling_card then return end

    local info = NeoCoreFusion.get_highlighted_fusion()
    if not (info.recipe and info.fuseable) then return end
    local fusion = info.recipe

    local comp_names = {}
    for _, comp in ipairs(fusion.jokers) do comp_names[comp.name] = true end
    local primary
    for _, card in ipairs(G.jokers.highlighted) do
        if card.ability and card.ability.set == 'Joker' and card.config
           and comp_names[card.config.center_key] and card.area == G.jokers and not card.fused then
            primary = card
            break
        end
    end
    if not primary then return end

    local chosen = ncf_deep_copy(fusion)
    chosen.cost = info.cost
    chosen.blocked = nil

    primary.get_card_fusion = function() return chosen end
    primary:fuse_card()
    primary.get_card_fusion = nil   -- restore the metatable method
end

G.FUNCS.ncf_fuse_highlighted = function(e)
    NeoCoreFusion.perform_highlighted_fusion()
end

-- Button definition ------------------------------------------------------
-- The button and the selected-names label live in SEPARATE UIBoxes so a
-- long label can never stretch the FUSE button.
local function ncf_fuse_button_def()
    return {n = G.UIT.ROOT, config = {align = 'cm', colour = G.C.CLEAR, padding = 0.05, r = 0.1}, nodes = {
        {n = G.UIT.R, config = {
            id = 'ncf_fuse_btn', align = 'cm', minw = 1.7, minh = 0.85, r = 0.2, padding = 0.08,
            hover = true, shadow = true,
            colour = G.C.UI.BACKGROUND_INACTIVE, button = 'ncf_fuse_highlighted',
        }, nodes = {
            {n = G.UIT.R, config = {align = 'cm', maxw = 1.6}, nodes = {
                {n = G.UIT.T, config = {text = localize('b_fuse'), colour = G.C.UI.TEXT_LIGHT, scale = 0.5, shadow = true}},
            }},
            {n = G.UIT.R, config = {align = 'cm'}, nodes = {
                {n = G.UIT.T, config = {ref_table = NeoCoreFusion, ref_value = 'fuse_cost_label', colour = G.C.WHITE, scale = 0.42, shadow = true}},
            }},
        }},
    }}
end

local function ncf_label_def()
    return {n = G.UIT.ROOT, config = {align = 'cm', colour = G.C.CLEAR, padding = 0.03}, nodes = {
        {n = G.UIT.R, config = {id = 'ncf_label_row', align = 'cm', r = 0.08, padding = 0.05, minh = 0.35, colour = G.C.CLEAR, collideable = true}, nodes = {
            {n = G.UIT.T, config = {ref_table = NeoCoreFusion, ref_value = 'selected_label', scale = 0.32,
                maxw = NeoCoreFusion.LABEL_MAX_W, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
        }},
    }}
end

function NeoCoreFusion.create_fuse_button()
    if G.ncf_fuse_button then return end
    if not (G.deck and G.deck.T) then return end
    G.ncf_fuse_button = UIBox{
        definition = ncf_fuse_button_def(),
        config = {
            align  = 'cm',
            offset = { x = 0, y = NeoCoreFusion.BUTTON_Y_OFFSET },
            major  = G.deck,
            bond   = 'Weak',
        }
    }
    -- label floats above the button in its own box (never resizes the button)
    G.ncf_fuse_label = UIBox{
        definition = ncf_label_def(),
        config = {
            align  = 'tm',
            offset = { x = 0, y = NeoCoreFusion.LABEL_Y_OFFSET },
            major  = G.ncf_fuse_button,
            bond   = 'Weak',
        }
    }
    NeoCoreFusion.fuse_btn_uie  = G.ncf_fuse_button:get_UIE_by_ID('ncf_fuse_btn')
    NeoCoreFusion.label_row_uie = G.ncf_fuse_label:get_UIE_by_ID('ncf_label_row')
end

function NeoCoreFusion.remove_fuse_button()
    if G.ncf_fuse_button then
        G.ncf_fuse_button:remove()
        G.ncf_fuse_button = nil
    end
    if G.ncf_fuse_label then
        G.ncf_fuse_label:remove()
        G.ncf_fuse_label = nil
    end
    NeoCoreFusion.fuse_btn_uie  = nil
    NeoCoreFusion.label_row_uie = nil
    -- re-arm the preview change-detection for the next label UIElement
    NeoCoreFusion.preview_key = nil
end

-- Per-frame: colour gold/grey, enable/disable click, cost text, selected names.
function NeoCoreFusion.update_fuse_button()
    local btn = NeoCoreFusion.fuse_btn_uie
    if not btn or not btn.config then return end

    -- selected Joker names ("Runner + Shortcut")
    local names = {}
    if G.jokers and G.jokers.highlighted then
        for _, c in ipairs(G.jokers.highlighted) do
            if c.ability and c.ability.set == 'Joker' then
                names[#names + 1] = ncf_joker_name(c)
            end
        end
    end
    NeoCoreFusion.selected_label = table.concat(names, " + ")
    local lr = NeoCoreFusion.label_row_uie
    if lr and lr.config then
        lr.config.colour = (NeoCoreFusion.selected_label ~= "") and NeoCoreFusion.PILL or G.C.CLEAR
    end

    -- button colour / clickability / cost
    local info = NeoCoreFusion.get_highlighted_fusion()
    if info.recipe and info.fuseable then
        btn.config.colour = G.C.GOLD
        btn.config.button = 'ncf_fuse_highlighted'
        NeoCoreFusion.fuse_cost_label = localize('$') .. tostring(info.cost)
    else
        btn.config.colour = G.C.UI.BACKGROUND_INACTIVE
        btn.config.button = nil
        NeoCoreFusion.fuse_cost_label = info.recipe and (localize('$') .. tostring(info.cost)) or ""
    end

    -- Hovering the selected-names label previews the fusion RESULT card art.
    -- (result_popup_def lives in recipe_book.lua; rebuilt only when it changes)
    if lr and lr.config then
        local rk = info.recipe and info.recipe.result_joker or nil
        if rk ~= NeoCoreFusion.preview_key then
            NeoCoreFusion.preview_key = rk
            if lr.children and lr.children.h_popup then
                lr.children.h_popup:remove()
                lr.children.h_popup = nil
            end
            -- release the previous preview Sprite if its popup was never opened
            -- (adopted sprites are removed with their popup UIBox; orphans have
            -- no parent and must be removed by hand or they pile up in G.I.SPRITE)
            local old_def = lr.config.h_popup
            local old_sp = old_def and old_def.nodes and old_def.nodes[1]
                and old_def.nodes[1].nodes and old_def.nodes[1].nodes[1]
                and old_def.nodes[1].nodes[1].config.object
            if old_sp and not old_sp.parent and not old_sp.REMOVED then old_sp:remove() end
            -- the label row is collideable at build time, so hover just works
            -- whenever h_popup is set (Node:hover no-ops while it is nil)
            if rk and G.P_CENTERS[rk] and NeoCoreFusion.result_popup_def then
                lr.config.h_popup = NeoCoreFusion.result_popup_def(rk)
                lr.config.h_popup_config = { align = 'tm', offset = { x = 0, y = -0.15 }, parent = lr }
            else
                lr.config.h_popup = nil
            end
        end
    end
end

-- Drive creation / removal / state from the main game loop (always ticks)
if not NeoCoreFusion.game_update_patched then
    NeoCoreFusion.game_update_patched = true
    local game_update_ref = Game.update
    function Game:update(dt)
        game_update_ref(self, dt)
        if G.STAGE == G.STAGES.RUN and G.jokers and G.deck and G.deck.T then
            if not G.ncf_fuse_button then NeoCoreFusion.create_fuse_button() end
            NeoCoreFusion.update_fuse_button()
        elseif G.ncf_fuse_button then
            NeoCoreFusion.remove_fuse_button()
        end
    end
end

-- Hide Fusion Jokers' per-joker FUSE button (we use the global one now).
-- Prune ONLY the node carrying func == 'can_fuse_card' (never an ancestor, or
-- we'd delete the shared sell/use column with the SELL button).
if not NeoCoreFusion.use_sell_patched then
    NeoCoreFusion.use_sell_patched = true

    local function ncf_is_fuse_node(e)
        if type(e) ~= "table" then return false end
        if e.config and e.config.func == 'can_fuse_card' then return true end
        if type(e.nodes) == "table" and e.nodes[1] and e.nodes[1].config
           and e.nodes[1].config.func == 'can_fuse_card' then return true end
        return false
    end

    local function ncf_prune_fuse(node)
        if type(node) ~= "table" or type(node.nodes) ~= "table" then return end
        for i = #node.nodes, 1, -1 do
            if ncf_is_fuse_node(node.nodes[i]) then
                table.remove(node.nodes, i)
            else
                ncf_prune_fuse(node.nodes[i])
            end
        end
    end

    local fj_use_and_sell = G.UIDEF.use_and_sell_buttons
    function G.UIDEF.use_and_sell_buttons(card)
        local retval = fj_use_and_sell(card)
        ncf_prune_fuse(retval)
        return retval
    end
end
