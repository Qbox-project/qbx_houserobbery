local config = require 'config.server'
local sharedConfig = require 'config.shared'
local startedLoot = {}
local startedPickup = {}
local lootOwners = {}
local pickupOwners = {}
local MIN_SEARCH_DURATION = 3500
local SEARCH_TIMEOUT = 15000

---@param value any
---@return boolean
local function isInteger(value)
    return type(value) == 'number' and value % 1 == 0
end

---@param houseIndex integer
---@param pointIndex integer
---@return string
local function getPointKey(houseIndex, pointIndex)
    return ('%d:%d'):format(houseIndex, pointIndex)
end

---@param source number
---@param houseIndex integer
---@return table? player
---@return table? house
local function getPlayerHouse(source, houseIndex)
    if not isInteger(houseIndex) then return end

    local house = sharedConfig.houses[houseIndex]
    local player = exports.qbx_core:GetPlayer(source)
    if not house or not house.opened or not player then return end
    if GetResourceKvpInt(player.PlayerData.citizenid) ~= houseIndex then return end
    if GetPlayerRoutingBucket(source) ~= house.routingbucket then return end

    return player, house
end

---@param source number
---@param sessions table
---@param owners table
local function releaseSearch(source, sessions, owners)
    local session = sessions[source]
    if not session then return end

    local house = sharedConfig.houses[session.houseIndex]
    local point = house and house[session.collection] and house[session.collection][session.pointIndex]
    local key = getPointKey(session.houseIndex, session.pointIndex)
    if owners[key] == source then
        if point then point.isBusy = false end
        owners[key] = nil
    end
    sessions[source] = nil
end

---@param source number
---@param houseIndex integer
---@param collection 'loot'|'pickups'
---@param pointIndex integer
---@param sessions table
---@param owners table
---@return table? player
---@return table? house
---@return table? point
local function startSearch(source, houseIndex, collection, pointIndex, sessions, owners)
    if not isInteger(pointIndex) then return end

    local existingSession = sessions[source]
    if existingSession then
        if GetGameTimer() - existingSession.startedAt <= SEARCH_TIMEOUT then return end
        releaseSearch(source, sessions, owners)
    end

    local player, house = getPlayerHouse(source, houseIndex)
    local point = house and house[collection] and house[collection][pointIndex]
    if not player or not point then return end

    local playerPed = GetPlayerPed(source)
    if playerPed <= 0 or #(GetEntityCoords(playerPed) - point.coords) > 3 then return end

    local key = getPointKey(houseIndex, pointIndex)
    if point.isBusy then
        local owner = owners[key]
        local session = owner and sessions[owner]
        if session and GetGameTimer() - session.startedAt <= SEARCH_TIMEOUT then
            exports.qbx_core:Notify(source, locale('notify.busy'))
            return
        end
        if owner then releaseSearch(owner, sessions, owners) else point.isBusy = false end
    end
    if point.isOpened then return end

    sessions[source] = {
        houseIndex = houseIndex,
        collection = collection,
        pointIndex = pointIndex,
        startedAt = GetGameTimer(),
    }
    owners[key] = source
    point.isBusy = true
    return player, house, point
end

---@param source number
---@param houseIndex integer
---@param pointIndex integer
---@param sessions table
---@param owners table
---@return table? player
---@return table? house
---@return table? point
local function finishSearch(source, houseIndex, pointIndex, sessions, owners)
    local session = sessions[source]
    if not session or session.houseIndex ~= houseIndex or session.pointIndex ~= pointIndex then return end

    local elapsed = GetGameTimer() - session.startedAt
    local player, house = getPlayerHouse(source, houseIndex)
    local point = house and house[session.collection] and house[session.collection][pointIndex]
    local key = getPointKey(houseIndex, pointIndex)
    local playerPed = GetPlayerPed(source)
    if elapsed < MIN_SEARCH_DURATION or elapsed > SEARCH_TIMEOUT or not player or not point
        or owners[key] ~= source or not point.isBusy or point.isOpened or playerPed <= 0
        or #(GetEntityCoords(playerPed) - point.coords) > 3 then
        releaseSearch(source, sessions, owners)
        return
    end

    point.isOpened = true
    releaseSearch(source, sessions, owners)
    return player, house, point
