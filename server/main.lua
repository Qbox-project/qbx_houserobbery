local config = require 'config.server'
local sharedConfig = require 'config.shared'
local StartedLoot = {}
local StartedPickup = {}

local function GetClosestHouse(Coords)
    local ClosestHouseIndex
    for i = 1, #sharedConfig.houses do
        if #(Coords - sharedConfig.houses[i].coords) <= 3 then
            if ClosestHouseIndex then
                if #(Coords - sharedConfig.houses[i].coords) < #(Coords - sharedConfig.houses[ClosestHouseIndex].coords) then
                    ClosestHouseIndex = i
                end
            else
                ClosestHouseIndex = i
            end
        end
    end
    return ClosestHouseIndex
end

local function EnterHouse(Source, Coords, Bucket, ClosestHouseIndex)
    SetResourceKvpInt(exports.qbx_core:GetPlayer(Source).PlayerData.citizenid, ClosestHouseIndex)
    TriggerClientEvent('qb-interior:client:screenfade', Source)
    Wait(200)
    local Ped = GetPlayerPed(Source)
    SetEntityCoords(Ped, Coords.x, Coords.y, Coords.z)
    SetEntityHeading(Ped, Coords.w)
    SetPlayerRoutingBucket(Source, Bucket)
    FreezeEntityPosition(Ped, true)
    Wait(200)
    FreezeEntityPosition(Ped, false)
end

local function LeaveHouse(Source, Coords)
    TriggerClientEvent('qb-interior:client:screenfade', Source)
    Wait(200)
    local Ped = GetPlayerPed(Source)
    SetEntityCoords(Ped, Coords.x, Coords.y, Coords.z)
    SetPlayerRoutingBucket(Source, 0)
    FreezeEntityPosition(Ped, true)
    Wait(200)
    FreezeEntityPosition(Ped, false)
end

local function ShuffleTables(Index)
    for i = #sharedConfig.interiors[Index].loot, 2, -1 do
        local j = math.random(i)
        sharedConfig.interiors[Index].loot[i], sharedConfig.interiors[Index].loot[j] = sharedConfig.interiors[Index].loot[j], sharedConfig.interiors[Index].loot[i]
    end
    for i = #sharedConfig.interiors[Index].pickups, 2, -1 do
        local j = math.random(i)
        sharedConfig.interiors[Index].pickups[i], sharedConfig.interiors[Index].pickups[j] = sharedConfig.interiors[Index].pickups[j], sharedConfig.interiors[Index].pickups[i]
    end
    for b = 1, #config.rewards do
        for i = #config.rewards[b].items, 2, -1 do
            local j = math.random(i)
            config.rewards[b].items[i], config.rewards[b].items[j] = config.rewards[b].items[j], config.rewards[b].items[i]
        end
    end
end

local function PoliceAlert(Text, House)
    SetTimeout(sharedConfig.interiors[House.interior].callCopsTimeout, function()
        TriggerEvent('police:server:policeAlert', Text)
    end)
end

AddEventHandler('lockpicks:UseLockpick', function(PlayerSource, IsAdvanced)
    local Player = exports.qbx_core:GetPlayer(PlayerSource)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(PlayerSource))
    local ClosestHouseIndex = GetClosestHouse(PlayerCoords)
    local House = sharedConfig.houses[ClosestHouseIndex]
    local Amount = exports.qbx_core:GetDutyCountType('leo')

    if not House then return end
    if House.opened then return end
    if not IsAdvanced and not Player.Functions.GetItemByName(config.requiredItems[2]) then return end
    if Amount < config.minimumHouseRobberyPolice then if config.notEnoughCopsNotify then exports.qbx_core:Notify(PlayerSource, Lang:t('notify.no_police', { Required = config.minimumHouseRobberyPolice }), 'error') end return end

    local Result = lib.callback.await('qb-houserobbery:callback:checkTime', PlayerSource)

    if not Result then return end

    local Skillcheck = lib.callback.await('qb-houserobbery:callback:startSkillcheck', PlayerSource, sharedConfig.interiors[House.interior].skillcheck)

    if Skillcheck then
        sharedConfig.houses[ClosestHouseIndex].opened = true
        exports.qbx_core:Notify(PlayerSource, Lang:t('notify.success_skillcheck'), 'success')
        TriggerClientEvent('qb-houserobbery:client:syncconfig', -1, sharedConfig.houses[ClosestHouseIndex], ClosestHouseIndex)
        EnterHouse(PlayerSource, sharedConfig.interiors[House.interior].exit, House.routingbucket, ClosestHouseIndex)
        PoliceAlert(Lang:t('notify.police_alert'), House)
    else
        exports.qbx_core:Notify(PlayerSource, Lang:t('notify.fail_skillcheck'), 'error')
    end
end)

RegisterNetEvent('qb-houserobbery:server:enterHouse', function(Index)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestHouseIndex = GetClosestHouse(PlayerCoords)

    if ClosestHouseIndex ~= Index then return end
    if not ClosestHouseIndex then return end
    if not sharedConfig.houses[Index].opened then return end

    EnterHouse(source, sharedConfig.interiors[sharedConfig.houses[ClosestHouseIndex].interior].exit, sharedConfig.houses[ClosestHouseIndex].routingbucket, ClosestHouseIndex)
end)

