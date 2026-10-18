script_name("Cheat Menu")
script_author("Helper")

require "lib.moonloader"
local sampev = require "lib.samp.events"
local imgui = require 'mimgui'
local inicfg = require 'inicfg'
local ffi = require "ffi"
local raknet = require "samp.raknet"
require "samp.synchronization"

ffi.cdef [[
    int VkKeyScanA(char c);
]]

local cfg = {
    brakeEnabled = false, speed = 0.6, maxSpeed = 3.0, minSpeed = 0.1, brakeKey = 0x58,
    espEnabled = false, espBox = false, espName = false, espHealth = false, espArmor = false, espDistance = false, espWeapon = false, espWeaponIcon = false, espPlayerCount = false, espOffscreenArrows = false, espLine = false,
    maxDistance = 100.0, espColor = 0xFF33CCFF, espBoxColor = 0xFFFF5555, espBoxFill = false, espBoxFillColor = 0x665555FF, espBoxFillAlpha = 0.25, espBoxStyle = 1,
    espLineColor = 0xFF33CCFF, espDistanceColor = 0xFFCCCCCC, espBoxThickness = 1.0, espLineThickness = 1.5,
    espSkeleton = false, espSkeletonColor = 0xFF33CCFF, espSkeletonThickness = 1.5, espLineOrigin = 1, espLineTarget = 1,
    mineEspEnabled = false, mineTimer = true, mineMaxDist = 150.0,
    carSpeedhackEnabled = false, carSpeedMultiplier = 2.0, carFlyEnabled = false, carFlySpeed = 1.0,
    rvankaEnabled = false, rvankaSpeed = 50.0, rvankaRadius = 4.0,
    aimEnabled = false, aimType = 2, aimFov = 15.0, aimSmooth = 5.0, aimBone = 1, aimDrawFov = false,
    aimSafe = 1.0, aimSuperSmooth = 1.0, aimIsFire = false,
    aimVisibleCheck = false, aimDynamicSmooth = false,
    aimIgnoreRange = false, aimIgnoreStun = false, aimDrawShoot = false,
    silentEnable = false, silentDistance = 50.0, silentMissChance = 0.0,
    silentShotText = false, silentRadius = 80.0, silentShowRadius = false,
    ahkSpammer = false, ahkSpamDelay = 3.0, ahkSpamText = "Hello everyone! Script is working perfectly!",
    ahkAutoH = false, ahkFastTimeKey = false, ahkFastDlKey = false, ahkFastHeal = false,
    antiAfkEnabled = false, adminCheckerEnabled = false, wheelTeleportEnabled = false,
    menuOpen = false, tab = 1, theme = 1, espEditorOpen = false,
    menuKey = 0x2D, botStopKey = 0x2E, unloadKey = 0x23,
    rwhEnabled = false, rwhMode = 1, rwhKey = 0x52, rwhRadius = 200.0, rwhOffset = 15.0,
    rwhActive = false, rwhSync = false, rwhPassenger = true,
    kickerEnabled = false, kickerKey = 0x52, kickerRadius = 200.0, kickerSync = false, kickerTargetId = -1,
 }

local espIniDefaults = {
    esp = {
        enabled = false,
        box = false,
        name = false,
        health = false,
        armor = false,
        distance = false,
        playerCount = false,
        weapon = false,
        weaponIcon = false,
        offscreenArrows = false,
        line = false,
        skeleton = false,
        maxDistance = 100.0,
        boxThickness = 1.0,
        lineThickness = 1.5,
        skeletonThickness = 1.5,
        color = 0xFF33CCFF,
        boxColor = 0xFFFF5555,
        boxFill = false,
        boxFillColor = 0x665555FF,
        boxFillAlpha = 0.25,
        boxStyle = 1,
        lineColor = 0xFF33CCFF,
        distanceColor = 0xFFCCCCCC,
        skeletonColor = 0xFF33CCFF,
        lineOrigin = 1,
        lineTarget = 1
    }
}

local espIni = inicfg.load(espIniDefaults, 'CheatUtility_ESP')
local espDirty = false
local espSaveTimer = 0.0

local function loadESPSettings()
    local e = espIni.esp or espIniDefaults.esp
    cfg.espEnabled = e.enabled
    cfg.espBox = e.box
    cfg.espName = e.name
    cfg.espHealth = e.health
    cfg.espArmor = e.armor or false
    cfg.espDistance = e.distance
    cfg.espPlayerCount = e.playerCount or false
    cfg.espWeapon = e.weapon
    cfg.espWeaponIcon = e.weaponIcon
    cfg.espOffscreenArrows = e.offscreenArrows or false
    cfg.espLine = e.line
    cfg.espSkeleton = e.skeleton
    cfg.maxDistance = tonumber(e.maxDistance) or 100.0
    cfg.espBoxThickness = tonumber(e.boxThickness) or 1.0
    cfg.espLineThickness = tonumber(e.lineThickness) or 1.5
    cfg.espSkeletonThickness = tonumber(e.skeletonThickness) or 1.5
    cfg.espColor = tonumber(e.color) or 0xFF33CCFF
    cfg.espBoxColor = tonumber(e.boxColor) or 0xFFFF5555
    cfg.espBoxFill = e.boxFill or false
    cfg.espBoxFillColor = tonumber(e.boxFillColor) or 0x665555FF
    cfg.espBoxFillAlpha = tonumber(e.boxFillAlpha) or 0.25
    cfg.espBoxStyle = tonumber(e.boxStyle) or 1
    if cfg.espBoxStyle < 1 or cfg.espBoxStyle > 2 then cfg.espBoxStyle = 1 end
    cfg.espLineColor = tonumber(e.lineColor) or 0xFF33CCFF
    cfg.espDistanceColor = tonumber(e.distanceColor) or 0xFFCCCCCC
    cfg.espSkeletonColor = tonumber(e.skeletonColor) or 0xFF33CCFF
    cfg.espLineOrigin = tonumber(e.lineOrigin) or 1
    if cfg.espLineOrigin < 1 or cfg.espLineOrigin > 3 then cfg.espLineOrigin = 1 end
    cfg.espLineTarget = tonumber(e.lineTarget) or 1
    if cfg.espLineTarget < 1 or cfg.espLineTarget > 2 then cfg.espLineTarget = 1 end
end

local function saveESPSettings()
    espIni.esp = {
        enabled = cfg.espEnabled,
        box = cfg.espBox,
        name = cfg.espName,
        health = cfg.espHealth,
        armor = cfg.espArmor,
        distance = cfg.espDistance,
        playerCount = cfg.espPlayerCount,
        weapon = cfg.espWeapon,
        weaponIcon = cfg.espWeaponIcon,
        offscreenArrows = cfg.espOffscreenArrows,
        line = cfg.espLine,
        skeleton = cfg.espSkeleton,
        maxDistance = cfg.maxDistance,
        boxThickness = cfg.espBoxThickness,
        lineThickness = cfg.espLineThickness,
        skeletonThickness = cfg.espSkeletonThickness,
        color = cfg.espColor,
        boxColor = cfg.espBoxColor,
        boxFill = cfg.espBoxFill,
        boxFillColor = cfg.espBoxFillColor,
        boxFillAlpha = cfg.espBoxFillAlpha,
        boxStyle = cfg.espBoxStyle,
        lineColor = cfg.espLineColor,
        distanceColor = cfg.espDistanceColor,
        skeletonColor = cfg.espSkeletonColor,
        lineOrigin = cfg.espLineOrigin,
        lineTarget = cfg.espLineTarget
    }
    inicfg.save(espIni, 'CheatUtility_ESP')
    espDirty = false
    espSaveTimer = 0.0
end

local function markESPDirty()
    espDirty = true
end

loadESPSettings()

local route = {
    recording = false,
    playing = false,
    paused = false,
    points = {},
    recordTimer = 0,
    playIndex = 1,
    recordInterval = 0.010,
    name = "route1",
    startTime = 0,
    playStartTime = 0,
    pauseTime = 0,
    inCar = false,
    lastApplied = { w=false, a=false, s=false, d=false, run=false, alt=false, ctrl=false },
    prevKey = { w=false, a=false, s=false, d=false, run=false, alt=false, ctrl=false, jump=false, enter=false }
}

local P_CAM = 0xB6F1A8
local OFF_PITCH = 0x50
local OFF_YAW   = 0x54

local lastSmooth = 0
local coefficent = 0.04253

local function now()
    return os.clock()
end

local function readCameraAngles()
    local ok, yaw, pitch = pcall(function()
        local y = representIntAsFloat(readMemory(P_CAM + OFF_YAW, 4, false))
        local p = representIntAsFloat(readMemory(P_CAM + OFF_PITCH, 4, false))
        return y, p
    end)
    if ok and yaw and pitch then return yaw, pitch end
    return 0, 0
end

local function writeCameraAngles(yaw, pitch)
    pcall(function()
        writeMemory(P_CAM + OFF_YAW, 4, representFloatAsInt(yaw), false)
        writeMemory(P_CAM + OFF_PITCH, 4, representFloatAsInt(pitch), false)
    end)
end

local st = { posX = 0, posY = 0, posZ = 0 }
local carSt = { posX = 0, posY = 0, posZ = 0 }
local menu = { x = 100, y = 100, w = 460, h = 540 }
local ui = { dragging = false, dragDX = 0, dragDY = 0, sliderDrag = nil, scrollY = 0, scrollOffset = 0, scrollAreaY = 0, scrollAreaH = 0, scrollViewH = 0, scrollMax = 0 }
local clipRect = { enabled = false, x = 0, y = 0, x2 = 0, y2 = 0 }
local spamTimer = 0
local autoHTimer = 0
local antiAfkTimer = 0
local isEditingSpamText = false
local spamTextBuffer = cfg.ahkSpamText
local isEditingRouteName = false
local routeNameBuffer = "route1"
local adminAlertActive = false

local AIM_CONTENT_HEIGHT = 520

local mineOreModels = {
    [1237]=true,[2936]=true,[3931]=true,[3932]=true,[3933]=true,[3934]=true,[2682]=true
}

local VK = {
    W=0x57, A=0x41, S=0x53, D=0x44,
    SHIFT=0x10, LALT=0x12, LCONTROL=0x11,
    SPACE=0x20, ENTER=0x0D,
    RBUTTON=0x02, LBUTTON=0x01
}

local fontCache = {}
local function getFont(size, bold)
    local key = size .. (bold and 'b' or 'n')
    if not fontCache[key] then fontCache[key] = renderCreateFont('Arial', size, bold and 5 or 4) end
    return fontCache[key]
end

local function rectIntersectsClip(x, y, w, h)
    if not clipRect.enabled then return true end
    if x + w <= clipRect.x then return false end
    if x >= clipRect.x2 then return false end
    if y + h <= clipRect.y then return false end
    if y >= clipRect.y2 then return false end
    return true
end

local function drawRect(x,y,w,h,c)
    if clipRect.enabled then
        local rx2, ry2 = x + w, y + h
        if x < clipRect.x then x = clipRect.x end
        if y < clipRect.y then y = clipRect.y end
        if rx2 > clipRect.x2 then rx2 = clipRect.x2 end
        if ry2 > clipRect.y2 then ry2 = clipRect.y2 end
        if rx2 <= x or ry2 <= y then return end
        w = rx2 - x
        h = ry2 - y
    end
    renderDrawBox(x,y,w,h,c)
end

local function drawBorder(x,y,w,h,t,c)
    drawRect(x,y,w,t,c); drawRect(x,y+h-t,w,t,c)
    drawRect(x,y,t,h,c); drawRect(x+w-t,y,t,h,c)
end

local function drawText(text,x,y,color,font)
    if not font then return end
    if clipRect.enabled and (y + 16 <= clipRect.y or y >= clipRect.y2) then return end
    renderFontDrawText(font,text,x+1,y+1,0xAA000000)
    renderFontDrawText(font,text,x,y,color)
end

local themes = {
    [1] = { bg=0xEE15171C, header=0xFF1E88E5, text=0xFFE0E0E0, textDim=0xFF9098A8, button=0xFF2A2E38, buttonHover=0xFF3A4150, buttonActive=0xFF1E88E5, sliderBg=0xFF2A2E38, sliderFill=0xFF1E88E5, checkbox=0xFF1E88E5, checkBg=0xFF2A2E38, border=0xFF2A2E38 },
    [2] = { bg=0xF0ECECEC, header=0xFF2196F3, text=0xFF202020, textDim=0xFF606060, button=0xFFD0D0D0, buttonHover=0xFFBBBBBB, buttonActive=0xFF2196F3, sliderBg=0xFFC8C8C8, sliderFill=0xFF2196F3, checkbox=0xFF2196F3, checkBg=0xFFC8C8C8, border=0xFFB0B0B0 },
    [3] = { bg=0xEE1A1428, header=0xFFAA44FF, text=0xFFE8DDFF, textDim=0xFF9080B0, button=0xFF2A1F45, buttonHover=0xFF3A2A60, buttonActive=0xFFAA44FF, sliderBg=0xFF2A1F45, sliderFill=0xFFAA44FF, checkbox=0xFFAA44FF, checkBg=0xFF2A1F45, border=0xFF3A2A60 }
}
local function T() return themes[cfg.theme] end

local function syncPos()
    if not isPlayerPlaying(PLAYER_HANDLE) then return end
    if isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        if car and doesVehicleExist(car) then carSt.posX,carSt.posY,carSt.posZ = getCarCoordinates(car) end
    else
        st.posX,st.posY,st.posZ = getCharCoordinates(PLAYER_PED)
    end
end

local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
function GetBodyPartCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

function fix(angle)
    if angle > math.pi then
        angle = angle - (math.pi * 2)
    elseif angle < -math.pi then
        angle = angle + (math.pi * 2)
    end
    return angle
end

function rand()
    return math.random(-50, 50) / 100
end

function getDamage(weap)
    local damage = {
        [22] = 8.25,
        [23] = 13.2,
        [24] = 46.200000762939,
        [25] = 30,
        [26] = 30,
        [27] = 30,
        [28] = 6.6,
        [29] = 8.25,
        [30] = 9.9,
        [31] = 9.9000005722046,
        [32] = 6.6,
        [33] = 25,
        [38] = 46.2
    }
    return (damage[weap] or 0) + math.random(1e9) / 1e15
end

function getDistanceFromPed(ped)
    local ax, ay, az = getCharCoordinates(1)
    local bx, by, bz = getCharCoordinates(ped)
    return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2 + (az - bz) ^ 2)
end

function getpx()
    local w, h = getScreenResolution()
    return ((w / 2) / getCameraFov()) * cfg.silentRadius / 10
end

function canPedBeShot(ped)
    local w, h = getScreenResolution()
    local cx = representIntAsFloat(readMemory(0xB6EC10, 4, false))
    local cy = representIntAsFloat(readMemory(0xB6EC14, 4, false))
    local xc, yc = w * cy, h * cx
    local ax, ay, az = convertScreenCoordsToWorld3D(xc, yc, 0)
    local bx, by, bz = getCharCoordinates(ped)
    return not select(
        1,
        processLineOfSight(ax, ay, az, bx, by, bz + 0.7, true, false, false, true, false, true, false, false)
    )
end

function getcond(ped)
    if cfg.silentShotText then
        return true
    else
        return canPedBeShot(ped)
    end
end

function CheckStuned()
    for k, v in pairs(
        {
            "DAM_armL_frmBK","DAM_armL_frmFT","DAM_armL_frmLT",
            "DAM_armR_frmBK","DAM_armR_frmFT","DAM_armR_frmRT",
            "DAM_LegL_frmBK","DAM_LegL_frmFT","DAM_LegL_frmLT",
            "DAM_LegR_frmBK","DAM_LegR_frmFT","DAM_LegR_frmRT",
            "DAM_stomach_frmBK","DAM_stomach_frmFT","DAM_stomach_frmLT","DAM_stomach_frmRT"
        }
    ) do
        if isCharPlayingAnim(PLAYER_PED, v) then
            return false
        end
    end
    return true
end

