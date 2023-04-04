local QBCore = exports['qbx-core']:GetCoreObject()
local StartedLoot = {}
local StartedPickup = {}

local function GetClosestHouse(Coords)
    local ClosestHouseIndex
    for i = 1, #Config.Houses do
        if #(Coords - Config.Houses[i].coords) <= 3 then
            if ClosestHouseIndex then
                if #(Coords - Config.Houses[i].coords) < #(Coords - Config.Houses[ClosestHouseIndex].coords) then
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
    SetResourceKvpInt(QBCore.Functions.GetPlayer(Source).PlayerData.citizenid, ClosestHouseIndex)
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
    for i = #Config.Interiors[Index].loot, 2, -1 do
        local j = math.random(i)
        Config.Interiors[Index].loot[i], Config.Interiors[Index].loot[j] = Config.Interiors[Index].loot[j], Config.Interiors[Index].loot[i]
    end
    for i = #Config.Interiors[Index].pickups, 2, -1 do
        local j = math.random(i)
        Config.Interiors[Index].pickups[i], Config.Interiors[Index].pickups[j] = Config.Interiors[Index].pickups[j], Config.Interiors[Index].pickups[i]
    end
    for b = 1, #Config.Rewards do
        for i = #Config.Rewards[b].items, 2, -1 do
            local j = math.random(i)
            Config.Rewards[b].items[i], Config.Rewards[b].items[j] = Config.Rewards[b].items[j], Config.Rewards[b].items[i]
        end
    end
end

local function PoliceAlert(Text, House)
    SetTimeout(Config.Interiors[House.interior].callCopsTimeout, function()
        TriggerEvent('police:server:policeAlert', Text)
    end)
end

AddEventHandler('lockpicks:UseLockpick', function(PlayerSource, IsAdvanced)
    local Player = QBCore.Functions.GetPlayer(PlayerSource)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(PlayerSource))
    local ClosestHouseIndex = GetClosestHouse(PlayerCoords)
    local House = Config.Houses[ClosestHouseIndex]
    local Amount = QBCore.Functions.GetDutyCountType('leo')

    if not House then return end
    if House.opened then return end
    if not IsAdvanced and not Player.Functions.GetItemByName(Config.RequiredItems[2]) then return end
    if Amount < Config.MinimumHouseRobberyPolice then if Config.NotEnoughCopsNotify then QBCore.Functions.Notify(PlayerSource, Lang:t('notify.no_police', { Required = Config.MinimumHouseRobberyPolice }), 'error') end return end

    local Result = lib.callback.await('qb-houserobbery:callback:checkTime', PlayerSource)

    if not Result then return end

    local Skillcheck = lib.callback.await('qb-houserobbery:callback:startSkillcheck', PlayerSource, Config.Interiors[House.interior].skillcheck)

    if Skillcheck then
        Config.Houses[ClosestHouseIndex].opened = true
        QBCore.Functions.Notify(PlayerSource, Lang:t('notify.success_skillcheck'), 'success')
        TriggerClientEvent('qb-houserobbery:client:syncconfig', -1, Config.Houses[ClosestHouseIndex], ClosestHouseIndex)
        EnterHouse(PlayerSource, Config.Interiors[House.interior].exit, House.routingbucket, ClosestHouseIndex)
        PoliceAlert(Lang:t('notify.police_alert'), House)
    else
        QBCore.Functions.Notify(PlayerSource, Lang:t('notify.fail_skillcheck'), 'error')
    end
end)

RegisterNetEvent('qb-houserobbery:server:enterHouse', function(Index)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestHouseIndex = GetClosestHouse(PlayerCoords)

    if ClosestHouseIndex ~= Index then return end
    if not ClosestHouseIndex then return end
    if not Config.Houses[Index].opened then return end

    EnterHouse(source, Config.Interiors[Config.Houses[ClosestHouseIndex].interior].exit, Config.Houses[ClosestHouseIndex].routingbucket, ClosestHouseIndex)
end)

RegisterNetEvent('qb-houserobbery:server:leaveHouse', function()
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Index = GetResourceKvpInt(QBCore.Functions.GetPlayer(source).PlayerData.citizenid)
    local Exit = vector3(Config.Interiors[Config.Houses[Index].interior].exit.x, Config.Interiors[Config.Houses[Index].interior].exit.y, Config.Interiors[Config.Houses[Index].interior].exit.z)

    if #(PlayerCoords - Exit) > 3 then return end

    LeaveHouse(source, Config.Houses[Index].coords)
end)

