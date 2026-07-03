-- ========================================================================
-- NeoCore Fusion — TFT-style fusion recipe book.
--
--   * A round book button sits to the RIGHT of the deck FUSE button
--     (press Q to open/close the book too).
--   * Each row shows the recipe with 0.5x joker art:  A + B  =  Result,
--     plus the result name and the (discounted) fusion cost.
--   * TFT-style availability: components you OWN render normally; missing
--     ones render GREYED (still recognisable). A fully-ready row glows.
--   * Hover any joker art to see that joker's full ability tooltip.
--   * Hover a recipe's name to preview the result card art (1x).
-- ========================================================================

NeoCoreFusion = NeoCoreFusion or {}
local RB = NeoCoreFusion.recipe_book or {}
NeoCoreFusion.recipe_book = RB

RB.PER_PAGE = 5                             -- recipe rows per page
RB.page = RB.page or 1
RB.BUTTON_OFFSET = { x = 0.35, y = 0 }      -- gap to the right of the FUSE button
RB.GREY = { 0.45, 0.45, 0.5, 1 }            -- tint for missing (unowned) jokers

-- Sprite helpers ----------------------------------------------------------

-- Card-art sprite for a center key. grey = render dimmed but recognisable.
local function center_sprite(key, scale, grey)
    local center = G.P_CENTERS[key]
    if not center then return nil end
    local atlas = (center.atlas and G.ASSET_ATLAS[center.atlas])
        or (center.set and G.ASSET_ATLAS[center.set])
        or G.ASSET_ATLAS['Joker']
    if not atlas then return nil end
    local s = Sprite(0, 0, scale * G.CARD_W, scale * G.CARD_H, atlas, center.pos or { x = 0, y = 0 })
    s.states.drag.can = false
    s.states.collide.can = false
    if grey then
        -- draw_self accepts an overlay colour: multiply toward grey keeps the
        -- art readable while clearly marking it as not owned yet
        s.draw = function(sp) Sprite.draw_self(sp, RB.GREY) end
    end
    return s
end

-- Hover popup showing the result joker's art at full card size.
local function result_popup_def(key)
    local s = center_sprite(key, 1, false)
    if not s then return nil end
    return {n = G.UIT.ROOT, config = { align = 'cm', colour = G.C.CLEAR, padding = 0.05 }, nodes = {
        {n = G.UIT.R, config = { align = 'cm', r = 0.1, colour = { 0, 0, 0, 0.8 }, padding = 0.12, shadow = true }, nodes = {
            {n = G.UIT.O, config = { object = s }},
        }},
    }}
end
NeoCoreFusion.result_popup_def = result_popup_def

-- Full ability tooltip for a center key, exactly like hovering a real card:
-- a hidden throwaway Card renders the standard card_h_popup (name, description
-- with live values, rarity badge). Cards are cached per key and cleaned up
-- when the book button is removed (stage exit).
RB._tt = RB._tt or {}
function RB.ability_popup(key)
    local center = G.P_CENTERS[key]
    if not center then return nil end
    local c = RB._tt[key]
    if not c or c.REMOVED then
        c = Card(0, 0, G.CARD_W, G.CARD_H, nil, center)
        c.states.visible = false
        c.no_shadow = true
        RB._tt[key] = c
    end
    c.ability_UIBox_table = c:generate_UIBox_ability_table()
    return G.UIDEF.card_h_popup(c)
end

function RB.clear_tooltip_cards()
    for _, c in pairs(RB._tt) do
        if c and c.remove and not c.REMOVED then c:remove() end
    end
    RB._tt = {}
end

-- Attach the hover popup to its own UIElement (parent isn't known until the
-- element exists, so a tiny per-frame func fills it in once).
G.FUNCS.ncf_rb_attach_popup = function(e)
    if e.config.h_popup_config and not e.config.h_popup_config.parent then
        e.config.h_popup_config.parent = e
    end
end

-- Recipe collection -------------------------------------------------------