function GetNearestPed(fov)
    local maxDistance = nil
    if not cfg.aimIgnoreRange then
        maxDistance = 35
    else
        maxDistance = 20000
    end
    local nearestPED = -1
    for i = 0, sampGetMaxPlayerId(true) do
        if sampIsPlayerConnected(i) then
            local find, handle = sampGetCharHandleBySampPlayerId(i)
            if find then
                if isCharOnScreen(handle) then
                    if not isCharDead(handle) then
                        local crosshairPos = {convertGameScreenCoordsToWindowScreenCoords(339.1, 179.1)}
                        local enPos = {GetBodyPartCoordinates(8, handle)}
                        local bonePos = {convert3DCoordsToScreen(enPos[1], enPos[2], enPos[3])}
                        local distance =
                            math.sqrt(
                            (math.pow((bonePos[1] - crosshairPos[1]), 2) + math.pow((bonePos[2] - crosshairPos[2]), 2))
                        )
                        if distance < cfg.aimSafe or distance > cfg.aimFov * 12 then
                            check = true
                        else
                            check = false
                        end
                        if not check then
                            local myPos = {getCharCoordinates(PLAYER_PED)}
                            local enPos2 = {getCharCoordinates(handle)}
                            local distance2 =
                                math.sqrt(
                                (math.pow((enPos2[1] - myPos[1]), 2) + math.pow((enPos2[2] - myPos[2]), 2) +
                                    math.pow((enPos2[3] - myPos[3]), 2))
                            )
                            if (distance2 < maxDistance) then
                                nearestPED = i
                                maxDistance = distance2
                            end
                        end
                    end
                end
            end
        end
    end
    return nearestPED
end

function getClosestPlayerFromCrosshair()
    local w, h = getScreenResolution()
    local cx = representIntAsFloat(readMemory(0xB6EC10, 4, false))
    local cy = representIntAsFloat(readMemory(0xB6EC14, 4, false))
    local xc, yc = w * cy, h * cx

    local R1, target = getCharPlayerIsTargeting(0)
    local R2, player = sampGetPlayerIdByCharHandle(target)
    if R2 then
        return player, target
    end
    local minDist = getpx()
    local closestId, closestPed = -1, -1
    for i = 0, 999 do
        local res, ped = sampGetCharHandleBySampPlayerId(i)
        if res then
            if getDistanceFromPed(ped) < cfg.silentDistance then
                local xi, yi = convert3DCoordsToScreen(getCharCoordinates(ped))
                local dist = math.sqrt((xi - xc) ^ 2 + (yi - yc) ^ 2)
                if dist < minDist then
                    minDist = dist
                    closestId, closestPed = i, ped
                end
            end
        end
    end
    return closestId, closestPed
end

local function updateAimbot()
    if not cfg.aimEnabled or not isPlayerPlaying(PLAYER_HANDLE) then return end

    if cfg.aimDrawFov then
        local sw,sh = getScreenResolution()
        local radius = cfg.aimFov*12
        local seg = 32
        for i=0,seg-1 do
            local a1=(i/seg)*math.pi*2
            local a2=((i+1)/seg)*math.pi*2
            renderDrawLine(sw/2+math.cos(a1)*radius, sh/2+math.sin(a1)*radius, sw/2+math.cos(a2)*radius, sh/2+math.sin(a2)*radius, 1, 0xAA00FF00)
        end
        if cfg.aimSafe > 0 then
            local radiusS = cfg.aimSafe
            for i=0,seg-1 do
                local a1=(i/seg)*math.pi*2
                local a2=((i+1)/seg)*math.pi*2
                renderDrawLine(sw/2+math.cos(a1)*radiusS, sh/2+math.sin(a1)*radiusS, sw/2+math.cos(a2)*radiusS, sh/2+math.sin(a2)*radiusS, 1, 0xAAFF0000)
            end
        end
    end

    if cfg.aimType == 2 and isKeyDown(VK.RBUTTON) then
        if not cfg.aimIsFire or (cfg.aimIsFire and isKeyDown(VK.LBUTTON)) then
            local playerID = GetNearestPed()
            if playerID ~= -1 then
                if (cfg.aimIgnoreStun and not CheckStuned()) then
                    return false
                end
                local _, handle = sampGetCharHandleBySampPlayerId(playerID)
                local myPos = {getActiveCameraCoordinates()}
                local enPos = {GetBodyPartCoordinates(8, handle)}
                if
                    not cfg.aimVisibleCheck or
                        (cfg.aimVisibleCheck and
                            isLineOfSightClear(
                                myPos[1], myPos[2], myPos[3],
                                enPos[1], enPos[2], enPos[3],
                                true, true, false, true, true
                            ))
                 then
                    local pedWeapon = getCurrentCharWeapon(PLAYER_PED)
                    if (pedWeapon >= 22 and pedWeapon <= 29) or pedWeapon == 32 then
                        coefficent = 0.04253
                    elseif pedWeapon == 30 or pedWeapon == 31 then
                        coefficent = 0.028
                    elseif pedWeapon == 33 then
                        coefficent = 0.01897
                    end
                    local vector = {myPos[1] - enPos[1], myPos[2] - enPos[2]}
                    local angle =
                        math.acos(vector[1] / math.sqrt((math.pow(vector[1], 2) + math.pow(vector[2], 2))))
                    local view = {
                        fix(representIntAsFloat(readMemory(0xB6F258, 4, false))),
                        fix(representIntAsFloat(readMemory(0xB6F248, 4, false)))
                    }
                    local dif = 0
                    if (vector[1] <= 0.0 and vector[2] >= 0.0) or (vector[1] >= 0.0 and vector[2] >= 0.0) then
                        dif = (angle + coefficent) - view[1]
                    end
                    if (vector[1] >= 0.0 and vector[2] <= 0.0) or (vector[1] <= 0.0 and vector[2] <= 0.0) then
                        dif = (-angle + coefficent) - view[1]
                    end
                    local multiplier = 1
                    if cfg.aimDynamicSmooth then multiplier = 5 end
                    local smooth = dif / ((cfg.aimSmooth * multiplier) * cfg.aimSuperSmooth)
                    if cfg.aimDynamicSmooth then
                        if smooth > 0.0 then
                            if smooth < lastSmooth then
                                smooth = smooth * (lastSmooth / smooth)
                            end
                        else
                            if -smooth < -lastSmooth then
                                smooth = smooth * (-lastSmooth / -smooth)
                            end
                        end
                        lastSmooth = smooth
                    end
                    if smooth > -1.0 and smooth < 0.5 and dif > -2.0 and dif < 2.0 then
                        view[1] = view[1] + smooth
                        ffi.cast('float*', 0xB6F258)[0] = view[1]
                        ffi.cast('float*', 0xB6F248)[0] = view[2]
                    end
                end
            end
        end
    end

    if cfg.aimDrawShoot and isKeyDown(VK.RBUTTON) and not sampIsCursorActive() then
        local playerID = GetNearestPed()
        if playerID ~= -1 then
            local _, handle = sampGetCharHandleBySampPlayerId(playerID)
            if handle then
                local bx, by, bz = GetBodyPartCoordinates(8, handle)
                local sx, sy = convert3DCoordsToScreen(bx, by, bz)
                if sx and sy then
                    drawRect(sx - 2, sy - 2, 4, 4, 0xFFFFFFFF)
                    local f = getFont(7, false)
                    drawText(tostring(8), sx + 6, sy, 0xFFFFFFFF, f)
                end
            end
        end
    end

    if cfg.silentShowRadius then
        local sw,sh = getScreenResolution()
        local radius = cfg.silentRadius
        local seg = 32
        for i=0,seg-1 do
            local a1=(i/seg)*math.pi*2
            local a2=((i+1)/seg)*math.pi*2
            renderDrawLine(sw/2+math.cos(a1)*radius, sh/2+math.sin(a1)*radius, sw/2+math.cos(a2)*radius, sh/2+math.sin(a2)*radius, 1, 0xAA7F71FF)
        end
    end
end

function sampev.onSendBulletSync(data)
    math.randomseed(os.clock())
    if not cfg.aimEnabled or cfg.aimType ~= 1 then
        return
    end
    local weap = getCurrentCharWeapon(PLAYER_PED)
    if not getDamage(weap) then
        return
    end
    local id, ped = getClosestPlayerFromCrosshair()
    if ped then
        if id == -1 then
            return
        end
        if data.targetType == 1 then
            return
        end
        if math.random(1, 100) < cfg.silentMissChance then
            return
        end
        if not getcond(ped) then
            return
        end
        data.targetType = 1
        local px, py, pz = getCharCoordinates(ped)
        data.targetId = id
        data.target = {x = px + rand(), y = py + rand(), z = pz + rand()}
        data.center = {x = rand(), y = rand(), z = rand()}
        lua_thread.create(
            function()
                wait(1)
                sampSendGiveDamage(id, getDamage(weap), weap, 3)
            end
        )
    end
end

function sampev.onSendVehicleSync(data)
    if cfg.rvankaEnabled then
        local angle = now()*cfg.rvankaSpeed
        if data.position then
            data.position.x = data.position.x + math.cos(angle)*cfg.rvankaRadius
            data.position.y = data.position.y + math.sin(angle)*cfg.rvankaRadius
        end
        if data.velocity then
            data.velocity.x = math.cos(angle)*40.0
            data.velocity.y = math.sin(angle)*40.0
            data.velocity.z = 25.0
        end
    end
end

function CreateSync(sync_type, copy_from_player)
    local sampfuncs = require('sampfuncs')
    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    local function func_send()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    local mt = {
        __index = function(t, index) return data[index] end,
        __newindex = function(t, index, value) data[index] = value end
    }
    return setmetatable({send = func_send}, mt)
end

function getCarRealMatrix(handle)
    local entity = getCarPointer(handle)
    if (entity ~= 0) then
        local carMatrix = readMemory(entity + 20, 4, true)
        if (carMatrix ~= 0) then
            local rx = representIntAsFloat(readMemory(carMatrix + (0 * 4), 4, true))
            local ry = representIntAsFloat(readMemory(carMatrix + (1 * 4), 4, true))
            local rz = representIntAsFloat(readMemory(carMatrix + (2 * 4), 4, true))
            local dx = representIntAsFloat(readMemory(carMatrix + (4 * 4), 4, true))
            local dy = representIntAsFloat(readMemory(carMatrix + (5 * 4), 4, true))
            local dz = representIntAsFloat(readMemory(carMatrix + (6 * 4), 4, true))
            return rx, ry, rz, dx, dy, dz
        end
    end
end

function getCoordsInFrontOfChar(vHandle, pHandle, offset)
    if not (doesVehicleExist(vHandle) and doesCharExist(pHandle)) then
        return false
    end
    local char = {getCharCoordinates(pHandle)}
    local charAngle = getCharHeading(pHandle)
    return true, char[1] + math.sin(-math.rad(charAngle)) * offset, char[2] + math.cos(-math.rad(charAngle)) * offset, char[3], charAngle
end

function getQuatByAngle(angle)
    local b = 0 * math.pi / 360.0
    local h = 0 * math.pi / 360.0
    local a = angle * math.pi / 360.0
    local c1, c2, c3 = math.cos(h), math.cos(a), math.cos(b)
    local s1, s2, s3 = math.sin(h), math.sin(a), math.sin(b)
    return (c1 * c2 * c3 - s1 * s2 * s3), -( c1 * s2 * c3 - s1 * c2 * s3 )
end

function sendUnoccupiedFuncs(id, x, y, z, vehicleHealth)
    local passenger = CreateSync('passenger')
    passenger.vehicleId = tonumber(id)
    passenger.health = getCharHealth(PLAYER_PED)
    passenger.armor = getCharArmour(PLAYER_PED)
    passenger.seatId = 1
    passenger.position = {x, y, z}
    passenger.send()

    local vehicleHandle = select(2, sampGetCarHandleBySampVehicleId(id))
    local rx, ry, rz, dx, dy, dz = getCarRealMatrix(vehicleHandle)

    local unoccupied = CreateSync('unoccupied')
    unoccupied.vehicleId = tonumber(id)
    unoccupied.seatId = 1
    unoccupied.roll = {rx, ry, rz}
    unoccupied.direction = {dx, dy, dz}
    unoccupied.moveSpeed.z = -0.1
    if vehicleHealth ~= nil then
        unoccupied.vehicleHealth = tonumber(vehicleHealth)
    end
    unoccupied.position = {x, y, z}
    unoccupied.send()
end

function sendPlayerRvanka(x, y, z)
    local player = CreateSync('player')
    local moveSpeed = 1.65
    player.moveSpeed = {moveSpeed, moveSpeed, moveSpeed}
    player.animationId, player.animationFlags = 1189, 4196
    player.position = {x - moveSpeed, y - moveSpeed, z - 0.65}
    player.send()
end

function sendVehicleKicker(x, y, z, move, qw, qz, angle, nomove)
    local vehicle = CreateSync('vehicle')
    if nomove then
        vehicle.moveSpeed = {0, 0, -0.1}
    else
        vehicle.moveSpeed = {math.sin(-math.rad(angle)) * move, math.cos(-math.rad(angle)) * move, -0.1}
    end
    vehicle.quaternion = {qw, 0.0, 0.0, qz}
    vehicle.position = {x, y, z}
    vehicle.send()
end

function sendPlayerKicker(sid, x, y, z)
    local player = CreateSync('player')
    player.keysData = 0
    player.moveSpeed = {0.7, 0.7, -1}
    player.specialAction = 4
    player.animationId = 1018
    player.animationFlags = 12211
    if sid ~= 0 then
        player.surfingVehicleId = sid
        player.surfingOffsets = {-50, -50, -50}
    end
    player.position = { x, y, z }
    player.send()
end

function sendUnoccupiedKicker(id, x, y, z)
    local unoccupied = CreateSync('unoccupied')
    local rx, ry, rz, dx, dy, dz = getCarRealMatrix(select(2, sampGetCarHandleBySampVehicleId(id)))
    unoccupied.vehicleId = id
    unoccupied.seatId = 0
    unoccupied.moveSpeed = {0.05, 0.05, 0.05}
    unoccupied.roll = {rx, ry, rz}
    unoccupied.direction = {dx, dy, dz}
    unoccupied.turnSpeed = {0.01, 0.01, 0.01}
    unoccupied.vehicleHealth = 1500
    unoccupied.position = { x, y, z }
    unoccupied.send()
end

function carLagger(vid, x, y, z)
    local trailer = CreateSync('trailer')
    trailer.trailerId = tonumber(vid)
    trailer.position = {x, y, z}
    trailer.send()
    local vehicle = CreateSync('vehicle')
    vehicle.trailerId = tonumber(vid)
    vehicle.position = {getCharCoordinates(PLAYER_PED)}
    vehicle.send()
    local unoccupied = CreateSync('unoccupied')
    unoccupied.vehicleId = tonumber(vid)
    unoccupied.seatId = 0
    unoccupied.roll = {-0.99413418769836, -0.10728088766336, 0.01371858920902}
    unoccupied.direction = {0.10740028321743, -0.99418157339096, 0.0082817962393165}
    unoccupied.position = {x, y, z}
    unoccupied.send()
end

function carRandomizer(vid, x, y, z)
    local player = CreateSync('player')
    player.surfingVehicleId = tonumber(vid)
    player.surfingOffsets = {-50, -50, -50}
    player.position = {getCharCoordinates(PLAYER_PED)}
    player.send()
    local unoccupied = CreateSync('unoccupied')
    unoccupied.vehicleId = tonumber(vid)
    unoccupied.seatId = 0
    unoccupied.roll = {-0.99413418769836, -0.10728088766336, 0.01371858920902}
    unoccupied.direction = {0.10740028321743, -0.99418157339096, 0.0082817962393165}
    unoccupied.position = {x, y, z}
    unoccupied.send()
end

function getNearCarToCenterInRadius(radius)
    local best, bestDist = -1, radius
    local sw, sh = getScreenResolution()
    for _, veh in ipairs(getAllVehicles()) do
        local ok, id = sampGetVehicleIdByCarHandle(veh)
        if ok then
            local cp = {getCarCoordinates(veh)}
            local sx, sy = convert3DCoordsToScreen(cp[1], cp[2], cp[3])
            if sx and sy then
                local d = math.sqrt((sx - sw/2)^2 + (sy - sh/2.5)^2)
                if d < bestDist then bestDist = d; best = id end
            end
        end
    end
    return best