end

-- Returns closes house index number from sharedConfig table
---@param coords vector3 Point to check for closest house point
---@return integer
local function getClosestHouse(coords)
    local closestHouseIndex
    for i = 1, #sharedConfig.houses do
        if #(coords - sharedConfig.houses[i].coords) <= 3 then
            if closestHouseIndex then
                if #(coords - sharedConfig.houses[i].coords) < #(coords - sharedConfig.houses[closestHouseIndex].coords) then
                    closestHouseIndex = i
                end
            else
                closestHouseIndex = i
            end
        end
    end
    return closestHouseIndex
end

-- Teleports player to house exit inside IPL interior
-- Sets routing bucket for player
-- Triggers loot point creation for client
---@param source number Player server Id
---@param coords vector4 Destination coordinates to teleport player
---@param bucket number Routing bucket to put player in
---@param closestHouseIndex number House index to store with player citizenid so we know what house they are in
local function enterHouse(source, coords, bucket, closestHouseIndex)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    SetResourceKvpInt(player.PlayerData.citizenid, closestHouseIndex)
    Player(source).state:set('houseRobbery', closestHouseIndex, true)
    TriggerClientEvent('qb-interior:client:screenfade', source)
    Wait(200)
    local ped = GetPlayerPed(source)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)
    exports.qbx_core:SetPlayerBucket(source, bucket)
    TriggerClientEvent('qbx_houserobbery:client:enterHouse', source)
    FreezeEntityPosition(ped, true)
    Wait(200)
    FreezeEntityPosition(ped, false)
end

-- Returns player to house entrace in routing bucket 0
---@param source number
---@param coords vector3
local function leaveHouse(source, coords)
    Player(source).state:set('houseRobbery', nil, true)
    TriggerClientEvent('qb-interior:client:screenfade', source)
    Wait(200)
    local ped = GetPlayerPed(source)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    exports.qbx_core:SetPlayerBucket(source, 0)
    FreezeEntityPosition(ped, true)
    Wait(200)
    FreezeEntityPosition(ped, false)
end

-- Shuffle loot tables
---@param index number House interior table to shuffle loot
local function shuffleTables(index)
    for i = #sharedConfig.interiors[index].loot, 2, -1 do
        local j = math.random(i)
        sharedConfig.interiors[index].loot[i], sharedConfig.interiors[index].loot[j] = sharedConfig.interiors[index].loot[j], sharedConfig.interiors[index].loot[i]
    end
    for i = #sharedConfig.interiors[index].pickups, 2, -1 do
        local j = math.random(i)
        sharedConfig.interiors[index].pickups[i], sharedConfig.interiors[index].pickups[j] = sharedConfig.interiors[index].pickups[j], sharedConfig.interiors[index].pickups[i]
    end
    for b = 1, #config.rewards do
        for i = #config.rewards[b].items, 2, -1 do
            local j = math.random(i)
            config.rewards[b].items[i], config.rewards[b].items[j] = config.rewards[b].items[j], config.rewards[b].items[i]
        end
    end
end

-- Alert police to house robbery in progress
---@param text string Text to send
---@param interiorId number Interior index number to fetch timeout from config
local function policeAlert(text, interiorId)
    SetTimeout(sharedConfig.interiors[interiorId].callCopsTimeout, function()
        TriggerEvent('police:server:policeAlert', text)
    end)
end