RegisterNetEvent('qb-houserobbery:server:leaveHouse', function()
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Index = GetResourceKvpInt(exports.qbx_core:GetPlayer(source).PlayerData.citizenid)
    local Exit = vector3(sharedConfig.interiors[sharedConfig.houses[Index].interior].exit.x, sharedConfig.interiors[sharedConfig.houses[Index].interior].exit.y, sharedConfig.interiors[sharedConfig.houses[Index].interior].exit.z)

    if #(PlayerCoords - Exit) > 3 then return end

    LeaveHouse(source, sharedConfig.houses[Index].coords)
end)

lib.callback.register('qb-houserobbery:callback:checkLoot', function(source, HouseIndex, LootIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Loot = sharedConfig.houses[HouseIndex].loot[LootIndex]

    if #(PlayerCoords - Loot.coords) > 3 then return end
    if Loot.isBusy then exports.qbx_core:Notify(source, Lang:t('notify.busy')) return end
    if Loot.isOpened then return end
    if not sharedConfig.houses[HouseIndex].opened then return end

    StartedLoot[source] = true
    sharedConfig.houses[HouseIndex].loot[LootIndex].isBusy = true
    return true
end)

RegisterNetEvent('qb-houserobbery:server:lootFinished', function(HouseIndex, LootIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Player = exports.qbx_core:GetPlayer(source)
    local Loot = sharedConfig.houses[HouseIndex].loot[LootIndex]
    local Reward = config.rewards[Loot.pool[math.random(#Loot.pool)]]

    if #(PlayerCoords - Loot.coords) > 3 then return end
    if not StartedLoot[source] then return end
    if not Loot.isBusy then return end
    if Loot.isOpened then return end

    for i = 1, math.random(Reward.togive.min, Reward.togive.max) do
        Player.Functions.AddItem(Reward.items[i], math.random(Reward.toget.min, Reward.toget.max))
    end
    StartedLoot[source] = false
    sharedConfig.houses[HouseIndex].loot[LootIndex].isBusy = false
    sharedConfig.houses[HouseIndex].loot[LootIndex].isOpened = true
    TriggerClientEvent('qb-houserobbery:client:syncconfig', -1, sharedConfig.houses[HouseIndex], HouseIndex)
end)

RegisterNetEvent('qb-houserobbery:server:lootCancelled', function(HouseIndex, LootIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))

    if #(PlayerCoords - sharedConfig.houses[HouseIndex].loot[LootIndex].coords) > 3 then return end
    if not StartedLoot[source] then return end

    StartedLoot[source] = false
    sharedConfig.houses[HouseIndex].loot[LootIndex].isBusy = false
end)

lib.callback.register('qb-houserobbery:callback:checkPickup', function(source, HouseIndex, PickupIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Pickup = sharedConfig.houses[HouseIndex].pickups[PickupIndex]

    if #(PlayerCoords - Pickup.coords) > 3 then return end
    if Pickup.isBusy then exports.qbx_core:Notify(source, Lang:t('notify.busy')) return end
    if Pickup.isOpened then return end

    StartedPickup[source] = true
    sharedConfig.houses[HouseIndex].pickups[PickupIndex].isBusy = true
    return true
end)

RegisterNetEvent('qb-houserobbery:server:pickupFinished', function(HouseIndex, PickupIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Player = exports.qbx_core:GetPlayer(source)
    local Pickup = sharedConfig.houses[HouseIndex].pickups[PickupIndex]

    if #(PlayerCoords - Pickup.coords) > 3 then return end
    if not StartedPickup[source] then return end
    if not Pickup.isBusy then return end
    if Pickup.isOpened then return end

    Player.Functions.AddItem(Pickup.reward, 1)
    StartedPickup[source] = false
    sharedConfig.houses[HouseIndex].pickups[PickupIndex].isBusy = false
    sharedConfig.houses[HouseIndex].pickups[PickupIndex].isOpened = true
    TriggerClientEvent('qb-houserobbery:client:syncconfig', -1, sharedConfig.houses[HouseIndex], HouseIndex)
end)

RegisterNetEvent('qb-houserobbery:server:pickupCancelled', function(HouseIndex, PickupIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))

    if #(PlayerCoords - sharedConfig.houses[HouseIndex].pickups[PickupIndex].coords) > 3 then return end
    if not StartedPickup[source] then return end

    StartedPickup[source] = false
    sharedConfig.houses[HouseIndex].pickups[PickupIndex].isBusy = false
end)

CreateThread(function()
    for i = 1, #sharedConfig.houses do
        ShuffleTables(sharedConfig.houses[i].interior)
        local RandomAmountOfLoot = math.random(sharedConfig.houses[i].setup.loot.min, sharedConfig.houses[i].setup.loot.max)
        for b = 1, RandomAmountOfLoot do
            sharedConfig.houses[i].loot[b] = {
                coords = sharedConfig.interiors[sharedConfig.houses[i].interior].loot[b].coords,
                pool = sharedConfig.interiors[sharedConfig.houses[i].interior].loot[b].pool,
                isBusy = false,
                isOpened = false
            }
        end
        local RandomAmountOfPickups = math.random(sharedConfig.houses[i].setup.pickups.min, sharedConfig.houses[i].setup.pickups.max)
        for b = 1, RandomAmountOfPickups do
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
    TriggerClientEvent('qb-houserobbery:client:syncconfig', -1, sharedConfig.houses)
end)

AddEventHandler('playerJoining', function(source)
    TriggerClientEvent('qb-houserobbery:client:syncconfig', source, sharedConfig.houses)
end)