end

function getNearCharToCenterInRadius(radius)
    local best, bestDist = -1, radius
    local myId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
    local sw, sh = getScreenResolution()
    for _, ch in ipairs(getAllChars()) do
        local ok, id = sampGetPlayerIdByCharHandle(ch)
        if ok and id ~= myId and not isCharDead(ch) then
            local cp = {getCharCoordinates(ch)}
            local sx, sy = convert3DCoordsToScreen(cp[1], cp[2], cp[3])
            if sx and sy then
                local d = math.sqrt((sx - sw/2)^2 + (sy - sh/2.5)^2)
                if d < bestDist then bestDist = d; best = id end
            end
        end
    end
    return best
end

local rwhTimer = 0
local function updateRWH()
    if not cfg.rwhEnabled or not isPlayerPlaying(PLAYER_HANDLE) then return end
    local keyJust = wasKeyPressed(cfg.rwhKey)

    if cfg.rwhMode == 1 then
        if keyJust then cfg.rwhActive = not cfg.rwhActive end
        if cfg.rwhActive then
            local id = -1
            local bestD = 9999
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local myId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
            for i = 0, sampGetMaxPlayerId(true) do
                if i ~= myId and sampIsPlayerConnected(i) then
                    local ok, ped = sampGetCharHandleBySampPlayerId(i)
                    if ok and not isCharDead(ped) and not sampIsPlayerPaused(i) then
                        local x, y, z = getCharCoordinates(ped)
                        local d = getDistanceBetweenCoords3d(mx, my, mz, x, y, z)
                        if d < bestD and d <= 45 then bestD = d; id = i end
                    end
                end
            end
            if id ~= -1 then
                local _, ped = sampGetCharHandleBySampPlayerId(id)
                local x, y, z = getCharCoordinates(ped)
                sendPlayerRvanka(x, y, z)
                if now() - rwhTimer > 2.0 then
                    lua_thread.create(function()
                        wait(50)
                        sendPlayerRvanka(x, y, z)
                    end)
                    rwhTimer = now()
                end
            end
        end
        return
    end

    if cfg.rwhMode == 2 then
        if not isCharInAnyCar(PLAYER_PED) then return end
        if getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED)) ~= 1 then return end
        local id = getNearCharToCenterInRadius(cfg.rwhRadius)
        if id ~= -1 and keyJust and not cfg.rwhSync then
            local _, ped = sampGetCharHandleBySampPlayerId(id)
            if ped then
                local bool, x, y, z, angle = getCoordsInFrontOfChar(getCarCharIsUsing(PLAYER_PED), ped, 2)
                if bool then
                    cfg.rwhSync = true
                    lua_thread.create(function()
                        local qw, qz = getQuatByAngle(angle + 180)
                        for i = 0, 3.45, 0.1 do
                            sendVehicleKicker(x, y, z, i, qw, qz, angle + 180)
                        end
                        wait(100)
                        cfg.rwhSync = false
                    end)
                end
            end
        end
        return
    end

    if cfg.rwhMode == 3 or cfg.rwhMode == 4 then
        if not isCharOnFoot(PLAYER_PED) then return end
        local vid = getNearCarToCenterInRadius(cfg.rwhRadius)
        if vid == -1 or not keyJust then return end
        local vh = select(2, sampGetCarHandleBySampVehicleId(vid))
        if not vh then return end
        local cx, cy, cz = getCarCoordinates(vh)
        cfg.rwhSync = true
        lua_thread.create(function()
            if cfg.rwhMode == 3 then
                if cfg.rwhPassenger then
                    sampSendEnterVehicle(vid, true)
                    wait(500)
                    sampForcePassengerSyncSeatId(vid, 1)
                    wait(500)
                    for i = cz, -135, -5 do
                        sendUnoccupiedFuncs(vid, cx, cy, i, 1500)
                        wait(0)
                    end
                else
                    sampSendEnterVehicle(vid, false)
                    wait(500)
                    sampForceVehicleSync(vid)
                    wait(500)
                    for i = cz, -990, -50 do
                        local veh = CreateSync('vehicle')
                        veh.moveSpeed.z = -0.1
                        veh.position = {cx, cy, i}
                        veh.send()
                        wait(0)
                    end
                end
            else
                for c = getCarHealth(vh), 100, -100 do
                    sendUnoccupiedFuncs(vid, cx, cy, cz, c)
                    wait(0)
                end
                sampSendVehicleDestroyed(vid)
            end
            wait(500)
            cfg.rwhSync = false
        end)
        return
    end

    if cfg.rwhMode == 5 then
        if not isCharInAnyCar(PLAYER_PED) then return end
        if keyJust and not cfg.rwhSync then
            local ch = {getCharCoordinates(PLAYER_PED)}
            local found, vh = findAllRandomVehiclesInSphere(ch[1], ch[2], ch[3], 85, true, true)
            if found and vh ~= storeCarCharIsInNoSave(PLAYER_PED) then
                local ok, vid = sampGetVehicleIdByCarHandle(vh)
                if ok then
                    cfg.rwhSync = true
                    for i = 0, 5 do carLagger(vid, ch[1], ch[2], ch[3] + 10) end
                    carLagger(vid, ch[1], ch[2], ch[3] + 55)
                    wait(35)
                    carLagger(vid, ch[1], ch[2], ch[3] + 15)
                    cfg.rwhSync = false
                end
            end
        end
        return
    end

    if cfg.rwhMode == 6 then
        if not isCharOnFoot(PLAYER_PED) then return end
        if keyJust and not cfg.rwhSync then
            local ch = {getCharCoordinates(PLAYER_PED)}
            local found, vh = findAllRandomVehiclesInSphere(ch[1], ch[2], ch[3], 15, true, true)
            if found then
                local ok, vid = sampGetVehicleIdByCarHandle(vh)
                if ok then
                    cfg.rwhSync = true
                    local off = math.random(-cfg.rwhOffset, cfg.rwhOffset)
                    local offZ = math.random(4, cfg.rwhOffset)
                    carRandomizer(vid, ch[1], ch[2], ch[3] - 50)
                    wait(20)
                    carRandomizer(vid, ch[1] - off, ch[2] - off, ch[3] + offZ)
                    cfg.rwhSync = false
                end
            end
        end
    end
end

local function updateKicker()
    if not cfg.kickerEnabled or not isPlayerPlaying(PLAYER_HANDLE) then return end
    if not isCharInAnyCar(PLAYER_PED) then return end
    if getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED)) ~= 1 then return end
    if cfg.kickerSync then return end

    local vid = getNearCharToCenterInRadius(cfg.kickerRadius)
    if vid == -1 then return end

    if wasKeyPressed(cfg.kickerKey) then
        local result, ped = sampGetCharHandleBySampPlayerId(vid)
        if not result then return end
        local bool, x, y, z, angle = getCoordsInFrontOfChar(getCarCharIsUsing(PLAYER_PED), ped, 2)
        if not bool then return end

        local myId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
        if vid == myId then return end

        cfg.kickerSync = true
        cfg.kickerTargetId = vid

        local nick = sampGetPlayerNickname(vid) or ("ID "..vid)
        sampAddChatMessage("{FFAA00}[Kicker] Trying to kick "..nick.." ["..vid.."]", -1)

        lua_thread.create(function()
            local qw, qz = getQuatByAngle(angle + 180)
            for i = 0, 3.45, 0.1 do
                sendVehicleKicker(x, y, z, i, qw, qz, angle + 180)
            end
            for i = 1, 10 do
                local bool2, x2, y2, z2, angle2 = getCoordsInFrontOfChar(getCarCharIsUsing(PLAYER_PED), ped, 2)
                if not bool2 then break end
                local qw2, qz2 = getQuatByAngle(angle2 + 180)
                for j = 0, 50 do
                    sendVehicleKicker(x2, y2, z2, 3.45, qw2, qz2, angle2 + 180)
                    wait(0)
                end
                wait(50)
            end
            cfg.kickerSync = false
            cfg.kickerTargetId = -1
        end)
    end
end

function onSendPacket(id)
    if cfg.rwhSync and (id == 200 or id == 210 or id == 209 or id == 212) then
        return false
    end
    if cfg.kickerSync and (id == 200 or id == 210 or id == 209) then
        return false
    end
end

local function ensureRouteDir()
    local dir = getWorkingDirectory().."\\routes"
    pcall(function() createDirectory(dir) end)
    return dir
end

local function recordRoutePoint()
    if not isPlayerPlaying(PLAYER_HANDLE) then return end

    local inCar = isCharInAnyCar(PLAYER_PED)
    local px,py,pz,h

    if inCar then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        if not car or not doesVehicleExist(car) then return end
        px,py,pz = getCarCoordinates(car)
        h = getCarHeading(car)
    else
        px,py,pz = getCharCoordinates(PLAYER_PED)
        h = getCharHeading(PLAYER_PED)
    end

    local yaw, pitch = readCameraAngles()

    local kw  = isKeyDown(VK.W)
    local ka  = isKeyDown(VK.A)
    local ks  = isKeyDown(VK.S)
    local kd  = isKeyDown(VK.D)
    local krun = isKeyDown(VK.SHIFT)
    local kalt = isKeyDown(VK.LALT)
    local kctrl = isKeyDown(VK.LCONTROL)
    local kjump = isKeyDown(VK.SPACE)
    local kenter = isKeyDown(VK.ENTER)

    local jumpEdge  = kjump  and not route.prevKey.jump
    local enterEdge = kenter and not route.prevKey.enter
    local t = now() - route.startTime

    route.points[#route.points+1] = {
        x=px, y=py, z=pz, h=h,
        yaw=yaw, pitch=pitch,
        w=kw, a=ka, s=ks, d=kd,
        run=krun, alt=kalt, ctrl=kctrl,
        jump=jumpEdge,
        enter=enterEdge,
        inCar=inCar,
        t=t
    }

    route.prevKey.w=kw; route.prevKey.a=ka; route.prevKey.s=ks
    route.prevKey.d=kd; route.prevKey.run=krun; route.prevKey.alt=kalt
    route.prevKey.ctrl=kctrl
    route.prevKey.jump=kjump
    route.prevKey.enter=kenter
end

local function saveRouteToFile()
    local dir = ensureRouteDir()
    local path = dir.."\\"..route.name..".lua"
    local f = io.open(path,"w")
    if not f then return false end
    f:write("return {\n")
    for _,p in ipairs(route.points) do
        f:write(string.format(
            "{x=%.4f,y=%.4f,z=%.4f,h=%.4f,yaw=%.5f,pitch=%.5f,w=%s,a=%s,s=%s,d=%s,run=%s,alt=%s,ctrl=%s,jump=%s,enter=%s,inCar=%s,t=%.4f},\n",
            p.x,p.y,p.z,p.h, p.yaw or 0, p.pitch or 0,
            tostring(p.w),tostring(p.a),tostring(p.s),tostring(p.d),
            tostring(p.run),tostring(p.alt),tostring(p.ctrl),
            tostring(p.jump),tostring(p.enter),
            tostring(p.inCar or false),p.t))
    end
    f:write("}\n"); f:close()
    return true
end

local function loadRouteFromFile()
    local dir = ensureRouteDir()
    local path = dir.."\\"..route.name..".lua"
    local f = io.open(path,"r")
    if not f then return false end
    local content = f:read("*a"); f:close()
    local func = loadstring(content)
    if not func then return false end
    local ok,data = pcall(func)
    if not ok or type(data)~="table" then return false end
    route.points = data
    return true
end

local function applyKeyState(vk, want) setVirtualKeyDown(vk, want and true or false) end

local function releaseAllKeys()
    applyKeyState(VK.W,false); applyKeyState(VK.A,false); applyKeyState(VK.S,false)
    applyKeyState(VK.D,false); applyKeyState(VK.SHIFT,false); applyKeyState(VK.LALT,false)
    applyKeyState(VK.LCONTROL,false); applyKeyState(VK.SPACE,false); applyKeyState(VK.ENTER,false)
    route.lastApplied.w=false; route.lastApplied.a=false; route.lastApplied.s=false
    route.lastApplied.d=false; route.lastApplied.run=false; route.lastApplied.alt=false
    route.lastApplied.ctrl=false
end

local function lerpAngle(a, b, t)
    local diff = fix(b - a)
    return a + diff * t
end

local function updateRouteBot()
    if not isPlayerPlaying(PLAYER_HANDLE) then return end

    if route.recording then
        if now()-route.recordTimer >= route.recordInterval then
            recordRoutePoint()
            route.recordTimer = now()
        end
        return
    end

    if not route.playing then return end
    if route.paused then
        releaseAllKeys()
        return
    end

    local total = #route.points
    if total==0 then route.playing=false; releaseAllKeys(); return end

    local elapsed = now() - route.playStartTime

    local i1, i2 = nil, nil
    for i=1,total do
        if route.points[i].t <= elapsed then i1 = i else i2 = i; break end
    end

    if not i1 then i1 = 1; i2 = 1 end
    if not i2 then
        route.playStartTime = now()
        route.playIndex = 1
        releaseAllKeys()
        return
    end

    local p1 = route.points[i1]
    local p2 = route.points[i2]

    route.playIndex = i1

    if p1.w    ~= route.lastApplied.w    then applyKeyState(VK.W,        p1.w);    route.lastApplied.w    = p1.w end
    if p1.a    ~= route.lastApplied.a    then applyKeyState(VK.A,        p1.a);    route.lastApplied.a    = p1.a end
    if p1.s    ~= route.lastApplied.s    then applyKeyState(VK.S,        p1.s);    route.lastApplied.s    = p1.s end
    if p1.d    ~= route.lastApplied.d    then applyKeyState(VK.D,        p1.d);    route.lastApplied.d    = p1.d end
    if p1.run  ~= route.lastApplied.run  then applyKeyState(VK.SHIFT,    p1.run);  route.lastApplied.run  = p1.run end
    if p1.alt  ~= route.lastApplied.alt  then applyKeyState(VK.LALT,     p1.alt);  route.lastApplied.alt  = p1.alt end
    if p1.ctrl ~= route.lastApplied.ctrl then applyKeyState(VK.LCONTROL, p1.ctrl); route.lastApplied.ctrl = p1.ctrl end

    if p1.jump then
        applyKeyState(VK.SPACE, true)
        lua_thread.create(function()
            wait(60)
            applyKeyState(VK.SPACE, false)
        end)
    end

    if p1.enter then
        applyKeyState(VK.ENTER, true)
        lua_thread.create(function()
            wait(60)
            applyKeyState(VK.ENTER, false)
        end)
    end

    local dt = p2.t - p1.t
    local alpha = 0
    if dt > 0.0001 then
        alpha = (elapsed - p1.t) / dt
        if alpha < 0 then alpha = 0 end
        if alpha > 1 then alpha = 1 end
    end

    local targetH = lerpAngle(p1.h or 0, p2.h or 0, alpha)
    if targetH < 0 then targetH = targetH + 360 end
    if targetH >= 360 then targetH = targetH - 360 end

    if p1.inCar and isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        if car and doesVehicleExist(car) then
            pcall(setCarHeading, car, targetH)
        end
    else
        pcall(setCharHeading, PLAYER_PED, targetH)
    end

    local yaw1, pitch1 = p1.yaw or 0, p1.pitch or 0
    local yaw2, pitch2 = p2.yaw or 0, p2.pitch or 0
    local curYaw = lerpAngle(yaw1, yaw2, alpha)
    local curPitch = pitch1 + (pitch2 - pitch1) * alpha
    writeCameraAngles(curYaw, curPitch)
end

