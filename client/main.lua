local config = require 'config.client'
local sharedConfig = require 'config.shared'
local house = 1
local ITEMS = exports.ox_inventory:Items()

local function dropFingerprint()
    if qbx.isWearingGloves() then
        return
    end

    local coords = GetEntityCoords(cache.ped)
    if config.fingerprintChance > math.random(0, 100) then
        TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
    end
end

CreateThread(function()
    local hasShownText
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local waitTime = 800
        local nearby = false
        for i = 1, #sharedConfig.houses do
            local distance = #(playerCoords - sharedConfig.houses[i].coords)
            if distance <= 1.4 and sharedConfig.houses[i].opened then
                waitTime = 0
                nearby = true
                house = i
                if config.useDrawText then
                    if not hasShownText then
                        hasShownText = true
                        lib.showTextUI(locale('text.enter_house'), {position = 'left-center'})
                    end
                else
                    qbx.drawText3d({
                        text = locale('text.enter_house'),
                        coords = sharedConfig.houses[i].coords,
                    })
                end
                if IsControlJustReleased(0, 38) then
                    lib.requestAnimDict('anim@heists@keycard@')
                    TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, false, false, false)
                    TriggerServerEvent('qbx_houserobbery:server:enterHouse', i)
                    RemoveAnimDict('anim@heists@keycard@')
                end
            elseif distance <= 1.6 and not sharedConfig.houses[i].opened then
                waitTime = 0
                nearby = true
                if config.useDrawText then
                    if not hasShownText then
                        hasShownText = true
                        lib.showTextUI(locale('text.enter_requirements'), {position = 'left-center'})
                    end
                else
                    qbx.drawText3d({
                        text = locale('text.enter_requirements'),
                        coords = sharedConfig.houses[i].coords,
                    })
                end
            end
        end
        if not nearby and hasShownText then
            hasShownText = false
            lib.hideTextUI()
        end
        Wait(waitTime)
    end
end)

CreateThread(function()
    local hasShownText
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local waitTime = 800
        local nearby = false
        for i = 1, #sharedConfig.interiors do
            local exit = vec3(sharedConfig.interiors[i].exit.x, sharedConfig.interiors[i].exit.y, sharedConfig.interiors[i].exit.z)
            if #(playerCoords - exit) <= 1.4 then
                waitTime = 0
                nearby = true
                if config.useDrawText then
                    if not hasShownText then
                        hasShownText = true
                        lib.showTextUI(locale('text.leave_house'), {position = 'left-center'})
                    end
                else
                    qbx.drawText3d({
                        text = locale('text.leave_house'),
                        coords = exit,
                    })
                end
                if IsControlJustReleased(0, 38) then
                    lib.requestAnimDict('anim@heists@keycard@')
                    TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, false, false, false)
                    TriggerServerEvent('qbx_houserobbery:server:leaveHouse')
                    RemoveAnimDict('anim@heists@keycard@')
                end
            end
        end
        if not nearby and hasShownText then
            hasShownText = false
            lib.hideTextUI()
        end
        Wait(waitTime)
    end
end)

CreateThread(function()
    local hasShownText
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local waitTime = 800
        local nearby = false
        if sharedConfig.houses[house].opened and sharedConfig.houses[house].loot[1] then
            for i = 1, #sharedConfig.houses[house].loot do
                if #(playerCoords - sharedConfig.houses[house].loot[i].coords) < 0.8 and not sharedConfig.houses[house].loot[i].isOpened then
                    waitTime = 0
                    nearby = true
                    if config.useDrawText then
                        if not hasShownText then
                            hasShownText = true
                            lib.showTextUI(locale('text.search'), {position = 'left-center'})
                        end
                    else
                    qbx.drawText3d({
                            text = locale('text.search'),
                            coords = sharedConfig.houses[house].loot[i].coords
                   })
                    end
                    if IsControlJustReleased(0, 38) then
                        dropFingerprint()
                        local canStart = lib.callback.await('qbx_houserobbery:callback:checkLoot', false, house, i)
                        if not canStart then return end
                        if lib.progressCircle({
                            duration = math.random(4000, 8000),
                            position = 'bottom',
                            canCancel = true,
                            disable = {
                                move = true,
                                combat = true,
                            },
                            anim = {
                                dict = 'missexile3',
                                clip = 'ex03_dingy_search_case_base_michael',
                                flag = 1,
                                blendIn = 1.0
                            },
                        }) then
                            TriggerServerEvent('qbx_houserobbery:server:lootFinished', house, i)
                        else
                            TriggerServerEvent('qbx_houserobbery:server:lootCancelled', house, i)
                        end
                    end
                end
            end
        end
        if not nearby and hasShownText then
            hasShownText = false
            lib.hideTextUI()
        end
        Wait(waitTime)
    end
end)

