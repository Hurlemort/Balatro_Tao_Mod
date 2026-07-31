-- positions straight from BattleScreen.xml, not a centered container like it looks
function SANS.LoadHealth()
    local imgY = 406 -- HP/KR: world (224,416)/(400,416), 23x10, bottom-anchored -> top = 416-10
    local healthY = 400
    local healthH = 21

    SANS.LoadImage("HP", 224, imgY, 0, 1, 1, false)
    SANS.LoadImage("KR", 400 - 23, imgY, 0, 1, 1, false) -- KR is right-anchored at x=400 in source
    SANS.healthbar = {
        rectX = 256,
        rectY = healthY,
        rectW = math.floor(SANS.player.max_hp * 1.2), -- Battle.xml: HPBackground.Width = floor(MaxHP*1.2)
        rectH = healthH
    }
end

function SANS.LoadFont(fontname, firstChar, lastChar)
    -- font sheets never change, so slicing once per session is enough
    if SANS.fonts[fontname] then return end

    -- Rebuild of the LoadImage function : easier since we have to direcSANSy manipulate the image data
    local filename = fontname .. ".png"

    local base = SANS.path or ""
    local last = base:sub(-1)
    if last ~= "/" and last ~= "\\" then
        base = base .. "/"
    end

    local full_path = base .. "textures/" .. filename

    -- Raw img data
    local file_data = NFS.newFileData(full_path)
    local imgData = love.image.newImageData(file_data)
    local width, height = imgData:getWidth(), imgData:getHeight()

    -- Green colums = character separator
    local charSlices = {}
    local startX = 0
    for x = 0, width - 1 do
        local r, g, b, a = imgData:getPixel(x, 0)
        if math.abs(r - 0) < 0.01 and math.abs(g - 1) < 0.01 and math.abs(b - 0) < 0.01 then
            local charW = x - startX
            if charW > 0 then
                table.insert(charSlices, {x = startX, w = charW})
            end
            startX = x + 1
        end
    end
    if startX < width then
        table.insert(charSlices, {x = startX, w = width - startX})
    end

    -- Create sub images per character
    SANS.fonts[fontname] = {}

    local numChars = lastChar - firstChar + 1

    for i = 1, math.min(numChars, #charSlices) do
        local slice = charSlices[i]
        local charCode = firstChar + i - 1

        local subData = love.image.newImageData(slice.w, height)
        subData:paste(imgData, 0, 0, slice.x, 0, slice.w, height)
        local subImg = love.graphics.newImage(subData)

        SANS.fonts[fontname][charCode] = {
            img = subImg,
            width = slice.w,
            height = height
        }
    end
end

-- loads an image to the framebuffer, fresh decode every call, no caching - tried caching once and it broke real rendering, not worth it
function SANS.LoadImage(name, x, y, rotation, scaleX, scaleY, isAttack, color)
    rotation = rotation or 0
    scaleX = scaleX or 1
    scaleY = scaleY or 1

    local filename = name .. ".png"

    local base = SANS.path or ""
    local last = base:sub(-1)
    if last ~= "/" and last ~= "\\" then
        base = base .. "/"
    end

    local full_path = base .. "textures/" .. filename

    local file_data = NFS.newFileData(full_path)
    local image_data = love.image.newImageData(file_data)

    -- recolor table (for bones and heart)
    if color then
        image_data:mapPixel(function(xp, yp, r, g, b, a)
            if a > 0 then
                return color.r or 1, color.g or 1, color.b or 1, a
            else
                return r, g, b, a
            end
        end)
    end

    local imgObj = love.graphics.newImage(image_data)
    local key = name
    if isAttack then
        SANS.attacksCount[name] = (SANS.attacksCount[name] or 0) + 1
        if SANS.attacksCount[name] > 1 then
            key = name .. SANS.attacksCount[name]
        end
    end

    SANS.images[key] = {
        img = imgObj,
        x = x,
        y = y,
        rotation = rotation,
        scaleX = scaleX,
        scaleY = scaleY,
        visible = true,
        isAttack = isAttack,
    }
    return key
end