local function updateAirBrake()
    if not cfg.brakeEnabled or not isPlayerPlaying(PLAYER_HANDLE) then return end
    local inCar = isCharInAnyCar(PLAYER_PED)
    local handle = inCar and storeCarCharIsInNoSave(PLAYER_PED) or PLAYER_PED
    if not handle or not doesCharExist(PLAYER_PED) then return end
    local angle = math.rad(getCharHeading(PLAYER_PED))
    local mx,my,mz = 0,0,0
    if isKeyDown(VK.W) then mx=mx-math.sin(angle); my=my+math.cos(angle) end
    if isKeyDown(VK.S) then mx=mx+math.sin(angle); my=my-math.cos(angle) end
    if isKeyDown(VK.A) then mx=mx-math.cos(angle); my=my-math.sin(angle) end
    if isKeyDown(VK.D) then mx=mx+math.cos(angle); my=my+math.sin(angle) end
    if isKeyDown(VK.SPACE) then mz=mz+1 end
    if isKeyDown(VK.SHIFT) then mz=mz-1 end
    local len = math.sqrt(mx*mx+my*my+mz*mz)
    if len>0 then mx,my,mz = mx/len,my/len,mz/len end
    st.posX=st.posX+mx*(cfg.speed*1.5)
    st.posY=st.posY+my*(cfg.speed*1.5)
    st.posZ=st.posZ+mz*(cfg.speed*1.5)
    if inCar and doesVehicleExist(handle) then
        setCarCoordinates(handle, st.posX,st.posY,st.posZ)
        setCarSpeed(handle, 0.0)
    else
        setCharCoordinates(PLAYER_PED, st.posX,st.posY,st.posZ)
    end
end

local function teleportToSight()
    if not cfg.wheelTeleportEnabled or not isPlayerPlaying(PLAYER_HANDLE) then return end
    if sampIsChatInputActive() or sampIsDialogActive() then return end
    local result,posX,posY,posZ = getTargetCoordinates()
    if result then
        posZ = getGroundZFor3dCoord(posX,posY,1000.0)
        local inCar = isCharInAnyCar(PLAYER_PED)
        local handle = inCar and storeCarCharIsInNoSave(PLAYER_PED) or PLAYER_PED
        if inCar and doesVehicleExist(handle) then setCarCoordinates(handle,posX,posY,posZ+1.0)
        else setCharCoordinates(PLAYER_PED,posX,posY,posZ+1.0) end
    end
end

local carSpeedhackCurrent = 0.0
local carFlyVelocity = {x = 0.0, y = 0.0, z = 0.0}

local function updateCarSpeedhack()
    if not cfg.carSpeedhackEnabled or not isPlayerPlaying(PLAYER_HANDLE) then
        carSpeedhackCurrent = 0.0
        return
    end
    if not isCharInAnyCar(PLAYER_PED) then
        carSpeedhackCurrent = 0.0
        return
    end

    local car = storeCarCharIsInNoSave(PLAYER_PED)
    if not car or not doesVehicleExist(car) then
        carSpeedhackCurrent = 0.0
        return
    end

    local ok, vx, vy, vz = pcall(getCarVelocity, car)
    if not ok or not vx or not vy or not vz then return end

    -- Hold ALT to smoothly add forward speed. No multiplier or W requirement.
    local targetAdd = isKeyDown(VK.LALT) and 0.045 or 0.0
    carSpeedhackCurrent = carSpeedhackCurrent + (targetAdd - carSpeedhackCurrent) * 0.12

    if math.abs(carSpeedhackCurrent) > 0.0001 then
        local angle = math.rad(getCarHeading(car))
        local fx = -math.sin(angle)
        local fy =  math.cos(angle)
        local addX = fx * carSpeedhackCurrent
        local addY = fy * carSpeedhackCurrent
        pcall(setCarVelocity, car, vx + addX, vy + addY, vz)
    end
end

local function updateCarFly()
    if not cfg.carFlyEnabled or not isPlayerPlaying(PLAYER_HANDLE) then return end
    if not isCharInAnyCar(PLAYER_PED) then return end

    local car = storeCarCharIsInNoSave(PLAYER_PED)
    if not car or not doesVehicleExist(car) then return end

    local angle = math.rad(getCarHeading(car))
    local tx, ty, tz = 0.0, 0.0, 0.0
    if isKeyDown(VK.W) then tx=tx-math.sin(angle); ty=ty+math.cos(angle) end
    if isKeyDown(VK.S) then tx=tx+math.sin(angle); ty=ty-math.cos(angle) end
    if isKeyDown(VK.A) then tx=tx-math.cos(angle); ty=ty-math.sin(angle) end
    if isKeyDown(VK.D) then tx=tx+math.cos(angle); ty=ty+math.sin(angle) end
    if isKeyDown(VK.SPACE) then tz=tz+1.0 end
    if isKeyDown(VK.SHIFT) then tz=tz-1.0 end

    local len = math.sqrt(tx*tx+ty*ty+tz*tz)
    if len > 0.0 then tx,ty,tz = tx/len,ty/len,tz/len end

    -- Smoothly accelerate/decelerate toward the requested flight direction.
    local targetSpeed = 1.35
    local targetX, targetY, targetZ = tx*targetSpeed, ty*targetSpeed, tz*targetSpeed
    carFlyVelocity.x = carFlyVelocity.x + (targetX - carFlyVelocity.x) * 0.16
    carFlyVelocity.y = carFlyVelocity.y + (targetY - carFlyVelocity.y) * 0.16
    carFlyVelocity.z = carFlyVelocity.z + (targetZ - carFlyVelocity.z) * 0.16

    pcall(setCarVelocity, car, carFlyVelocity.x, carFlyVelocity.y, carFlyVelocity.z)
end

local espSkeletonBones = {
    -- torso / neck / head
    {2, 3}, {3, 4}, {4, 5}, {5, 6},
    -- left arm
    {21, 22}, {22, 23}, {23, 24},
    -- right arm
    {31, 32}, {32, 33}, {33, 34},
    -- left leg
    {41, 42}, {42, 43}, {43, 44},
    -- right leg
    {51, 52}, {52, 53}, {53, 54},
    -- connect shoulders/hips to the torso
    {3, 21}, {3, 31}, {2, 41}, {2, 51}
}

local function drawSkeleton(ped)
    for _, pair in ipairs(espSkeletonBones) do
        local ok1, x1, y1, z1 = pcall(GetBodyPartCoordinates, pair[1], ped)
        local ok2, x2, y2, z2 = pcall(GetBodyPartCoordinates, pair[2], ped)
        if ok1 and ok2 and x1 and x2 then
            local sx1, sy1 = convert3DCoordsToScreen(x1, y1, z1)
            local sx2, sy2 = convert3DCoordsToScreen(x2, y2, z2)
            if sx1 and sy1 and sx2 and sy2 then
                renderDrawLine(sx1, sy1, sx2, sy2, cfg.espSkeletonThickness, cfg.espSkeletonColor)
            end
        end
    end
end

local weaponNames = {
    [0] = 'Fist', [1] = 'Brass Knuckles', [2] = 'Golf Club', [3] = 'Nightstick',
    [4] = 'Knife', [5] = 'Bat', [6] = 'Shovel', [7] = 'Pool Cue', [8] = 'Katana',
    [9] = 'Chainsaw', [10] = 'Dildo', [11] = 'Dildo 2', [12] = 'Vibrator',
    [13] = 'Vibrator 2', [14] = 'Flowers', [15] = 'Cane', [16] = 'Grenade',
    [17] = 'Tear Gas', [18] = 'Molotov', [22] = 'Pistol', [23] = 'Silenced Pistol',
    [24] = 'Desert Eagle', [25] = 'Shotgun', [26] = 'Sawed-Off', [27] = 'Combat Shotgun',
    [28] = 'Uzi', [29] = 'MP5', [30] = 'AK-47', [31] = 'M4', [32] = 'Tec-9',
    [33] = 'Rifle', [34] = 'Sniper', [35] = 'RPG', [36] = 'Heat-Seeker',
    [37] = 'Flamethrower', [38] = 'Minigun', [39] = 'Satchel', [40] = 'Detonator',
    [41] = 'Spray Can', [42] = 'Fire Extinguisher', [43] = 'Camera', [44] = 'Night Vision',
    [45] = 'Thermal Goggles', [46] = 'Parachute'
}

local function getWeaponName(weaponId)
    return weaponNames[tonumber(weaponId) or 0] or ('Weapon '..tostring(weaponId))
end

-- Real GTA: San Andreas weapon HUD icons.
-- The original game stores the fist in HUD.TXD and weapon icons in the
-- corresponding weapon TXD files. MoonLoader exposes the same GTA sprite
-- loading/drawing opcodes, so we use the actual game sprites instead of
-- approximating weapons with render lines.
local weaponSpriteInfo = {
    [0]  = {'hud', 'fist'},
    [1]  = {'brassknuckle', 'brassknuckleicon'},
    [2]  = {'golfclub', 'golfclubicon'},
    [3]  = {'nitestick', 'nitestickicon'},
    [4]  = {'knifecur', 'knifecuricon'},
    [5]  = {'bat', 'baticon'},
    [6]  = {'shovel', 'shovelicon'},
    [7]  = {'poolcue', 'poolcueicon'},
    [8]  = {'katana', 'katanaicon'},
    [9]  = {'chnsaw', 'chnsawicon'},
    [10] = {'gun_dildo1', 'dildo1icon'},
    [11] = {'gun_dildo2', 'dildo2icon'},
    [12] = {'gun_vibe1', 'vibe1icon'},
    [13] = {'gun_vibe2', 'vibe2icon'},
    [14] = {'flowera', 'floweraicon'},
    [15] = {'gun_cane', 'caneicon'},
    [16] = {'grenade', 'grenadeicon'},
    [17] = {'teargas', 'teargasicon'},
    [18] = {'molotov', 'molotovicon'},
    [22] = {'colt45', 'colt45icon'},
    [23] = {'silenced', 'silencedicon'},
    [24] = {'desert_eagle', 'desert_eagleicon'},
    [25] = {'chromegun', 'chromegunicon'},
    [26] = {'sawnoff', 'sawnofficon'},
    [27] = {'shotgspa', 'shotgspaicon'},
    [28] = {'micro_uzi', 'micro_uziicon'},
    [29] = {'mp5lng', 'mp5lngicon'},
    [30] = {'ak47', 'ak47icon'},
    [31] = {'m4', 'm4icon'},
    [32] = {'tec9', 'tec9icon'},
    [33] = {'rifle', 'rifleicon'},
    [34] = {'sniper', 'snipericon'},
    [35] = {'rocketla', 'rocketlaicon'},
    [36] = {'heatseek', 'heatseekicon'},
    [37] = {'flame', 'flameicon'},
    [38] = {'minigun', 'minigunicon'},
    [39] = {'satchel', 'satchelicon'},
    [40] = {'bomb', 'bombicon'},
    [41] = {'spraycan', 'spraycanicon'},
    [42] = {'fire_ex', 'fire_exicon'},
    [43] = {'camera', 'cameraicon'},
    [44] = {'nvgoggles', 'nvgogglesicon'},
    [45] = {'irgoggles', 'irgogglesicon'},
    [46] = {'gun_para', 'gun_paraicon'}
}

local weaponSprites = {}
local weaponSpriteLoadAttempted = {}

local function getWeaponSprite(weaponId)
    weaponId = tonumber(weaponId) or 0
    if weaponSprites[weaponId] then return weaponSprites[weaponId] end
    if weaponSpriteLoadAttempted[weaponId] then return nil end
    weaponSpriteLoadAttempted[weaponId] = true

    local info = weaponSpriteInfo[weaponId]
    if not info then return nil end

    local ok, sprite = pcall(function()
        loadTextureDictionary(info[1])
        return loadSprite(info[2])
    end)

    if ok and sprite and tonumber(sprite) and tonumber(sprite) ~= 0 then
        weaponSprites[weaponId] = sprite
        return sprite
    end
    return nil
end

local function drawWeaponIcon(cx, cy, weaponId, color, sizePx)
    local sprite = getWeaponSprite(weaponId)
    if not sprite then return end

    -- drawSprite() uses GTA's 640x448 game-screen coordinate space,
    -- while ESP coordinates are normal window/screen pixels. Convert them first.
    local gx, gy = convertWindowScreenCoordsToGameScreenCoords(math.floor(cx), math.floor(cy))
    if gx and gy then
        -- Keep the native GTA icon small enough to match the ESP box.
        -- drawSprite() expects GTA's virtual 640x448 coordinates, so convert
        -- the desired on-screen pixel size back into that coordinate space.
        local sw, sh = getScreenResolution()
        local px = tonumber(sizePx) or 18.0
        local gw = px * 640.0 / sw
        local gh = px * 448.0 / sh
        drawSprite(sprite, gx, gy, gw, gh, 255, 255, 255, 255)
    end
end

local function drawESPBox(x,y,w,h,t,color,style)
    if style == 2 then
        local corner = math.max(5, math.min(14, w * 0.28))
        drawRect(x,y,corner,t,color); drawRect(x,y,t,corner,color)
        drawRect(x+w-corner,y,corner,t,color); drawRect(x+w-t,y,t,corner,color)
        drawRect(x,y+h-t,corner,t,color); drawRect(x,y+h-corner,t,corner,color)
        drawRect(x+w-corner,y+h-t,corner,t,color); drawRect(x+w-t,y+h-corner,t,corner,color)
    else
        drawBorder(x,y,w,h,t,color)
    end
end

local function drawHealthIcon(x,y,scale,color)
    local s = scale or 1
    -- Tiny heart silhouette, rendered independently of font glyph support.
    drawRect(x-4*s,y-2*s,3*s,3*s,color)
    drawRect(x+1*s,y-2*s,3*s,3*s,color)
    drawRect(x-3*s,y+1*s,6*s,3*s,color)
    drawRect(x-2*s,y+4*s,4*s,2*s,color)
end

local function drawArmorIcon(x,y,scale,color)
    local s = scale or 1
    -- Tiny shield silhouette.
    drawRect(x-4*s,y-4*s,8*s,2*s,color)
    drawRect(x-3*s,y-2*s,6*s,5*s,color)
    drawRect(x-2*s,y+3*s,4*s,2*s,color)
    drawRect(x-1*s,y+5*s,2*s,1*s,color)
end

local function drawHealthArmorBars(sx, sy, boxW, boxH, hp, armor)
    local barW = math.max(22, math.min(90, boxW * 1.65))
    local barH = 4
    local x = sx - barW/2
    local y = sy + boxH + 3
    local hpRatio = math.max(0, math.min(1, hp/100))
    local hpColor = hp > 50 and 0xFF32E650 or (hp > 20 and 0xFFFFC833 or 0xFFFF3333)
    drawRect(x-1,y-1,barW+2,barH+2,0xAA000000)
    drawRect(x,y,barW,barH,0x66333333)
    if hpRatio > 0 then drawRect(x,y,barW*hpRatio,barH,hpColor) end
    local font = getFont(7,false)
    local hpText = string.format('%d HP', math.floor(hp+0.5))
    drawHealthIcon(x+1,y+2,0.65,hpColor)
    drawText(hpText, x+7, y+5, hpColor, font)

    local ay = y + 17
    local ar = math.max(0, math.min(1, armor/100))
    drawRect(x-1,ay-1,barW+2,barH+2,0xAA000000)
    drawRect(x,ay,barW,barH,0x66333333)
    if ar > 0 then drawRect(x,ay,barW*ar,barH,0xFFFFFFFF) end
    local armorText = string.format('%d AP', math.floor(armor+0.5))
    drawArmorIcon(x+1,ay+2,0.65,0xFFFFFFFF)
    drawText(armorText, x+7, ay+5, 0xFFFFFFFF, font)
end