-- Lockpick event handler for entering houses.
-- Triggers skillcheck callback on calling player before teleporting them inside
---@param playerSource number Player server Id
---@param isAdvanced boolean Is this an advanced lockpick
AddEventHandler('lockpicks:UseLockpick', function(playerSource, isAdvanced)
    local player = exports.qbx_core:GetPlayer(playerSource)
    if not player then return end

    local playerCoords = GetEntityCoords(GetPlayerPed(playerSource))
    local closestHouseIndex = getClosestHouse(playerCoords)
    local house = sharedConfig.houses[closestHouseIndex]
    local amount = exports.qbx_core:GetDutyCountType('leo')

    if not house then return end
    if house.opened then return end
    if not isAdvanced and not player.Functions.GetItemByName(config.requiredItems[2]) then return end
    if amount < config.minimumPolice then
        if config.notEnoughCopsNotify then
            exports.qbx_core:Notify(playerSource, locale('notify.no_police', config.minimumPolice), 'error')
            return
        end
    end

    local result = lib.callback.await('qbx_houserobbery:client:checkTime', playerSource)

    if not result then return end

    local skillcheck = lib.callback.await('qbx_houserobbery:client:startSkillcheck', playerSource, sharedConfig.interiors[house.interior].skillcheck)

    if skillcheck then
        sharedConfig.houses[closestHouseIndex].opened = true
        exports.qbx_core:Notify(playerSource, locale('notify.success_skillcheck'), 'success')
        TriggerClientEvent('qbx_houserobbery:client:syncconfig', -1, sharedConfig.houses[closestHouseIndex], closestHouseIndex)
        enterHouse(playerSource, sharedConfig.interiors[house.interior].exit, house.routingbucket, closestHouseIndex)
        policeAlert(locale('notify.police_alert'), house.interior)
    else
        exports.qbx_core:Notify(playerSource, locale('notify.fail_skillcheck'), 'error')
    end
end)

-- Teleports player inside house and sets routing bucket.
---@param index number House index number to locate in config
RegisterNetEvent('qbx_houserobbery:server:enterHouse', function(index)
    if not isInteger(index) then return end

    local playerCoords = GetEntityCoords(GetPlayerPed(source --[[@as number]]))
    local closestHouseIndex = getClosestHouse(playerCoords)

    if not closestHouseIndex then return end
    if closestHouseIndex ~= index then return end

    local house = sharedConfig.houses[index]
    if not house or not house.opened then return end

    enterHouse(source --[[@as number]], sharedConfig.interiors[house.interior].exit, house.routingbucket, closestHouseIndex)
end)

-- NetEvent to handle player exiting house
RegisterNetEvent('qbx_houserobbery:server:leaveHouse', function()
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local index = GetResourceKvpInt(player.PlayerData.citizenid)
    local house = sharedConfig.houses[index]
    local interior = house and sharedConfig.interiors[house.interior]
    if not house or not interior or GetPlayerRoutingBucket(source) ~= house.routingbucket then return end

    local playerCoords = GetEntityCoords(GetPlayerPed(source --[[@as number]]))
    local exit = interior.exit.xyz
    if #(playerCoords - exit) > 3 then return end

    releaseSearch(source, startedLoot, lootOwners)
    releaseSearch(source, startedPickup, pickupOwners)
    leaveHouse(source --[[@as number]], house.coords)
    DeleteResourceKvp(player.PlayerData.citizenid)
end)

-- Callback to check if loot is busy/already looted
---@param source number Player server Id
---@param houseIndex number House index from sharedConfig
---@param lootIndex number Loot index from sharedConfig (dynamically generated)
---@return boolean?
lib.callback.register('qbx_houserobbery:server:checkLoot', function(source, houseIndex, lootIndex)
    return startSearch(source, houseIndex, 'loot', lootIndex, startedLoot, lootOwners) ~= nil
end)