lib.callback.register('qb-houserobbery:callback:checkLoot', function(source, HouseIndex, LootIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Loot = Config.Houses[HouseIndex].loot[LootIndex]

    if #(PlayerCoords - Loot.coords) > 3 then return end
    if Loot.isBusy then QBCore.Functions.Notify(source, Lang:t('notify.busy')) return end
    if Loot.isOpened then return end
    if not Config.Houses[HouseIndex].opened then return end

    StartedLoot[source] = true
    Config.Houses[HouseIndex].loot[LootIndex].isBusy = true
    return true
end)

RegisterNetEvent('qb-houserobbery:server:lootFinished', function(HouseIndex, LootIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Player = QBCore.Functions.GetPlayer(source)
    local Loot = Config.Houses[HouseIndex].loot[LootIndex]
    local Reward = Config.Rewards[Loot.pool[math.random(#Loot.pool)]]

    if #(PlayerCoords - Loot.coords) > 3 then return end
    if not StartedLoot[source] then return end
    if not Loot.isBusy then return end
    if Loot.isOpened then return end

    for i = 1, math.random(Reward.togive.min, Reward.togive.max) do
        Player.Functions.AddItem(Reward.items[i], math.random(Reward.toget.min, Reward.toget.max))
    end
    StartedLoot[source] = false
    Config.Houses[HouseIndex].loot[LootIndex].isBusy = false
    Config.Houses[HouseIndex].loot[LootIndex].isOpened = true
    TriggerClientEvent('qb-houserobbery:client:syncconfig', -1, Config.Houses[HouseIndex], HouseIndex)
end)

RegisterNetEvent('qb-houserobbery:server:lootCancelled', function(HouseIndex, LootIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))

    if #(PlayerCoords - Config.Houses[HouseIndex].loot[LootIndex].coords) > 3 then return end
    if not StartedLoot[source] then return end

    StartedLoot[source] = false
    Config.Houses[HouseIndex].loot[LootIndex].isBusy = false
end)

lib.callback.register('qb-houserobbery:callback:checkPickup', function(source, HouseIndex, PickupIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Pickup = Config.Houses[HouseIndex].pickups[PickupIndex]

    if #(PlayerCoords - Pickup.coords) > 3 then return end
    if Pickup.isBusy then QBCore.Functions.Notify(source, Lang:t('notify.busy')) return end
    if Pickup.isOpened then return end

    StartedPickup[source] = true
    Config.Houses[HouseIndex].pickups[PickupIndex].isBusy = true
    return true
end)

RegisterNetEvent('qb-houserobbery:server:pickupFinished', function(HouseIndex, PickupIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Player = QBCore.Functions.GetPlayer(source)
    local Pickup = Config.Houses[HouseIndex].pickups[PickupIndex]

    if #(PlayerCoords - Pickup.coords) > 3 then return end
    if not StartedPickup[source] then return end
    if not Pickup.isBusy then return end
    if Pickup.isOpened then return end

    Player.Functions.AddItem(Pickup.reward, 1)
    StartedPickup[source] = false
    Config.Houses[HouseIndex].pickups[PickupIndex].isBusy = false
    Config.Houses[HouseIndex].pickups[PickupIndex].isOpened = true
    TriggerClientEvent('qb-houserobbery:client:syncconfig', -1, Config.Houses[HouseIndex], HouseIndex)
end)

RegisterNetEvent('qb-houserobbery:server:pickupCancelled', function(HouseIndex, PickupIndex)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))

    if #(PlayerCoords - Config.Houses[HouseIndex].pickups[PickupIndex].coords) > 3 then return end
    if not StartedPickup[source] then return end

    StartedPickup[source] = false
    Config.Houses[HouseIndex].pickups[PickupIndex].isBusy = false
end)

CreateThread(function()
    for i = 1, #Config.Houses do
        ShuffleTables(Config.Houses[i].interior)
        local RandomAmountOfLoot = math.random(Config.Houses[i].setup.loot.min, Config.Houses[i].setup.loot.max)
        for b = 1, RandomAmountOfLoot do
            Config.Houses[i].loot[b] = {
                coords = Config.Interiors[Config.Houses[i].interior].loot[b].coords,
                pool = Config.Interiors[Config.Houses[i].interior].loot[b].pool,
                isBusy = false,
                isOpened = false
            }
        end
        local RandomAmountOfPickups = math.random(Config.Houses[i].setup.pickups.min, Config.Houses[i].setup.pickups.max)
        for b = 1, RandomAmountOfPickups do
            Config.Houses[i].pickups[b] = {
                coords = Config.Interiors[Config.Houses[i].interior].pickups[b].coords,
                prop = Config.Interiors[Config.Houses[i].interior].pickups[b].model,
                reward = Config.Interiors[Config.Houses[i].interior].pickups[b].reward,
                entity = {},
                isBusy = false,
                isOpened = false
            }
        end
    end
    Wait(50)
    TriggerClientEvent('qb-houserobbery:client:syncconfig', -1, Config.Houses)
end)

AddEventHandler('playerJoining', function(source)
    TriggerClientEvent('qb-houserobbery:client:syncconfig', source, Config.Houses)
end)

lib.versionCheck('Qbox-project/qb-houserobbery')