local function drawOffscreenArrow(targetX, targetY, sw, sh, color)
    local cx, cy = sw / 2, sh / 2
    local dx, dy = targetX - cx, targetY - cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return end
    dx, dy = dx / len, dy / len

    -- Keep the arrow tip just inside the screen border.
    local margin = math.max(22, math.min(40, math.min(sw, sh) * 0.035))
    local halfW, halfH = sw / 2 - margin, sh / 2 - margin
    local tx, ty
    local scaleX = math.abs(dx) > 0.0001 and halfW / math.abs(dx) or math.huge
    local scaleY = math.abs(dy) > 0.0001 and halfH / math.abs(dy) or math.huge
    local scale = math.min(scaleX, scaleY)
    tx, ty = cx + dx * scale, cy + dy * scale

    local size = 12
    local baseX = tx - dx * size
    local baseY = ty - dy * size
    local px, py = -dy, dx
    local wing = size * 0.65
    local lx, ly = baseX + px * wing, baseY + py * wing
    local rx, ry = baseX - px * wing, baseY - py * wing

    -- Black outline + colored arrow for readability over any background.
    local outline = 0xCC000000
    local ot = 3
    renderDrawLine(tx, ty, lx, ly, ot, outline)
    renderDrawLine(tx, ty, rx, ry, ot, outline)
    renderDrawLine(lx, ly, rx, ry, ot, outline)
    renderDrawLine(tx, ty, lx, ly, 1.5, color)
    renderDrawLine(tx, ty, rx, ry, 1.5, color)
    renderDrawLine(lx, ly, rx, ry, 1.5, color)
end

local function drawESP()
    useRenderCommands(true)
    if not isPlayerPlaying(PLAYER_HANDLE) then return end
    local myX,myY,myZ = getCharCoordinates(PLAYER_PED)
    if cfg.espEnabled then
        if cfg.espPlayerCount then
            local playersInRadius, vehiclesInRadius = 0, 0
            for id=0,1000 do
                if sampIsPlayerConnected(id) then
                    local result,ped = sampGetCharHandleBySampPlayerId(id)
                    if result and doesCharExist(ped) and not isCharDead(ped) and ped~=PLAYER_PED then
                        local px,py,pz = getCharCoordinates(ped)
                        local dist = math.sqrt((px-myX)^2+(py-myY)^2+(pz-myZ)^2)
                        if dist <= cfg.maxDistance then playersInRadius = playersInRadius + 1 end
                    end
                end
            end
            for _,veh in ipairs(getAllVehicles()) do
                if doesVehicleExist(veh) then
                    local vx,vy,vz = getCarCoordinates(veh)
                    local dist = math.sqrt((vx-myX)^2+(vy-myY)^2+(vz-myZ)^2)
                    if dist <= cfg.maxDistance then vehiclesInRadius = vehiclesInRadius + 1 end
                end
            end
            local sw,sh = getScreenResolution()
            local font = getFont(10,false)
            local line1 = string.format('ESP', playersInRadius)
            local line2 = string.format('%d Players', playersInRadius)
            local line3 = string.format('%d Vehicles', vehiclesInRadius)
            local function centerCounter(text,y)
                local tw = renderGetFontDrawTextLength(font,text)
                drawText(text, sw/2 - tw/2 + 1, y+1, 0xCC000000, font)
                drawText(text, sw/2 - tw/2, y, 0xFFFFFFFF, font)
            end
            centerCounter(line1, 8)
            centerCounter(line2, 20)
            centerCounter(line3, 32)
        end
        if cfg.espOffscreenArrows then
            local sw, sh = getScreenResolution()
            for id=0,1000 do
                if sampIsPlayerConnected(id) then
                    local result,ped = sampGetCharHandleBySampPlayerId(id)
                    if result and doesCharExist(ped) and not isCharDead(ped) and ped~=PLAYER_PED then
                        local px,py,pz = getCharCoordinates(ped)
                        local dist = math.sqrt((px-myX)^2+(py-myY)^2+(pz-myZ)^2)
                        if dist <= cfg.maxDistance and not isCharOnScreen(ped) then
                            local sx,sy = convert3DCoordsToScreen(px,py,pz+0.9)
                            if sx and sy then
                                -- Only draw arrows for projected points outside the visible area.
                                if sx < 0 or sx > sw or sy < 0 or sy > sh then
                                    drawOffscreenArrow(sx, sy, sw, sh, cfg.espColor)
                                end
                            end
                        end
                    end
                end
            end
        end
        for id=0,1000 do
            if sampIsPlayerConnected(id) then
                local result,ped = sampGetCharHandleBySampPlayerId(id)
                if result and doesCharExist(ped) and isCharOnScreen(ped) and not isCharDead(ped) and ped~=PLAYER_PED then
                    local px,py,pz = getCharCoordinates(ped)
                    local dist = math.sqrt((px-myX)^2+(py-myY)^2+(pz-myZ)^2)
                    if dist<=cfg.maxDistance then
                        local sx,sy = convert3DCoordsToScreen(px,py,pz+0.9)
                        local _,sy2 = convert3DCoordsToScreen(px,py,pz-0.9)
                        if sx and sy and sy2 then
                            if cfg.espSkeleton then
                                drawSkeleton(ped)
                            end
                            local boxH = math.abs(sy2-sy)
                            local boxW = boxH*0.5
                            local bx = sx-boxW/2
                            if cfg.espBox then
                                drawESPBox(bx-1,sy-1,boxW+2,boxH+2,1,0xCC000000,cfg.espBoxStyle)
                                if cfg.espBoxFill then
                                    local fillValue = tonumber(cfg.espBoxFillColor) or 0x665555FF
                                    local fr = math.floor(fillValue / 0x10000) % 256
                                    local fg = math.floor(fillValue / 0x100) % 256
                                    local fb = fillValue % 256
                                    local fa = math.floor(math.max(0, math.min(1, cfg.espBoxFillAlpha or 0.25)) * 255)
                                    local fillColor = fa * 0x1000000 + fr * 0x10000 + fg * 0x100 + fb
                                    drawRect(bx,sy,boxW,boxH,fillColor)
                                end
                                drawESPBox(bx,sy,boxW,boxH,cfg.espBoxThickness,cfg.espBoxColor,cfg.espBoxStyle)
                            end
                            if cfg.espName then
                                local name = sampGetPlayerNickname(id)
                                if name then
                                    local font = getFont(9,false)
                                    drawText(name, sx-(renderGetFontDrawTextLength(font,name)/2), sy-14, cfg.espColor, font)
                                end
                            end
                            if cfg.espWeapon or cfg.espWeaponIcon then
                                local weaponId = getCurrentCharWeapon(ped)
                                local yOffset = sy - (cfg.espName and 25 or 13)
                                if cfg.espWeaponIcon then
                                    drawWeaponIcon(sx, yOffset, weaponId, 0xFFFFFFFF, math.max(12.0, math.min(22.0, boxH * 0.28)))
                                    yOffset = yOffset - 13
                                end
                                if cfg.espWeapon then
                                    local weaponText = getWeaponName(weaponId)
                                    local font = getFont(8, false)
                                    drawText(weaponText, sx - (renderGetFontDrawTextLength(font, weaponText) / 2), yOffset, 0xFFFFFFFF, font)
                                end
                            end
                            if cfg.espHealth or cfg.espArmor then
                                local rawHp = tonumber(getCharHealth(ped)) or 0
                                local hp = math.max(0, math.min(100, rawHp / 10.0))
                                local armor = tonumber(getCharArmour(ped)) or 0
                                armor = math.max(0, math.min(100, armor))
                                if cfg.espHealth and cfg.espArmor then
                                    drawHealthArmorBars(sx,sy,boxW,boxH,hp,armor)
                                elseif cfg.espHealth then
                                    local barW = math.max(22, math.min(90, boxW * 1.65))
                                    local barH = 4
                                    local x = sx-barW/2; local y=sy+boxH+3
                                    local ratio=hp/100
                                    local color=hp>50 and 0xFF32E650 or (hp>20 and 0xFFFFC833 or 0xFFFF3333)
                                    drawRect(x-1,y-1,barW+2,barH+2,0xAA000000); drawRect(x,y,barW,barH,0x66333333)
                                    if ratio>0 then drawRect(x,y,barW*ratio,barH,color) end
                                    local font=getFont(7,false); local text=string.format('%d HP',math.floor(hp+0.5)); drawHealthIcon(x+1,y+2,0.65,color); drawText(text,x+7,y+5,color,font)
                                else
                                    local barW = math.max(22, math.min(90, boxW * 1.65))
                                    local barH = 4; local x=sx-barW/2; local y=sy+boxH+3
                                    local ratio=armor/100
                                    drawRect(x-1,y-1,barW+2,barH+2,0xAA000000); drawRect(x,y,barW,barH,0x66333333)
                                    if ratio>0 then drawRect(x,y,barW*ratio,barH,0xFFFFFFFF) end
                                    local font=getFont(7,false); local text=string.format('%d AP',math.floor(armor+0.5)); drawArmorIcon(x+1,y+2,0.65,0xFFFFFFFF); drawText(text,x+7,y+5,0xFFFFFFFF,font)
                                end
                            end
                            if cfg.espDistance then
                                local ds = string.format('%.0fm',dist)
                                local font = getFont(8,false)
                                drawText(ds, sx-(renderGetFontDrawTextLength(font,ds)/2), sy+boxH+((cfg.espHealth or cfg.espArmor) and 30 or 2), cfg.espDistanceColor, font)
                            end
                            if cfg.espLine then
                                local sw,sh = getScreenResolution()
                                local startX, startY = sw/2, sh
                                if cfg.espLineOrigin == 2 then
                                    startY = sh/2
                                elseif cfg.espLineOrigin == 3 then
                                    startY = 0
                                end
                                local targetX, targetY = sx, sy + boxH
                                if cfg.espLineTarget == 2 then
                                    local ok, hx, hy, hz = pcall(GetBodyPartCoordinates, 8, ped)
                                    if ok and hx and hy and hz then
                                        local hsx, hsy = convert3DCoordsToScreen(hx, hy, hz)
                                        if hsx and hsy then
                                            targetX, targetY = hsx, hsy
                                        end
                                    end
                                else
                                    local ok1, fx1, fy1, fz1 = pcall(GetBodyPartCoordinates, 44, ped)
                                    local ok2, fx2, fy2, fz2 = pcall(GetBodyPartCoordinates, 54, ped)
                                    if ok1 and ok2 and fx1 and fx2 then
                                        local fsx1, fsy1 = convert3DCoordsToScreen(fx1, fy1, fz1)
                                        local fsx2, fsy2 = convert3DCoordsToScreen(fx2, fy2, fz2)
                                        if fsx1 and fsy1 and fsx2 and fsy2 then
                                            targetX, targetY = (fsx1 + fsx2) / 2, (fsy1 + fsy2) / 2
                                        end
                                    end
                                end
                                renderDrawLine(startX,startY,targetX,targetY,cfg.espLineThickness,cfg.espLineColor)
                            end
                        end
                    end
                end
            end
        end
    end
    if cfg.mineEspEnabled then
        for i=0,32768 do
            if doesObjectExist(i) then
                local model = getObjectModel(i)
                if mineOreModels[model] then
                    local ox,oy,oz = getObjectCoordinates(i)
                    local dist = math.sqrt((ox-myX)^2+(oy-myY)^2+(oz-myZ)^2)
                    if dist<=cfg.mineMaxDist then
                        local sx,sy = convert3DCoordsToScreen(ox,oy,oz)
                        if sx and sy then
                            local font = getFont(9,true)
                            local txt = string.format("[ORE] %.0fm",dist)
                            drawText(txt, sx-(renderGetFontDrawTextLength(font,txt)/2), sy, 0xFFFFCC00, font)
                        end
                    end
                end
            end
        end
    end
    if adminAlertActive then
        local sw,sh = getScreenResolution()
        local font = getFont(14,true)
        local warn = "WARNING: ADMIN SPECTATING YOU!"
        drawText(warn,(sw-renderGetFontDrawTextLength(font,warn))/2, sh*0.2, 0xFFFF2222, font)
    end

    if cfg.kickerEnabled and isCharInAnyCar(PLAYER_PED) and getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED)) == 1 then
        local sw, sh = getScreenResolution()
        local cxx, cyy = sw/2, sh/2.5
        local radius = cfg.kickerRadius
        local seg = 48
        for i=0,seg-1 do
            local a1=(i/seg)*math.pi*2
            local a2=((i+1)/seg)*math.pi*2
            renderDrawLine(cxx+math.cos(a1)*radius, cyy+math.sin(a1)*radius, cxx+math.cos(a2)*radius, cyy+math.sin(a2)*radius, 1, 0xAAFF6600)
        end
        if not cfg.kickerSync then
            local vid = getNearCharToCenterInRadius(cfg.kickerRadius)
            if vid ~= -1 then
                local ok, ped = sampGetCharHandleBySampPlayerId(vid)
                if ok then
                    local x, y, z = getCharCoordinates(ped)
                    local sx, sy = convert3DCoordsToScreen(x, y, z + 0.9)
                    if sx and sy then
                        local nick = sampGetPlayerNickname(vid) or ("ID "..vid)
                        local font = getFont(9, true)
                        drawText(nick, sx - renderGetFontDrawTextLength(font, nick)/2, sy - 20, 0xFFFF8800, font)
                        drawText("[KICKER]", sx - renderGetFontDrawTextLength(font, "[KICKER]")/2, sy - 8, 0xFFFF3300, font)
                        drawRect(sx - 3, sy - 3, 6, 6, 0xFFFF8800)
                    end
                end
            end
        end
    end
end

function sampev.onWindowMessage(msg,wparam,lparam)
    if isEditingRouteName then
        if msg==0x100 then
            if wparam==0x0D then isEditingRouteName=false; route.name=routeNameBuffer
            elseif wparam==0x08 then if #routeNameBuffer>0 then routeNameBuffer=routeNameBuffer:sub(1,-2) end end
        elseif msg==0x102 then
            if wparam>=32 and wparam<=126 then routeNameBuffer=routeNameBuffer..string.char(wparam) end
        end
    end
    if isEditingSpamText then
        if msg==0x100 then
            if wparam==0x0D then isEditingSpamText=false; cfg.ahkSpamText=spamTextBuffer
            elseif wparam==0x08 then if #spamTextBuffer>0 then spamTextBuffer=spamTextBuffer:sub(1,-2) end end
        elseif msg==0x102 then
            if wparam>=32 and wparam<=126 then spamTextBuffer=spamTextBuffer..string.char(wparam) end
        end
    end
    if msg==0x020A and cfg.wheelTeleportEnabled then teleportToSight() end
end

local function updateAntiAFK()
    if not cfg.antiAfkEnabled or not isPlayerPlaying(PLAYER_HANDLE) then return end
    if now()-antiAfkTimer>=20.0 then
        setVirtualKeyDown(0x02,true)
        lua_thread.create(function() wait(50); setVirtualKeyDown(0x02,false) end)
        antiAfkTimer=now()
    end
end

local function updateAdminChecker()
    if not cfg.adminCheckerEnabled or not isPlayerPlaying(PLAYER_HANDLE) then return end
    local found = false
    for id=0,1000 do
        if sampIsPlayerConnected(id) then
            local name = sampGetPlayerNickname(id)
            if name and (name:find("Admin") or name:find("Helper") or name:find("A_")) then
                local result,ped = sampGetCharHandleBySampPlayerId(id)
                if result and doesCharExist(ped) then found=true end
            end
        end
    end
    adminAlertActive = found
end

local function updateAHK()
    if not isPlayerPlaying(PLAYER_HANDLE) or sampIsChatInputActive() or sampIsDialogActive() then return end
    if cfg.ahkAutoH then
        if now()-autoHTimer>=0.3 then
            setVirtualKeyDown(0x48,true)
            lua_thread.create(function() wait(50); setVirtualKeyDown(0x48,false) end)
            autoHTimer=now()
        end
    end
    if cfg.ahkFastTimeKey and wasKeyPressed(0x71) then sampSendChat("/time") end
    if cfg.ahkFastDlKey and wasKeyPressed(0x72) then sampSendChat("/dl") end
    if cfg.ahkFastHeal and wasKeyPressed(0x73) then sampSendChat("/heal") end
    if cfg.ahkSpammer then
        if now()-spamTimer>=cfg.ahkSpamDelay then
            if cfg.ahkSpamText and cfg.ahkSpamText~="" then sampSendChat(cfg.ahkSpamText) end
            spamTimer=now()
        end
    end
end

local function inRect(px,py,x,y,w,h) return px>=x and px<=x+w and py>=y and py<=y+h end

-- ============================================================
-- MIMGUI INTERFACE ONLY
-- All controls below edit the existing cfg/route variables.
-- No gameplay logic is changed here.
-- ============================================================
local uiFontScale = 1.0