-- NetEvent to update status of loot drops inside house and give reward
---@param houseIndex number House index from sharedConfig
---@param lootIndex number Loot index from sharedConfig (dynamically generated)
RegisterNetEvent('qbx_houserobbery:server:lootFinished', function(houseIndex, lootIndex)
    local player, house, loot = finishSearch(source, houseIndex, lootIndex, startedLoot, lootOwners)
    if not player then return end

    local reward = config.rewards[loot.pool[math.random(#loot.pool)]]
    if not reward then return end

    for i = 1, math.random(reward.togive.min, reward.togive.max) do
        player.Functions.AddItem(reward.items[i], math.random(reward.toget.min, reward.toget.max))
    end
    TriggerClientEvent('qbx_houserobbery:client:syncconfig', -1, house, houseIndex)
end)

-- NetEvent to handle cancelling loot attempt
---@param houseIndex number House index from sharedConfig
---@param lootIndex number Loot index from sharedConfig (dynamically generated)
RegisterNetEvent('qbx_houserobbery:server:lootCancelled', function(houseIndex, lootIndex)
    local session = startedLoot[source]
    if not session or session.houseIndex ~= houseIndex or session.pointIndex ~= lootIndex then return end

    releaseSearch(source, startedLoot, lootOwners)
end)

-- Callback to check if pickup point is busy or looted
---@param source number Player server Id
---@param houseIndex number House index from sharedConfig
---@param pickupIndex number Pickup index from sharedConfig (dynamically generated)
---@return boolean?
lib.callback.register('qbx_houserobbery:server:checkPickup', function(source, houseIndex, pickupIndex)
    return startSearch(source, houseIndex, 'pickups', pickupIndex, startedPickup, pickupOwners) ~= nil
end)

-- NetEvent to update pickup point status and give reward
---@param houseIndex number House index from sharedConfig
---@param pickupIndex number Pickup index from sharedConfig (dynamically generated)
RegisterNetEvent('qbx_houserobbery:server:pickupFinished', function(houseIndex, pickupIndex)
    local player, house, pickup = finishSearch(source, houseIndex, pickupIndex, startedPickup, pickupOwners)
    if not player then return end

    player.Functions.AddItem(pickup.reward, 1)
    TriggerClientEvent('qbx_houserobbery:client:syncconfig', -1, house, houseIndex)
end)

-- NetEvent to handle cancelling pickup attempt
---@param houseIndex number House index from sharedConfig
---@param pickupIndex number Pickup index from sharedConfig (dynamically generated)
RegisterNetEvent('qbx_houserobbery:server:pickupCancelled', function(houseIndex, pickupIndex)
    local session = startedPickup[source]
    if not session or session.houseIndex ~= houseIndex or session.pointIndex ~= pickupIndex then return end

    releaseSearch(source, startedPickup, pickupOwners)
end)

AddEventHandler('playerDropped', function()
    releaseSearch(source, startedLoot, lootOwners)
    releaseSearch(source, startedPickup, pickupOwners)
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    Player(source).state:set('houseRobbery', nil, true)
end)

-- Startup thread to shuffle loot for all houses in configuration and sync configuration to clients
CreateThread(function()
    for i = 1, #sharedConfig.houses do
        shuffleTables(sharedConfig.houses[i].interior)
        local randomAmountOfLoot = math.random(sharedConfig.houses[i].setup.loot.min, sharedConfig.houses[i].setup.loot.max)
        for b = 1, randomAmountOfLoot do
            sharedConfig.houses[i].loot[b] = {
                coords = sharedConfig.interiors[sharedConfig.houses[i].interior].loot[b].coords,
                pool = sharedConfig.interiors[sharedConfig.houses[i].interior].loot[b].pool,
                isBusy = false,
                isOpened = false
            }
        end
        local randomAmountOfPickups = math.random(sharedConfig.houses[i].setup.pickups.min, sharedConfig.houses[i].setup.pickups.max)
        for b = 1, randomAmountOfPickups do
            sharedConfig.houses[i].pickups[b] = {
                coords = sharedConfig.interiors[sharedConfig.houses[i].interior].pickups[b].coords,
                prop = sharedConfig.interiors[sharedConfig.houses[i].interior].pickups[b].model,
                reward = sharedConfig.interiors[sharedConfig.houses[i].interior].pickups[b].reward,
                entity = {},
                isBusy = false,
                isOpened = false
            }
        end
    end
    Wait(50)
    TriggerClientEvent('qbx_houserobbery:client:syncconfig', -1, sharedConfig.houses)
end)

-- Event handler to sync configuration to new players joining server
AddEventHandler('playerJoining', function()
    TriggerClientEvent('qbx_houserobbery:client:syncconfig', source, sharedConfig.houses)
end)
