local CONF = _SHARED and _SHARED.infobox
assert(CONF, 'confira o config.lua no xml')
local CFG, ALPHA, TYPES, ALIASES = CONF.cfg, CONF.alpha, CONF.types, CONF.aliases or {}
local active, queue = {}, {}
local uid = 0
local lastTick = getTickCount()
local gS, gOX, gOY = 1, 0, 0

local function updateScale()
    gS = GetScaleValue()
    local sw, sh = GetScreenSize()
    gOX = (sw - 1920 * gS) / 2
    gOY = (sh - 1080 * gS) / 2
end

local function rx(x) 
    return gOX + x * gS 
end

local function ry(y) 
    return gOY + y * gS 
end

local function clampN(v, a, b) 
    return math.max(a, math.min(v, b)) 
end

local function round(v) 
    return math.floor(v + 0.5) 
end

local function approach(cur, target, speed, dt)
    return cur + (target - cur) * (1 - math.exp(-speed * dt))
end

local function col(rgb, a, mul)
    return tocolor(rgb[1], rgb[2], rgb[3], math.floor(clampN(a * (mul or 1), 0, 255)))
end

local function resolveFont(f)
    if isElement(f) then return f end
    return LoadFont(f.name, f.size, false, 'cleartype')
end

local function wrapText(text, font, maxW)
    local lines = {}
    if text == '' then return lines end
    for paragraph in (text .. '\n'):gmatch('(.-)\n') do
        local line = ''
        for word in paragraph:gmatch('%S+') do
            local test = (line == '') and word or (line .. ' ' .. word)
            if dxGetTextWidth(test, 1, font) <= maxW then
                line = test
            else
                if line ~= '' then lines[#lines + 1] = line; line = '' end
                if dxGetTextWidth(word, 1, font) > maxW then
                    local chunk = ''
                    for i = 1, (utf8.len(word) or #word) do
                        local ch = utf8.sub(word, i, i)
                        if chunk ~= '' and dxGetTextWidth(chunk .. ch, 1, font) > maxW then
                            lines[#lines + 1] = chunk
                            chunk = ch
                        else
                            chunk = chunk .. ch
                        end
                    end
                    line = chunk
                else
                    line = word
                end
            end
        end
        lines[#lines + 1] = line
    end
    return lines
end

local function buildLayout(n)
    local S = GetScaleValue()
    local titleFont, descFont = resolveFont(FONT.title), resolveFont(FONT.desc)
    local titleW = dxGetTextWidth(n.title, 1, titleFont) / S
    n.badgeW = math.ceil(25 + titleW + 14)
    local counterW = dxGetTextWidth('99+x', 1, titleFont) / S
    local minContent = n.badgeW + CFG.badgeGap + counterW
    local maxContent = CFG.maxW - CFG.padding * 2

    n.lines = wrapText(n.text, descFont, maxContent * S)
    local widest = 0
    for _, l in ipairs(n.lines) do
        widest = math.max(widest, dxGetTextWidth(l, 1, descFont) / S)
    end

    local contentW = clampN(math.max(minContent, widest), CFG.minW - CFG.padding * 2, maxContent)
    n.w = math.ceil(contentW + CFG.padding * 2)
    n.lineH = math.ceil(dxGetFontHeight(1, descFont) / S * CFG.lineSpacing)

    if #n.lines > 0 then
        n.h = CFG.padding + CFG.badgeH + CFG.badgeGap + #n.lines * n.lineH + CFG.bottomPad
    else
        n.h = CFG.padding * 2 + CFG.badgeH
    end
end

function Infobox(ntype, text, opts)
    opts = opts or {}
    ntype = ALIASES[ntype] or ntype
    ntype = TYPES[ntype] and ntype or 'about'
    text = tostring(text or '')
    local key = opts.key or (ntype .. '|' .. text)
    local now = getTickCount()

    for _, n in ipairs(active) do
        if n.key == key and not n.leaving then
            n.count = n.count + 1
            n.expire = now + n.duration
            n.pulseTick = now
            if n.text ~= text then
                n.text = text
                buildLayout(n)
            end
            return n.uid
        end
    end
    for _, n in ipairs(queue) do
        if n.key == key then
            n.count = n.count + 1
            return n.uid
        end
    end

    uid = uid + 1
    local n = {
        uid = uid, key = key, type = ntype, text = text,
        title = opts.title or TYPES[ntype].title,
        count = 1,
        duration = opts.duration or clampN(CFG.minTime + #text * CFG.timePerChar, CFG.minTime, CFG.maxTime),
        alpha = 0, ox = -CFG.slideDist, y = 0, ty = 0,
        pulseTick = 0, spawnTick = now, placed = false, leaving = false,
    }
    buildLayout(n)
    queue[#queue + 1] = n
    return n.uid
end

function ClearInfobox()
    for _, n in ipairs(active) do n.leaving = true end
    queue = {}
end

addEvent('Hayees.Notify > Add', true)
addEventHandler('Hayees.Notify > Add', root, function(ntype, text, opts)
    Infobox(ntype, text, opts)
end)

local function drawNotify(n, now)
    local tp = TYPES[n.type]
    local a = n.alpha
    local x, y = round(CFG.startX + n.ox), round(n.y)
    local pad = CFG.padding

    local pulse = 0
    if n.pulseTick > 0 then
        pulse = 1 - easeOutQuad(clampN((now - n.pulseTick) / 400, 0, 1))
    end

    RoundedRectangle(x, y, n.w, n.h, CFG.radius, col(tp.card, ALPHA.card, a))
    local bx, by = x + pad, y + pad
    RoundedRectangle(bx, by, n.badgeW, CFG.badgeH, CFG.badgeRadius, col(tp.color, ALPHA.badge + 45 * pulse, a))

    local icon = IMG[tp.icon]
    if icon then
        local ix = bx + 9 + (10 - tp.iw) / 2
        local iy = by + (CFG.badgeH - tp.ih) / 2
        dxDrawImage(rx(ix), ry(iy), tp.iw * gS, tp.ih * gS, icon, 0, 0, 0, tocolor(255, 255, 255, math.floor(255 * a)))
    end

    local titleFont = resolveFont(FONT.title)
    dxDrawText(n.title, rx(bx + 25), ry(by), rx(bx + n.badgeW), ry(by + CFG.badgeH), col(tp.color, ALPHA.title, a), 1, titleFont, 'left', 'center', false, false, false, false, true)

    if n.count > 1 then
        local label = (n.count > 99) and '99+x' or (n.count .. 'x')
        local sc = 1 + 0.4 * pulse
        dxDrawText(label, rx(x + n.w - pad - 80), ry(by), rx(x + n.w - pad), ry(by + CFG.badgeH), tocolor(255, 255, 255, math.floor(clampN((ALPHA.counter + 160 * pulse) * a, 0, 255))), sc, titleFont, 'right', 'center', false, false, false, false, true)
    end

    if #n.lines > 0 then
        local descFont = resolveFont(FONT.desc)
        local dy = by + CFG.badgeH + CFG.badgeGap
        for i, line in ipairs(n.lines) do
            local ly = dy + (i - 1) * n.lineH
            dxDrawText(line, rx(x + pad), ry(ly), rx(x + n.w - pad), ry(ly + n.lineH), tocolor(255, 255, 255, math.floor(ALPHA.desc * a)), 1, descFont, 'left', 'top', false, false, false, false, true)
        end
    end

    if CFG.showProgress and not n.leaving then
        local prog = clampN((n.expire - now) / n.duration, 0, 1)
        local barW = (n.w - pad * 2) * prog
        local barY = y + n.h - 9
        local barH = math.max(1, 2 * gS)
        dxDrawRectangle(rx(x + pad), ry(barY), (n.w - pad * 2) * gS, barH, tocolor(255, 255, 255, math.floor(10 * a)))
        dxDrawRectangle(rx(x + pad), ry(barY), barW * gS, barH, col(tp.color, 110, a))
    end
end

addEventHandler('onClientRender', root, function()
    if #active == 0 and #queue == 0 then 
        return 
    end

    local now = getTickCount()
    local dt = clampN((now - lastTick) / 1000, 0, 0.1)
    lastTick = now
    updateScale()

    local visible = 0

    for _, n in ipairs(active) do 
        if not n.leaving then 
            visible = visible + 1 
        end 
    end

    while visible < CFG.maxVisible and #queue > 0 do
        local n = table.remove(queue, 1)
        n.expire = now + n.duration
        active[#active + 1] = n
        visible = visible + 1
    end

    for _, n in ipairs(active) do
        if not n.leaving and now >= n.expire then n.leaving = true end
    end

    local cy = CFG.startY
    for _, n in ipairs(active) do
        if not n.leaving then
            n.ty = cy
            cy = cy + n.h + CFG.gap
        end
        if not n.placed then n.y = n.ty; n.placed = true end
    end

    for i = #active, 1, -1 do
        local n = active[i]
        n.alpha = approach(n.alpha, n.leaving and 0 or 1, CFG.fadeSpeed, dt)
        n.ox = approach(n.ox, n.leaving and -CFG.slideDist or 0, CFG.moveSpeed, dt)
        if not n.leaving then n.y = approach(n.y, n.ty, CFG.moveSpeed, dt) end

        if n.leaving and n.alpha < 0.02 then
            table.remove(active, i)
        end
    end
    for _, n in ipairs(active) do
        drawNotify(n, now)
    end
end)


addCommandHandler('infotest', function()
    Infobox('error', 'Voc~e não tem dinheiro para comrpar esse veículo.')
    Infobox('wartning', 'Acabei de criar essa notificação #Hayees >:)(xxx)llkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk')
    Infobox('about', 'Teste curto')
    for i = 1, 5 do 
        setTimer(function() Infobox('success', 'Recebi 1x Pão.', {key = 'giveTest'}) end, i*350,1)
    end
end) 