-- Lightweight animated snow effect for the main window.
-- Particles are created once and only their positions are updated each frame.
local snowflakes = {}
local snowflakeCount = 42
local snowflakeLastTime = os.clock()
local snowflakeInitialized = false

local function initSnowflakes(w, h)
    if snowflakeInitialized then return end
    snowflakeInitialized = true
    for i = 1, snowflakeCount do
        snowflakes[i] = {
            x = math.random() * math.max(1, w),
            y = math.random() * math.max(1, h),
            speed = 12 + math.random() * 22,
            drift = 5 + math.random() * 11,
            phase = math.random() * math.pi * 2,
            size = 1.0 + math.random() * 1.6,
            alpha = 70 + math.random(0, 70)
        }
    end
end

local function drawSnowflakes()
    local now = os.clock()
    local dt = math.min(now - snowflakeLastTime, 0.05)
    snowflakeLastTime = now

    local winPos = imgui.GetWindowPos()
    local winSize = imgui.GetWindowSize()
    local w, h = winSize.x, winSize.y
    initSnowflakes(w, h)

    local drawList = imgui.GetWindowDrawList()
    local snowColor = 0xB8FFFFFF

    for i = 1, #snowflakes do
        local f = snowflakes[i]
        f.y = f.y + f.speed * dt
        f.phase = f.phase + dt * 0.7
        f.x = f.x + math.sin(f.phase) * f.drift * dt

        if f.y > h + 8 then
            f.y = -8
            f.x = math.random() * math.max(1, w)
        end
        if f.x < -8 then f.x = w + 8 end
        if f.x > w + 8 then f.x = -8 end

        drawList:AddCircleFilled(
            imgui.ImVec2(winPos.x + f.x, winPos.y + f.y),
            f.size,
            snowColor,
            8
        )
    end
end
local spamInput = ffi.new('char[256]')
local routeInput = ffi.new('char[128]')
ffi.copy(spamInput, cfg.ahkSpamText or '')
ffi.copy(routeInput, route.name or 'route1')

local function syncTextBuffer(buf, text, size)
    text = tostring(text or '')
    if #text >= size then text = text:sub(1, size - 1) end
    ffi.fill(buf, size, 0)
    ffi.copy(buf, text)
end

local uiAnim = { alpha = 0.0, target = 0.0, tabs = {}, toggles = {} }
local uiAnimLast = os.clock()

local function uiLerp(a, b, t)
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    return a + (b - a) * t
end

local function setupStyle()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    style.WindowPadding = imgui.ImVec2(18, 16)
    style.FramePadding = imgui.ImVec2(6, 5)
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.TouchExtraPadding = imgui.ImVec2(0, 0)
    style.IndentSpacing = 0
    style.ScrollbarSize = 8
    style.GrabMinSize = 10
    style.WindowBorderSize = 0
    style.ChildBorderSize = 0
    style.PopupBorderSize = 0
    style.FrameBorderSize = 0
    style.WindowRounding = 12
    style.ChildRounding = 10
    style.FrameRounding = 8
    style.PopupRounding = 8
    style.ScrollbarRounding = 8
    style.GrabRounding = 8
    style.TabRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.0, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    local c = imgui.Col
    style.Colors[c.Text] = imgui.ImVec4(0.10, 0.10, 0.12, 1.00)
    style.Colors[c.TextDisabled] = imgui.ImVec4(0.48, 0.48, 0.52, 1.00)
    style.Colors[c.WindowBg] = imgui.ImVec4(0.98, 0.98, 0.985, 0.98)
    style.Colors[c.ChildBg] = imgui.ImVec4(0.98, 0.98, 0.985, 0.00)
    style.Colors[c.PopupBg] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    style.Colors[c.Border] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.BorderShadow] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.FrameBg] = imgui.ImVec4(0.93, 0.93, 0.95, 1.00)
    style.Colors[c.FrameBgHovered] = imgui.ImVec4(0.90, 0.90, 0.93, 1.00)
    style.Colors[c.FrameBgActive] = imgui.ImVec4(0.86, 0.86, 0.90, 1.00)
    style.Colors[c.TitleBg] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.TitleBgActive] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.TitleBgCollapsed] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.MenuBarBg] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.Separator] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.SeparatorHovered] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.SeparatorActive] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.ScrollbarBg] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.ScrollbarGrab] = imgui.ImVec4(0.75, 0.75, 0.78, 1.00)
    style.Colors[c.ScrollbarGrabHovered] = imgui.ImVec4(0.62, 0.62, 0.66, 1.00)
    style.Colors[c.ScrollbarGrabActive] = imgui.ImVec4(0.52, 0.52, 0.56, 1.00)
    style.Colors[c.CheckMark] = imgui.ImVec4(0.48, 0.28, 0.88, 1.00)
    style.Colors[c.SliderGrab] = imgui.ImVec4(0.48, 0.28, 0.88, 1.00)
    style.Colors[c.SliderGrabActive] = imgui.ImVec4(0.40, 0.20, 0.78, 1.00)
    style.Colors[c.Button] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[c.ButtonHovered] = imgui.ImVec4(0.48, 0.28, 0.88, 0.10)
    style.Colors[c.ButtonActive] = imgui.ImVec4(0.48, 0.28, 0.88, 0.16)
end

local function ToggleButton(label, boolRef, speed)
    local p = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()
    local h = imgui.GetTextLineHeightWithSpacing()
    local w = h * 1.7
    local r = h / 2
    local s = speed or 0.2
    local changed = false

    if imgui.InvisibleButton('##toggle_' .. label, imgui.ImVec2(w, h)) then
        boolRef[0] = not boolRef[0]
        uiAnim.toggles[label] = { t = boolRef[0] and 1 or 0, last = os.clock() }
        changed = true
    end

    local st = uiAnim.toggles[label]
    if not st then st = { t = boolRef[0] and 1 or 0, last = os.clock() }; uiAnim.toggles[label] = st end
    local target = boolRef[0] and 1 or 0
    st.t = uiLerp(st.t, target, math.min(1, (os.clock() - st.last) / s))
    st.last = os.clock()

    local activeCol = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
    local textCol = imgui.GetStyle().Colors[imgui.Col.Text]
    dl:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + w, p.y + h), imgui.GetColorU32Vec4(activeCol), r)
    dl:AddCircleFilled(imgui.ImVec2(p.x + r + st.t * (w - r * 2), p.y + r), r * (0.82 + 0.18 * st.t), imgui.GetColorU32Vec4(textCol), 32)
    dl:AddText(imgui.ImVec2(p.x + w + r, p.y + r - imgui.CalcTextSize(label).y / 2), imgui.GetColorU32Vec4(textCol), label)
    return changed
end

local function section(title, description)
    imgui.Spacing()
    imgui.Text(title)
    if description then
        imgui.SameLine()
        imgui.TextDisabled(description)
    end
    imgui.Separator()
    imgui.Spacing()
end

local espPersistKeys = {
    espEnabled=true, espBox=true, espName=true, espHealth=true, espArmor=true, espDistance=true, espLine=true,
    espSkeleton=true, maxDistance=true, espBoxThickness=true, espLineThickness=true, espSkeletonThickness=true,
    espColor=true, espBoxColor=true, espBoxFill=true, espBoxFillColor=true, espBoxFillAlpha=true, espBoxStyle=true, espOffscreenArrows=true, espLineColor=true, espDistanceColor=true, espSkeletonColor=true
}

local function checkbox(label, key)
    local v = imgui.new.bool(cfg[key] and true or false)
    if ToggleButton(label, v, 0.16) then
        cfg[key] = v[0]
        if espPersistKeys[key] then markESPDirty() end
    end
end

local function checkboxWithPopup(label, key, popupId, drawSettings)
    local v = imgui.new.bool(cfg[key] and true or false)
    if ToggleButton(label, v, 0.16) then
        cfg[key] = v[0]
        if espPersistKeys[key] then markESPDirty() end
    end
    if imgui.IsMouseClicked(1) and imgui.IsItemHovered() then imgui.OpenPopup(popupId) end
    if imgui.BeginPopup(popupId) then
        imgui.Text(label .. ' Settings')
        imgui.Separator()
        drawSettings()
        imgui.EndPopup()
    end
end

local sliderLastMouseX = {}

local function slider(label, key, minv, maxv, fmt)
    local v = imgui.new.float(tonumber(cfg[key]) or minv)

    -- Keep the visual track exactly on top of ImGui's real slider frame.
    -- SliderFloat puts the label to the right of the frame, so the frame
    -- itself occupies the full calculated item width before the label.
    local cursor = imgui.GetCursorScreenPos()
    local avail = imgui.GetContentRegionAvail().x
    local style = imgui.GetStyle()
    -- SliderFloat's frame uses CalcItemWidth(), which is the full available
    -- width. The text label is added AFTER the frame, so do not subtract the
    -- label width here. That was the source of the post-release offset.
    local trackX = cursor.x
    local trackW = math.max(1, avail)
    local trackH = imgui.GetTextLineHeight() + style.FramePadding.y * 2

    local draw = imgui.GetWindowDrawList()
    local bg = imgui.GetColorU32Vec4(imgui.ImVec4(0.10, 0.075, 0.13, 1.00))
    local fillVec = imgui.ImVec4(0.58, 0.23, 0.82, 1.00)

    local oldFrameBorder = style.FrameBorderSize
    style.FrameBorderSize = 0

    -- Hide ImGui's own frame and grab. We draw the entire visual slider below.
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0, 0, 0, 0))
    imgui.PushStyleColor(imgui.Col.FrameBgHovered, imgui.ImVec4(0, 0, 0, 0))
    imgui.PushStyleColor(imgui.Col.FrameBgActive, imgui.ImVec4(0, 0, 0, 0))
    local transparentGrab = imgui.ImVec4(0, 0, 0, 0)
    imgui.PushStyleColor(imgui.Col.SliderGrab, transparentGrab)
    imgui.PushStyleColor(imgui.Col.SliderGrabActive, transparentGrab)

    local changed = imgui.SliderFloat(label, v, minv, maxv, fmt or '%.1f')
    local active = imgui.IsItemActive()
    local hovered = imgui.IsItemHovered()
    local mouseX = imgui.GetIO().MousePos.x

    -- Remember the exact mouse position while this slider is being dragged.
    -- After LMB is released ImGui's item is no longer active, and recalculating
    -- the visual fill from an estimated grab width can shift it left/right.
    -- Keeping the last real cursor X makes the visual fill stay exactly where
    -- the cursor released the slider.
    if active then
        sliderLastMouseX[key] = mouseX
    end

    imgui.PopStyleColor(5)
    style.FrameBorderSize = oldFrameBorder

    if changed then
        cfg[key] = v[0]
        if espPersistKeys[key] then markESPDirty() end
    end

    -- Use the actual mouse X while dragging. This removes the last possible
    -- mismatch between the hidden ImGui grab and our custom purple fill.
    local t = (tonumber(v[0]) - minv) / (maxv - minv)
    t = math.max(0, math.min(1, t))

    local fillEnd

    if active then
        fillEnd = math.max(trackX, math.min(trackX + trackW, mouseX))
    elseif sliderLastMouseX[key] ~= nil then
        -- Use the exact position from the last drag instead of trying to
        -- reconstruct ImGui's internal grab geometry.
        fillEnd = math.max(trackX, math.min(trackX + trackW, sliderLastMouseX[key]))
    else
        -- Initial/programmatic value: map it across the full visual track.
        fillEnd = trackX + trackW * t
    end

    draw:AddRectFilled(
        imgui.ImVec2(trackX, cursor.y),
        imgui.ImVec2(trackX + trackW, cursor.y + trackH),
        bg, 5.0
    )

    if fillEnd > trackX then
        draw:AddRectFilled(
            imgui.ImVec2(trackX, cursor.y),
            imgui.ImVec2(fillEnd, cursor.y + trackH),
            imgui.GetColorU32Vec4(fillVec), 0.0
        )
    end

    -- Draw the current value on top of our custom track. The custom fill is
    -- drawn after SliderFloat, so it would otherwise cover ImGui's value text.
    local valueText = string.format(fmt or '%.1f', tonumber(v[0]) or minv)
    local valueSize = imgui.CalcTextSize(valueText)
    local valueX = trackX + (trackW - valueSize.x) * 0.5
    local valueY = cursor.y + (trackH - valueSize.y) * 0.5
    local textColor = imgui.GetColorU32Vec4(style.Colors[imgui.Col.Text])
    draw:AddText(imgui.ImVec2(valueX, valueY), textColor, valueText)
end

local function colorChannels(value)
    value = tonumber(value) or 0xFFFFFFFF
    local a = math.floor(value / 0x1000000) % 256
    local r = math.floor(value / 0x10000) % 256
    local g = math.floor(value / 0x100) % 256
    local b = value % 256
    return r / 255, g / 255, b / 255, a / 255
end

local function makeColor(r, g, b, a)
    local ri = math.floor(math.max(0, math.min(1, r)) * 255 + 0.5)
    local gi = math.floor(math.max(0, math.min(1, g)) * 255 + 0.5)
    local bi = math.floor(math.max(0, math.min(1, b)) * 255 + 0.5)
    local ai = math.floor(math.max(0, math.min(1, a)) * 255 + 0.5)
    return ai * 0x1000000 + ri * 0x10000 + gi * 0x100 + bi
end

local function colorEditor(label, key)
    local r, g, b, a = colorChannels(cfg[key])
    -- Full ImGui color picker: click the color field to open the hue/saturation
    -- picker, brightness bar and alpha control. No RGB sliders are needed.
    local color = imgui.new.float[4](r, g, b, a)
    if imgui.ColorEdit4(label .. '##' .. key, color) then
        cfg[key] = makeColor(color[0], color[1], color[2], color[3])
        if espPersistKeys[key] then markESPDirty() end
    end
end

local function actionButton(label, fn, width)
    if imgui.Button(label, imgui.ImVec2(width or 0, 0)) then fn() end
end

local tabs = {
    { 'Aim',  'Aimbot', 'crosshairs' },
    { 'ESP',  'Visuals', 'eye' },
    { 'AHK',  'Automation', 'gears' },
    { 'Set',  'Settings', 'sliders' },
    { 'Bot',  'Route Bot', 'route' },
    { 'RWH',  'Rvanka', 'bolt' }
}

local function drawAir()
    section('Air / Movement', 'Movement controls')
    checkbox('Enable AirBrake', 'brakeEnabled')
    slider('Speed Multiplier', 'speed', cfg.minSpeed, cfg.maxSpeed, '%.2f')
    checkbox('Teleport on Mouse Wheel', 'wheelTeleportEnabled')
    imgui.TextDisabled('Wheel teleport uses the current map marker / target coordinates.')
end

local function espPreviewColor(hex)
    return hex
end