-- Gather every registered recipe (any mod), with ownership info. Recipes
-- whose result OR components aren't registered centers (e.g. cross-mod
-- clones for a mod you don't have) are skipped — they can never be fused.
function RB.collect()
    local list = {}
    if not (FusionJokers and FusionJokers.fusions) then return list end
    for _, f in ipairs(FusionJokers.fusions) do
        if type(f) == 'table' and f.result_joker and type(f.jokers) == 'table'
            and G.P_CENTERS[f.result_joker] then
            local valid, need, own, ready = true, {}, {}, true
            for _, c in ipairs(f.jokers) do
                if not (c.name and G.P_CENTERS[c.name]) then valid = false break end
                need[c.name] = (need[c.name] or 0) + 1
            end
            if valid then
                for name, n in pairs(need) do
                    own[name] = #SMODS.find_card(name)
                    if own[name] < n then ready = false end
                end
                list[#list + 1] = { fusion = f, ready = ready, own = own }
            end
        end
    end
    table.sort(list, function(a, b)
        if a.ready ~= b.ready then return a.ready end
        return (a.fusion.result_joker or '') < (b.fusion.result_joker or '')
    end)
    return list
end

-- UI building -------------------------------------------------------------

-- A joker sprite wrapped so hovering it shows the full ability tooltip.
local function sprite_node(key, grey)
    local sp = center_sprite(key, 0.5, grey)
    if not sp then return nil end
    return {n = G.UIT.C, config = {
        align = 'cm', collideable = true,
        func = 'ncf_rb_attach_popup', insta_func = true,
        h_popup = RB.ability_popup(key),
        h_popup_config = { align = 'tm', offset = { x = 0, y = -0.1 } },
    }, nodes = {
        {n = G.UIT.O, config = { object = sp }},
    }}
end

local function recipe_row(entry)
    local f = entry.fusion
    local nodes = {}

    -- component sprites (greyed when that copy isn't owned)
    local seen = {}
    for _, comp in ipairs(f.jokers) do
        seen[comp.name] = (seen[comp.name] or 0) + 1
        local grey = (entry.own[comp.name] or 0) < seen[comp.name]
        local node = sprite_node(comp.name, grey)
        if node then
            if #nodes > 0 then
                nodes[#nodes + 1] = {n = G.UIT.T, config = { text = " + ", scale = 0.4, colour = G.C.WHITE, shadow = true }}
            end
            nodes[#nodes + 1] = node
        end
    end

    -- "=" result sprite (greyed until the recipe is ready)
    nodes[#nodes + 1] = {n = G.UIT.T, config = { text = " = ", scale = 0.45, colour = G.C.WHITE, shadow = true }}
    local rnode = sprite_node(f.result_joker, not entry.ready)
    if rnode then nodes[#nodes + 1] = rnode end

    -- name (hover -> full-size result art) + cost
    local cost = f.cost
    if type(cost) == "number" and G.GAME and NeoCoreFusion.discounted_cost then
        cost = NeoCoreFusion.discounted_cost(f)
    end
    local name = localize{ type = 'name_text', key = f.result_joker, set = 'Joker' }
    if type(name) ~= "string" or name == "ERROR" then name = f.result_joker end
    -- name column shrinks a little for wide (3+ component) recipes so the
    -- row still fits the panel; the name text auto-shrinks past maxw
    local wide = #f.jokers >= 3
    nodes[#nodes + 1] = {n = G.UIT.C, config = { align = 'cl', padding = 0.06, minw = wide and 2.2 or 2.9 }, nodes = {
        {n = G.UIT.R, config = {
            align = 'cl', padding = 0.03, collideable = true,
            func = 'ncf_rb_attach_popup', insta_func = true,
            h_popup = result_popup_def(f.result_joker),
            h_popup_config = { align = 'cl', offset = { x = -0.15, y = 0 } },
        }, nodes = {
            {n = G.UIT.T, config = { text = name, scale = 0.38, maxw = wide and 2.2 or 2.9,
                colour = entry.ready and G.C.GOLD or G.C.UI.TEXT_LIGHT, shadow = true }},
        }},
        {n = G.UIT.R, config = { align = 'cl', padding = 0.03 }, nodes = {
            {n = G.UIT.T, config = { text = localize('$') .. tostring(cost), scale = 0.38, colour = G.C.MONEY, shadow = true }},
        }},
    }}

    return {n = G.UIT.R, config = {
        align = 'cl', padding = 0.08, r = 0.1,
        colour = entry.ready and { 0.85, 0.7, 0.2, 0.3 } or { 0, 0, 0, 0.5 },
        emboss = entry.ready and 0.05 or nil,
    }, nodes = nodes}
end

-- Page cycle callback: remember the page and rebuild the overlay.
G.FUNCS.ncf_rb_page = function(args)
    RB.page = args.to_key or 1
    G.FUNCS.exit_overlay_menu()
    G.FUNCS.ncf_open_recipe_book()
end

G.FUNCS.ncf_open_recipe_book = function(e)
    local list = RB.collect()
    local pages = math.max(1, math.ceil(#list / RB.PER_PAGE))
    if RB.page > pages then RB.page = 1 end

    local rows = {}
    rows[#rows + 1] = {n = G.UIT.R, config = { align = 'cm', padding = 0.04 }, nodes = {
        {n = G.UIT.T, config = { text = "FUSION RECIPES", scale = 0.5, colour = G.C.WHITE, shadow = true }},
    }}
    local first = (RB.page - 1) * RB.PER_PAGE + 1
    for i = first, math.min(first + RB.PER_PAGE - 1, #list) do
        rows[#rows + 1] = recipe_row(list[i])
    end
    if #list == 0 then
        rows[#rows + 1] = {n = G.UIT.R, config = { align = 'cm', padding = 0.2 }, nodes = {
            {n = G.UIT.T, config = { text = "No fusion recipes registered", scale = 0.4, colour = G.C.UI.TEXT_LIGHT }},
        }}
    end
    if pages > 1 then
        local pageopts = {}
        for i = 1, pages do pageopts[i] = tostring(i) .. "/" .. tostring(pages) end
        rows[#rows + 1] = {n = G.UIT.R, config = { align = 'cm', padding = 0.05 }, nodes = {
            create_option_cycle({
                options = pageopts, current_option = RB.page,
                opt_callback = 'ncf_rb_page', colour = G.C.BLUE,
                w = 4.5, scale = 0.8, no_pips = true,
            }),
        }}
    end

    RB.book_open = true
    G.FUNCS.overlay_menu{
        definition = create_UIBox_generic_options({
            contents = {
                {n = G.UIT.C, config = { align = 'cm', padding = 0.05 }, nodes = rows},
            }
        })
    }
end

-- Round book button (to the right of the FUSE button) ----------------------

function RB.create_button()
    if G.ncf_recipe_btn then return end
    if not G.ncf_fuse_button then return end
    G.ncf_recipe_btn = UIBox{
        definition = {n = G.UIT.ROOT, config = { align = 'cm', colour = G.C.CLEAR, padding = 0 }, nodes = {
            -- same node shape as the (clickable) FUSE button: an R row carrying
            -- hover + button; round because r = half the button size.
            {n = G.UIT.R, config = {
                id = 'ncf_rb_btn', align = 'cm', minw = 0.85, minh = 0.85, r = 0.42, padding = 0.12,
                hover = true, shadow = true, colour = HEX('3B9C9C'),
                button = 'ncf_open_recipe_book',
            }, nodes = {
                -- little open book: two cream pages on a dark cover, spine gap between
                {n = G.UIT.C, config = { align = 'cm', minw = 0.46, minh = 0.36, r = 0.05, colour = HEX('5A3A1E'), padding = 0.04 }, nodes = {
                    {n = G.UIT.C, config = { align = 'cm', minw = 0.17, minh = 0.26, r = 0.02, colour = HEX('F4EBD0') }, nodes = {}},
                    {n = G.UIT.B, config = { w = 0.035, h = 0.26 }},
                    {n = G.UIT.C, config = { align = 'cm', minw = 0.17, minh = 0.26, r = 0.02, colour = HEX('F4EBD0') }, nodes = {}},
                }},
            }},
        }},
        config = { align = 'cr', offset = { x = RB.BUTTON_OFFSET.x, y = RB.BUTTON_OFFSET.y }, major = G.ncf_fuse_button, bond = 'Weak' },
    }
    RB.anchor = G.ncf_fuse_button
end

function RB.remove_button()
    if G.ncf_recipe_btn then
        G.ncf_recipe_btn:remove()
        G.ncf_recipe_btn = nil
    end
    RB.anchor = nil
    RB.clear_tooltip_cards()
end

-- Lifecycle: exists while the FUSE button exists (play + shop, gone in menus).
-- If the FUSE button is ever rebuilt, re-anchor by rebuilding the book button.
if not RB.game_update_patched then
    RB.game_update_patched = true
    local game_update_ref = Game.update
    function Game:update(dt)
        game_update_ref(self, dt)
        if G.STAGE == G.STAGES.RUN and G.ncf_fuse_button then
            if G.ncf_recipe_btn and RB.anchor ~= G.ncf_fuse_button then RB.remove_button() end
            if not G.ncf_recipe_btn then RB.create_button() end
        elseif G.ncf_recipe_btn then
            RB.remove_button()
        end
        if not G.OVERLAY_MENU then RB.book_open = false end
    end
end

-- Q hotkey: open/close the recipe book during a run.
if not RB.key_hook_patched then
    RB.key_hook_patched = true
    local key_press_ref = Controller.key_press_update
    function Controller:key_press_update(key, dt)
        key_press_ref(self, key, dt)
        if key == 'q' and G.STAGE == G.STAGES.RUN
           and not self.locks.frame and not self.text_input_hook then
            if G.OVERLAY_MENU then
                if RB.book_open then
                    RB.book_open = false
                    G.FUNCS.exit_overlay_menu()
                end
            else
                G.FUNCS.ncf_open_recipe_book()
            end
        end
    end
end