CreateThread(function()
    local hasShownText
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local waitTime = 800
        local nearby = false
        if sharedConfig.houses[house].opened and sharedConfig.houses[house].pickups[1] then
            for i = 1, #sharedConfig.houses[house].pickups do
                if #(playerCoords - sharedConfig.houses[house].pickups[i].coords) < 0.8 and not sharedConfig.houses[house].pickups[i].isOpened then
                    waitTime = 0
                    nearby = true
                    if config.useDrawText then
                        if not hasShownText then
                            hasShownText = true
                            lib.showTextUI(locale('text.pickup', {Item = ITEMS[sharedConfig.houses[house].pickups[i].reward]['label']}), {position = 'left-center'})
                        end
                    else
                    qbx.drawText3d({
                            text = locale('text.pickup', { Item = ITEMS[sharedConfig.houses[house].pickups[i].reward]['label'] }),
                            coords = sharedConfig.houses[house].pickups[i].coords
                    })
                    end
                    if IsControlJustReleased(0, 38) then
                        dropFingerprint()
                        local canStart = lib.callback('qbx_houserobbery:callback:checkPickup', false, house, i)
                        if not canStart then return end
                        if lib.progressCircle({
                            duration = math.random(4000, 8000),
                            position = 'bottom',
                            canCancel = true,
                            disable = {
                                move = true,
                                combat = true,
                            },
                            anim = {
                                dict = 'missexile3',
                                clip = 'ex03_dingy_search_case_base_michael',
                                flag = 1,
                                blendIn = 1.0
                            },
                        }) then
                            TriggerServerEvent('qbx_houserobbery:server:pickupFinished', house, i)
                        else
                            TriggerServerEvent('qbx_houserobbery:server:pickupCancelled', house, i)
                        end
                    end
                elseif #(playerCoords - sharedConfig.houses[house].pickups[i].coords) < 30.0 and sharedConfig.houses[house].pickups[i].isOpened then
                    local Pickup = sharedConfig.houses[house].pickups[i]
                    local Entity = GetClosestObjectOfType(Pickup.coords.x, Pickup.coords.y, Pickup.coords.z, 3.0, joaat(Pickup.prop), false, false, false)
                    if DoesEntityExist(Entity) then
                        SetEntityVisible(Entity, false, false)
                    end
                end
            end
        end
        if not nearby and hasShownText then
            hasShownText = false
            lib.hideTextUI()
        end
        Wait(waitTime)
    end
end)

lib.callback.register('qbx_houserobbery:callback:startSkillcheck', function(difficulty)
    lib.requestAnimDict('veh@break_in@0h@p_m_one@')
    TaskPlayAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'std_force_entry_rds', 3.0, 3.0, -1, 17, 0, false, false, false)
    local Success = lib.skillCheck(difficulty)
    ClearPedTasks(cache.ped)
    RemoveAnimDict('veh@break_in@0h@p_m_one@')
    return Success
end)

lib.callback.register('qbx_houserobbery:callback:checkTime', function()
    local currentHour = GetClockHours()
    return currentHour >= config.startHours or currentHour <= config.endHours
end)

RegisterNetEvent('qbx_houserobbery:client:syncconfig', function(data, index)
    if index then
        sharedConfig.houses[index] = data
    else
        sharedConfig.houses = data
    end
end)