local function drawCJPreview()
    local pos = imgui.GetCursorScreenPos()
    local size = imgui.GetContentRegionAvail()
    local w = math.max(260, size.x)
    local h = math.max(330, size.y)
    local dl = imgui.GetWindowDrawList()
    local cx = pos.x + w * 0.50
    local top = pos.y + 24
    local bottom = pos.y + h - 18

    -- Clean preview area, no frame.
    dl:AddRectFilled(imgui.ImVec2(pos.x, pos.y), imgui.ImVec2(pos.x + w, pos.y + h), 0x0A000000, 12)
    dl:AddText(imgui.ImVec2(pos.x + 18, pos.y + 14), 0xFF55555D, 'ESP Preview')

    local scale = math.min(1.0, (h - 70) / 360)
    local headR = 25 * scale
    local headY = top + 45 * scale
    local shoulderY = top + 90 * scale
    local hipY = top + 210 * scale
    local footY = bottom - 4
    local bodyW = 82 * scale
    local legW = 27 * scale

    -- CJ-like NPC silhouette.
    dl:AddCircleFilled(imgui.ImVec2(cx, headY), headR, 0xFFD6A078, 32)
    dl:AddRectFilled(imgui.ImVec2(cx - bodyW/2, shoulderY), imgui.ImVec2(cx + bodyW/2, hipY), 0xFF20252C, 10)
    dl:AddRectFilled(imgui.ImVec2(cx - bodyW/2 - 9*scale, shoulderY + 7*scale), imgui.ImVec2(cx - bodyW/2 + 8*scale, hipY - 4*scale), 0xFFD6A078, 7)
    dl:AddRectFilled(imgui.ImVec2(cx + bodyW/2 - 8*scale, shoulderY + 7*scale), imgui.ImVec2(cx + bodyW/2 + 9*scale, hipY - 4*scale), 0xFFD6A078, 7)
    dl:AddRectFilled(imgui.ImVec2(cx - 32*scale, hipY - 2*scale), imgui.ImVec2(cx + 32*scale, hipY + 26*scale), 0xFF31363D, 5)
    dl:AddRectFilled(imgui.ImVec2(cx - 31*scale, hipY + 22*scale), imgui.ImVec2(cx - 4*scale, footY), 0xFF3A4B68, 5)
    dl:AddRectFilled(imgui.ImVec2(cx + 4*scale, hipY + 22*scale), imgui.ImVec2(cx + 31*scale, footY), 0xFF3A4B68, 5)
    dl:AddRectFilled(imgui.ImVec2(cx - 38*scale, footY - 5*scale), imgui.ImVec2(cx - 3*scale, footY + 5*scale), 0xFF181A1F, 4)
    dl:AddRectFilled(imgui.ImVec2(cx + 3*scale, footY - 5*scale), imgui.ImVec2(cx + 38*scale, footY + 5*scale), 0xFF181A1F, 4)

    -- Preview ESP follows exactly the enabled settings.
    local boxTop = headY - headR - 10*scale
    local boxBottom = footY + 8*scale
    local boxLeft = cx - 58*scale
    local boxRight = cx + 58*scale

    if cfg.espBox then
        local col = tonumber(cfg.espBoxColor) or 0xFFFF5555
        if cfg.espBoxStyle == 2 then
            local l = 18*scale
            local t = 22*scale
            dl:AddLine(imgui.ImVec2(boxLeft, boxTop), imgui.ImVec2(boxLeft+l, boxTop), col, cfg.espBoxThickness or 1.5)
            dl:AddLine(imgui.ImVec2(boxLeft, boxTop), imgui.ImVec2(boxLeft, boxTop+t), col, cfg.espBoxThickness or 1.5)
            dl:AddLine(imgui.ImVec2(boxRight, boxTop), imgui.ImVec2(boxRight-l, boxTop), col, cfg.espBoxThickness or 1.5)
            dl:AddLine(imgui.ImVec2(boxRight, boxTop), imgui.ImVec2(boxRight, boxTop+t), col, cfg.espBoxThickness or 1.5)
            dl:AddLine(imgui.ImVec2(boxLeft, boxBottom), imgui.ImVec2(boxLeft+l, boxBottom), col, cfg.espBoxThickness or 1.5)
            dl:AddLine(imgui.ImVec2(boxLeft, boxBottom), imgui.ImVec2(boxLeft, boxBottom-t), col, cfg.espBoxThickness or 1.5)
            dl:AddLine(imgui.ImVec2(boxRight, boxBottom), imgui.ImVec2(boxRight-l, boxBottom), col, cfg.espBoxThickness or 1.5)
            dl:AddLine(imgui.ImVec2(boxRight, boxBottom), imgui.ImVec2(boxRight, boxBottom-t), col, cfg.espBoxThickness or 1.5)
        else
            dl:AddRect(imgui.ImVec2(boxLeft, boxTop), imgui.ImVec2(boxRight, boxBottom), col, 0, 0, cfg.espBoxThickness or 1.5)
        end
    end

    if cfg.espBoxFill then
        local fill = tonumber(cfg.espBoxFillColor) or 0x665555FF
        local alpha = math.max(0.05, math.min(0.65, tonumber(cfg.espBoxFillAlpha) or 0.25))
        local a = math.floor(alpha * 255)
        fill = (fill & 0x00FFFFFF) | (a << 24)
        dl:AddRectFilled(imgui.ImVec2(boxLeft+2, boxTop+2), imgui.ImVec2(boxRight-2, boxBottom-2), fill, 2)
    end

    if cfg.espName then
        dl:AddText(imgui.ImVec2(boxLeft, boxTop - 23*scale), tonumber(cfg.espColor) or 0xFF33CCFF, 'CJ')
    end

    if cfg.espHealth then
        local hpX = boxLeft - 10*scale
        dl:AddRectFilled(imgui.ImVec2(hpX, boxTop), imgui.ImVec2(hpX+4*scale, boxBottom), 0xFF333333, 2)
        dl:AddRectFilled(imgui.ImVec2(hpX, boxTop + (boxBottom-boxTop)*0.16), imgui.ImVec2(hpX+4*scale, boxBottom), 0xFF42D66B, 2)
    end

    if cfg.espArmor then
        local arX = boxRight + 7*scale
        dl:AddRectFilled(imgui.ImVec2(arX, boxTop), imgui.ImVec2(arX+4*scale, boxBottom), 0xFF333333, 2)
        dl:AddRectFilled(imgui.ImVec2(arX, boxTop + (boxBottom-boxTop)*0.28), imgui.ImVec2(arX+4*scale, boxBottom), 0xFFE7E7E7, 2)
    end

    if cfg.espDistance then
        dl:AddText(imgui.ImVec2(boxLeft, boxBottom + 8*scale), tonumber(cfg.espDistanceColor) or 0xFFCCCCCC, '24 m')
    end

    if cfg.espWeapon then
        dl:AddText(imgui.ImVec2(boxLeft, boxBottom + 26*scale), tonumber(cfg.espColor) or 0xFF33CCFF, 'Fist')
    end

    if cfg.espWeaponIcon then
        dl:AddCircleFilled(imgui.ImVec2(boxRight + 22*scale, boxBottom + 18*scale), 7*scale, 0xFF77777F, 16)
    end

    if cfg.espSkeleton then
        local sc = tonumber(cfg.espSkeletonColor) or 0xFF33CCFF
        local st = tonumber(cfg.espSkeletonThickness) or 1.5
        dl:AddLine(imgui.ImVec2(cx, headY+headR), imgui.ImVec2(cx, shoulderY+18*scale), sc, st)
        dl:AddLine(imgui.ImVec2(cx, shoulderY+18*scale), imgui.ImVec2(cx-28*scale, hipY), sc, st)
        dl:AddLine(imgui.ImVec2(cx, shoulderY+18*scale), imgui.ImVec2(cx+28*scale, hipY), sc, st)
        dl:AddLine(imgui.ImVec2(cx-28*scale, hipY), imgui.ImVec2(cx-18*scale, footY), sc, st)
        dl:AddLine(imgui.ImVec2(cx+28*scale, hipY), imgui.ImVec2(cx+18*scale, footY), sc, st)
    end

    if cfg.espLine then
        local lc = tonumber(cfg.espLineColor) or 0xFF33CCFF
        local lt = tonumber(cfg.espLineThickness) or 1.5
        local fromY = cfg.espLineOrigin == 2 and pos.y + h*0.5 or (cfg.espLineOrigin == 3 and pos.y + 24 or pos.y + h - 10)
        local toY = cfg.espLineTarget == 2 and headY or footY
        dl:AddLine(imgui.ImVec2(pos.x + 22, fromY), imgui.ImVec2(cx, toY), lc, lt)
    end

    if cfg.espOffscreenArrows then
        local ax, ay = pos.x + w - 34, pos.y + 42
        dl:AddTriangleFilled(imgui.ImVec2(ax, ay), imgui.ImVec2(ax-12, ay+18), imgui.ImVec2(ax+12, ay+18), tonumber(cfg.espColor) or 0xFF33CCFF)
    end

    imgui.Dummy(imgui.ImVec2(w, h))
end

local function drawESPPage()
    imgui.Text('ESP')
    imgui.SameLine()
    imgui.TextDisabled('Live preview')
    imgui.Spacing()

    local avail = imgui.GetContentRegionAvail()
    local leftW = math.max(300, avail.x * 0.48)
    local rightW = math.max(280, avail.x - leftW - 16)

    imgui.BeginChild('##esp_controls', imgui.ImVec2(leftW, math.max(1, avail.y)), false)
        checkbox('Enable ESP', 'espEnabled')
        checkboxWithPopup('Player Box', 'espBox', '##esp_box_popup', function()
            imgui.Text('Box Style')
            if imgui.Button(cfg.espBoxStyle == 1 and 'Full Box [X]' or 'Full Box', imgui.ImVec2(120, 28)) then cfg.espBoxStyle = 1; markESPDirty() end
            imgui.SameLine()
            if imgui.Button(cfg.espBoxStyle == 2 and 'Corner Box [X]' or 'Corner Box', imgui.ImVec2(120, 28)) then cfg.espBoxStyle = 2; markESPDirty() end
            slider('Thickness', 'espBoxThickness', 1.0, 5.0, '%.1f px')
            colorEditor('Box Color', 'espBoxColor')
        end)
        checkbox('Box Fill', 'espBoxFill')
        if cfg.espBoxFill then
            colorEditor('Fill Color', 'espBoxFillColor')
            slider('Fill Opacity', 'espBoxFillAlpha', 0.05, 0.65, '%.2f')
        end
        checkboxWithPopup('Player Name', 'espName', '##esp_name_popup', function() colorEditor('Name Color', 'espColor') end)
        checkboxWithPopup('Health', 'espHealth', '##esp_health_popup', function() imgui.TextDisabled('Automatic HP color') end)
        checkboxWithPopup('Armor', 'espArmor', '##esp_armor_popup', function() imgui.TextDisabled('Armor bar preview') end)
        checkboxWithPopup('Distance', 'espDistance', '##esp_distance_popup', function() colorEditor('Distance Color', 'espDistanceColor') end)
        checkbox('Players in Radius', 'espPlayerCount')
        checkboxWithPopup('Weapon Text', 'espWeapon', '##esp_weapon_text_popup', function() colorEditor('Weapon Text Color', 'espColor') end)
        checkboxWithPopup('Weapon Icon', 'espWeaponIcon', '##esp_weapon_icon_popup', function() colorEditor('Weapon Icon Color', 'espColor') end)
        checkboxWithPopup('Snaplines', 'espLine', '##esp_line_popup', function()
            slider('Thickness', 'espLineThickness', 1.0, 5.0, '%.1f px')
            colorEditor('Snapline Color', 'espLineColor')
        end)
        checkboxWithPopup('Off-screen Arrows', 'espOffscreenArrows', '##esp_arrow_popup', function() colorEditor('Arrow Color', 'espColor') end)
        checkboxWithPopup('Skeleton', 'espSkeleton', '##esp_skeleton_popup', function()
            slider('Thickness', 'espSkeletonThickness', 1.0, 5.0, '%.1f px')
            colorEditor('Skeleton Color', 'espSkeletonColor')
        end)
        imgui.Spacing()
        if imgui.Button('ESP Editor', imgui.ImVec2(-1, 34)) then cfg.espEditorOpen = true end
    imgui.EndChild()

    imgui.SameLine()
    imgui.BeginChild('##esp_preview', imgui.ImVec2(rightW, math.max(1, avail.y)), false)
        drawCJPreview()
    imgui.EndChild()
end

local function drawMine()
    section('Mine Wallhack', 'Ore markers')
    checkbox('Enable Mine Ore WH', 'mineEspEnabled')
    slider('Max Draw Distance', 'mineMaxDist', 50.0, 300.0, '%.0f m')
    imgui.TextDisabled('Supported ore models are handled by the existing script logic.')
end

local function drawCar()
    section('Vehicle Movement', 'Speed and flight')
    checkbox('Speedhack', 'carSpeedhackEnabled')
    imgui.TextDisabled('Hold ALT to smoothly add forward speed.')

    imgui.Spacing()
    checkbox('Car Fly', 'carFlyEnabled')
    imgui.TextDisabled('Use W/A/S/D to fly. Space = up, Shift = down. Acceleration is smooth.')
end

local function drawRadioButton(label, active)
    -- Compatibility helper for mimgui builds without imgui.RadioButton.
    local prefix = active and "[*] " or "[ ] "
    return imgui.Button(prefix .. label)
end

local function drawAim()
    section('Aimbot', 'Targeting controls')
    checkbox('Enable Aimbot', 'aimEnabled')

    imgui.Text('Aimbot Mode')
    local silent = cfg.aimType == 1
    local smooth = cfg.aimType == 2
    if drawRadioButton('Silent', silent) then cfg.aimType = 1 end
    imgui.SameLine(0, 24)
    if drawRadioButton('Smooth', smooth) then cfg.aimType = 2 end

    imgui.Spacing()

    if cfg.aimType == 2 then
        section('Smooth Aimbot', 'Settings for Smooth mode only')
        imgui.Columns(2, 'aim_flags', false)
        checkbox('Only when shooting', 'aimIsFire')
        checkbox('Visible Check', 'aimVisibleCheck')
        checkbox('Dynamic Smooth', 'aimDynamicSmooth')
        checkbox('Ignore Range', 'aimIgnoreRange')
        imgui.NextColumn()
        checkbox('Ignore Stun', 'aimIgnoreStun')
        checkbox('Draw FOV Circle', 'aimDrawFov')
        checkbox('Draw Shoot Marker', 'aimDrawShoot')
        imgui.Columns(1)

        slider('FOV Radius', 'aimFov', 1.0, 30.0, '%.1f')
        imgui.TextDisabled('Search radius around the crosshair.')
        slider('Smooth', 'aimSmooth', 1.0, 25.0, '%.1f')
        imgui.TextDisabled('Higher value = slower and smoother aiming.')
        slider('Super Smooth', 'aimSuperSmooth', 1.0, 25.0, '%.1f')
        imgui.TextDisabled('Additional smoothing for the aim movement.')
        slider('Safe Zone', 'aimSafe', 1.0, 300.0, '%.1f px')
        imgui.TextDisabled('Dead-zone around the crosshair.')
    else
        section('Silent Aimbot', 'Settings for Silent mode only')
        checkbox('Shot through textures', 'silentShotText')
        checkbox('Show Silent Radius', 'silentShowRadius')
        slider('Silent Distance', 'silentDistance', 1.0, 500.0, '%.1f m')
        imgui.TextDisabled('Maximum distance for Silent Aim.')
        slider('Miss Chance', 'silentMissChance', 0.0, 100.0, '%.1f %%')
        imgui.TextDisabled('Chance to intentionally miss a shot.')
        slider('Silent Radius', 'silentRadius', 1.0, 300.0, '%.1f px')
        imgui.TextDisabled('Screen radius used to find Silent Aim targets.')
    end

    imgui.Spacing()
    imgui.Text('Target Bone')
    if drawRadioButton('Body', cfg.aimBone == 1) then cfg.aimBone = 1 end
    imgui.SameLine(0, 24)
    if drawRadioButton('Head', cfg.aimBone == 2) then cfg.aimBone = 2 end
end

local function drawAHK()
    section('Chat Spammer', 'Automatic chat messages')
    checkbox('Enable Chat Spammer', 'ahkSpammer')
    slider('Spam Delay', 'ahkSpamDelay', 1.0, 10.0, '%.1f sec')
    imgui.SetNextItemWidth(-1)
    if imgui.InputText('Spam Text', spamInput, 256) then
        cfg.ahkSpamText = ffi.string(spamInput)
        spamTextBuffer = cfg.ahkSpamText
    end

    section('Utilities', 'Quality-of-life tools')
    checkbox('Anti-AFK Protection', 'antiAfkEnabled')
    checkbox('Admin / Spectate Checker', 'adminCheckerEnabled')
    checkbox('Auto H', 'ahkAutoH')

    section('Fast Key Binds', 'Hotkeys')
    checkbox('Fast /time (F2)', 'ahkFastTimeKey')
    checkbox('Fast /dl (F3)', 'ahkFastDlKey')
    checkbox('Fast /heal (F4)', 'ahkFastHeal')
end

local hotkeyCapture = nil
local hotkeyWasDown = {}

local function keyName(vk)
    local names = {
        [0x08]='BACKSPACE', [0x09]='TAB', [0x0D]='ENTER', [0x10]='SHIFT', [0x11]='CTRL', [0x12]='ALT',
        [0x1B]='ESC', [0x20]='SPACE', [0x21]='PAGEUP', [0x22]='PAGEDOWN', [0x23]='END', [0x24]='HOME',
        [0x25]='LEFT', [0x26]='UP', [0x27]='RIGHT', [0x28]='DOWN', [0x2D]='INSERT', [0x2E]='DELETE',
        [0x70]='F1', [0x71]='F2', [0x72]='F3', [0x73]='F4', [0x74]='F5', [0x75]='F6',
        [0x76]='F7', [0x77]='F8', [0x78]='F9', [0x79]='F10', [0x7A]='F11', [0x7B]='F12'
    }
    if names[vk] then return names[vk] end
    if vk >= 0x30 and vk <= 0x39 then return string.char(vk) end
    if vk >= 0x41 and vk <= 0x5A then return string.char(vk) end
    if vk >= 0x60 and vk <= 0x69 then return 'NUM' .. tostring(vk - 0x60) end
    return string.format('VK 0x%02X', vk)
end

local hotkeyIniDefaults = {
    hotkeys = { menu = 0x2D, botStop = 0x2E, unload = 0x23 }
}
local hotkeyIni = inicfg.load(hotkeyIniDefaults, 'CheatUtility_Hotkeys')

local function loadHotkeys()
    local h = hotkeyIni.hotkeys or hotkeyIniDefaults.hotkeys
    cfg.menuKey = tonumber(h.menu) or 0x2D
    cfg.botStopKey = tonumber(h.botStop) or 0x2E
    cfg.unloadKey = tonumber(h.unload) or 0x23
    if cfg.menuKey == 0x75 then cfg.menuKey = 0x2D end
end

local function saveHotkeys()
    hotkeyIni.hotkeys = {
        menu = cfg.menuKey,
        botStop = cfg.botStopKey,
        unload = cfg.unloadKey
    }
    inicfg.save(hotkeyIni, 'CheatUtility_Hotkeys')
end

loadHotkeys()
if type(cfg.menuKey) ~= 'number' or cfg.menuKey < 1 or cfg.menuKey > 255 then
    cfg.menuKey = 0x2D
end

local function startHotkeyCapture(target)
    hotkeyCapture = target
    hotkeyWasDown = {}
end

local function processHotkeyCapture()
    if not hotkeyCapture then return false end
    for vk = 1, 255 do
        if vk ~= 0x75 and vk ~= 0x01 and vk ~= 0x02 and vk ~= 0x04 and vk ~= 0x05 then
            local down = isKeyDown(vk)
            if down and not hotkeyWasDown[vk] then
                cfg[hotkeyCapture] = vk
                saveHotkeys()
                hotkeyCapture = nil
                hotkeyWasDown = {}
                return true
            end
            hotkeyWasDown[vk] = down
        end
    end
    return true
end

local function hotkeyButton(label, target)
    local active = hotkeyCapture == target
    local text = active and 'Press a key...' or keyName(cfg[target])
    imgui.Text(label)
    imgui.SameLine()
    if imgui.Button(text .. '##' .. target, imgui.ImVec2(150, 30)) then
        startHotkeyCapture(target)
    end
    if active then
        imgui.SameLine()
        imgui.TextDisabled('press any key')
    end
end

local function drawSettings()
    section('Hotkeys', 'Only menu, bot and unload controls')
    hotkeyButton('Open / Hide Menu', 'menuKey')
    hotkeyButton('Bot Pause / Resume', 'botStopKey')
    hotkeyButton('Unload Cheat', 'unloadKey')
    imgui.TextDisabled('Menu: /load also works. F6 is removed.')

    imgui.Spacing()
    section('Settings', 'Script controls')
    imgui.TextDisabled('Unload the cheat script from MoonLoader.')
    imgui.Spacing()
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.48, 0.18, 0.68, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.58, 0.24, 0.78, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.39, 0.12, 0.56, 1.0))
    if imgui.Button('Unload Cheat', imgui.ImVec2(-1, 42)) then
        imgui.PopStyleColor(3)
        saveESPSettings()
        saveHotkeys()
        thisScript():unload()
        return
    end
    imgui.PopStyleColor(3)
end

local function drawBot()
    section('Route Bot', 'Record and replay routes')
    imgui.SetNextItemWidth(-1)
    if imgui.InputText('Route Name', routeInput, 128) then
        routeNameBuffer = ffi.string(routeInput)
        route.name = routeNameBuffer
    end

    imgui.Spacing()
    local half = (imgui.GetContentRegionAvail().x - 8) / 2
    if route.recording then
        actionButton('Stop Recording', function() route.recording = false end, half)
    else
        actionButton('Start Recording', function()
            route.recording=true
            route.playing=false
            route.points={}
            route.recordTimer=now()
            route.startTime=now()
            route.prevKey={w=false,a=false,s=false,d=false,run=false,alt=false,ctrl=false,jump=false,enter=false}
            releaseAllKeys()
        end, half)
    end
    imgui.SameLine()
    if route.playing then
        actionButton('Stop Playback', function()
            route.playing=false
            route.paused=false
            releaseAllKeys()
        end, half)
    else
        actionButton('Start Playback', function()
            if #route.points > 0 then
                route.playing=true
                route.recording=false
                route.paused=false
                route.playIndex=1
                route.playStartTime=now()
                releaseAllKeys()
            end
        end, half)
    end

    imgui.Spacing()
    local third = (imgui.GetContentRegionAvail().x - 16) / 3
    actionButton('Save', function() route.name=routeNameBuffer; saveRouteToFile() end, third)
    imgui.SameLine()
    actionButton('Load', function() route.name=routeNameBuffer; loadRouteFromFile() end, third)
    imgui.SameLine()
    actionButton('Clear', function() route.points={}; route.playIndex=1 end, third)

    imgui.Spacing()
    imgui.Text(string.format('Points recorded: %d', #route.points))
    if route.recording then
        imgui.TextDisabled('Status: RECORDING...')
    elseif route.playing and route.paused then
        imgui.TextDisabled('Status: PAUSED (bot hotkey to resume)')
    elseif route.playing then
        imgui.TextDisabled('Status: PLAYING (LOOP)')
        imgui.TextDisabled(string.format('Progress: %d / %d', route.playIndex, #route.points))
    else
        imgui.TextDisabled('Status: IDLE')
        imgui.TextDisabled('Controls: WASD + Shift + Alt + Ctrl + Space + Enter + Mouse')
    end
end

local function drawRWH()
    section('RWH', 'Sync tools')
    checkbox('Enable RWH', 'rwhEnabled')

    imgui.Text('Mode')
    local modes = {'Onfoot Rvanka','Vehicle Kicker','Car Upper','Car Destroyer','Lagger','Randomizer'}
    for i, name in ipairs(modes) do
        if drawRadioButton(name, cfg.rwhMode == i) then
            cfg.rwhMode=i
            cfg.rwhActive=false
            cfg.rwhSync=false
        end
        if i % 2 == 1 then imgui.SameLine(0, 22) end
    end

    imgui.Spacing()
    imgui.Text(string.format('Activation Key: 0x%02X', cfg.rwhKey))
    if imgui.Button('Set Default Key (R)', imgui.ImVec2(-1, 32)) then cfg.rwhKey=0x52 end
    slider('Search Radius', 'rwhRadius', 50.0, 400.0, '%.0f px')
    slider('Randomizer Offset', 'rwhOffset', 1.0, 20.0, '%.0f')

    if cfg.rwhMode == 3 or cfg.rwhMode == 4 then
        checkbox('Passenger Mode (safer)', 'rwhPassenger')
    end

    if cfg.rwhActive then
        imgui.TextDisabled('Status: ACTIVE')
    elseif cfg.rwhSync then
        imgui.TextDisabled('Status: SYNCING...')
    else
        imgui.TextDisabled('Status: IDLE')
    end

    imgui.Spacing()
    section('Vehicle Kicker', 'Target near the crosshair')
    checkbox('Enable Kicker', 'kickerEnabled')
    imgui.Text(string.format('Activation Key: 0x%02X', cfg.kickerKey))
    if imgui.Button('Set Default Key (R)', imgui.ImVec2(-1, 32)) then cfg.kickerKey=0x52 end
    slider('Search Radius', 'kickerRadius', 50.0, 400.0, '%.0f px')

    section('Kicker Info')
    imgui.TextDisabled('Works only when you are the driver.')
    imgui.TextDisabled('Aim at a target inside the circle.')
    imgui.TextDisabled('Press the activation key to kick.')
    if cfg.kickerSync then
        imgui.TextDisabled('Status: KICKING ID '..tostring(cfg.kickerTargetId))
    else
        imgui.TextDisabled('Status: IDLE')
    end
end

local function drawCurrentTab()
    if cfg.tab == 1 then drawAim()
    elseif cfg.tab == 2 then drawESPPage()
    elseif cfg.tab == 3 then drawAHK()
    elseif cfg.tab == 4 then drawSettings()
    elseif cfg.tab == 5 then drawBot()
    elseif cfg.tab == 6 then drawRWH()
    end
end

local function drawESPEditorWindow()
    if not cfg.espEditorOpen then return end

    imgui.SetNextWindowSize(imgui.ImVec2(520, 560), imgui.Cond.Always)
    local opened = imgui.Begin('ESP Editor##esp_editor', nil, imgui.WindowFlags.NoCollapse)

    if opened then
        imgui.Text('ESP Editor')
        imgui.TextDisabled('Colors and thickness')
        imgui.Separator()

        section('General', 'ESP distance')
        slider('Max Distance', 'maxDistance', 10.0, 300.0, '%.0f m')

        section('Colors', 'Individual ESP colors')
        colorEditor('Player Box', 'espBoxColor')
        colorEditor('Name / Weapon / Arrow', 'espColor')
        colorEditor('Distance', 'espDistanceColor')
        colorEditor('Snapline', 'espLineColor')
        colorEditor('Skeleton', 'espSkeletonColor')

        section('Thickness', 'Line and box thickness')
        slider('Player Box', 'espBoxThickness', 1.0, 5.0, '%.1f px')
        slider('Snapline', 'espLineThickness', 1.0, 5.0, '%.1f px')
        slider('Skeleton', 'espSkeletonThickness', 1.0, 5.0, '%.1f px')

        imgui.Spacing()
        if imgui.Button('Reset ESP Colors / Thickness', imgui.ImVec2(-1, 34)) then
            cfg.espBoxColor = 0xFFFF5555
            cfg.espBoxFillColor = 0x665555FF
            cfg.espBoxFillAlpha = 0.25
            cfg.espBoxFill = false
            cfg.espBoxStyle = 1
            cfg.espColor = 0xFF33CCFF
            cfg.espLineColor = 0xFF33CCFF
            cfg.espDistanceColor = 0xFFCCCCCC
            cfg.espSkeletonColor = 0xFF33CCFF
            cfg.espBoxThickness = 1.0
            cfg.espLineThickness = 1.5
            cfg.espSkeletonThickness = 1.5
            markESPDirty()
        end

        imgui.Spacing()
        if imgui.Button('Close Editor', imgui.ImVec2(-1, 34)) then
            cfg.espEditorOpen = false
        end
    end
    imgui.End()
end

local function CustomMenuItem(index, item, size, duration)
    local id = item[1] .. '##nav_' .. index
    local clicked = imgui.Selectable(item[2], cfg.tab == index, 0, size or imgui.ImVec2(92, 30))
    if clicked then cfg.tab = index end
    return clicked
end

local function drawMimguiMenu()
    setupStyle()
    local now = os.clock()
    local dt = math.min(0.05, now - uiAnimLast)
    uiAnimLast = now
    uiAnim.target = cfg.menuOpen and 1 or 0
    uiAnim.alpha = uiLerp(uiAnim.alpha, uiAnim.target, math.min(1, dt / 0.12))
    if uiAnim.alpha <= 0.001 and not cfg.menuOpen then return end

    local resX, resY = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(760, 500), imgui.Cond.FirstUseEver)
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, uiAnim.alpha)

    if imgui.Begin('##clean_menu', nil, imgui.WindowFlags.NoDecoration) then
        imgui.Text('Cheat Menu')
        imgui.SameLine()
        imgui.TextDisabled('')
        imgui.Spacing()

        for i, item in ipairs(tabs) do
            if i > 1 then imgui.SameLine() end
            CustomMenuItem(i, item, imgui.ImVec2(100, 30), 0.2)
        end

        imgui.Spacing()
        imgui.BeginChild('##clean_content', imgui.ImVec2(-1, -1), false)
        drawCurrentTab()
        imgui.EndChild()
        imgui.End()
    end

    drawESPEditorWindow()
    imgui.PopStyleVar()
end

local imguiFrame = imgui.OnFrame(
    function() return cfg.menuOpen or uiAnim.alpha > 0.001 end,
    function()
        drawMimguiMenu()
    end
)

local menuWasDown, botWasDown, unloadWasDown = false, false, false

function main()
    while not isSampLoaded() or not isSampfuncsLoaded() do wait(100) end
    while not isSampAvailable() do wait(100) end

    local ok = pcall(function()
        sampRegisterChatCommand("load", function()
            cfg.menuOpen = not cfg.menuOpen
            showCursor(cfg.menuOpen)
            if not cfg.menuOpen then
                isEditingSpamText=false
                isEditingRouteName=false
            end
        end)
    end)

    if ok then
        sampAddChatMessage('{00FF00}[Cheat] Loaded. /load or ' .. keyName(cfg.menuKey) .. ' opens menu. ' .. keyName(cfg.botStopKey) .. ' = bot pause/resume. ' .. keyName(cfg.unloadKey) .. ' = unload.', -1)
    else
        sampAddChatMessage('{FF0000}[Cheat] /load failed. Use ' .. keyName(cfg.menuKey) .. '.', -1)
    end

    while true do
        wait(0)

        local captured = processHotkeyCapture()
        if not captured then
            -- Menu hotkey: use MoonLoader's edge-triggered key check first.
            -- This reliably catches INSERT (0x2D) even when the ImGui window is hidden.
            local menuPressed = false
            if isKeyJustPressed then
                menuPressed = isKeyJustPressed(cfg.menuKey)
            else
                local menuDown = isKeyDown(cfg.menuKey)
                menuPressed = menuDown and not menuWasDown
                menuWasDown = menuDown
            end

            if menuPressed then
                cfg.menuOpen = not cfg.menuOpen
                showCursor(cfg.menuOpen)
                if not cfg.menuOpen then
                    isEditingSpamText=false; isEditingRouteName=false
                end
            end

            local botDown = isKeyDown(cfg.botStopKey)
            if botDown and not botWasDown then
                if route.playing then
                    if route.paused then
                        route.playStartTime = route.playStartTime + (now() - route.pauseTime)
                        route.paused = false
                    else
                        route.paused = true
                        route.pauseTime = now()
                        releaseAllKeys()
                    end
                end
            end
            botWasDown = botDown

            local unloadDown = isKeyDown(cfg.unloadKey)
            if unloadDown and not unloadWasDown then
                saveESPSettings()
                saveHotkeys()
                thisScript():unload()
                return
            end
            unloadWasDown = unloadDown
        else
            menuWasDown, botWasDown, unloadWasDown = false, false, false
        end

        if cfg.carFlyEnabled and isCharInAnyCar(PLAYER_PED) then
            local car = storeCarCharIsInNoSave(PLAYER_PED)
            if car and doesVehicleExist(car) then
                local cx,cy,cz = getCarCoordinates(car)
                if carSt.posX==0 and carSt.posY==0 then carSt.posX,carSt.posY,carSt.posZ=cx,cy,cz end
            end
        end

        updateRouteBot()
        updateAirBrake()
        updateCarSpeedhack()
        updateCarFly()
        updateAimbot()
        updateRWH()
        updateKicker()
        updateAHK()
        updateAntiAFK()
        updateAdminChecker()

        if espDirty then
            espSaveTimer = espSaveTimer + 0.01
            if espSaveTimer >= 1.0 then
                saveESPSettings()
            end
        end

        drawESP()
    end
end