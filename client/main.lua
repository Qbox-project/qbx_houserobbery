local config = require 'config.client'
local sharedConfig = require 'config.shared'

local House = 1

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        for i = 1, #sharedConfig.houses do
            if #(PlayerCoords - sharedConfig.houses[i].coords) <= 1.4 and sharedConfig.houses[i].opened then
                WaitTime = 0
                Nearby = true
                House = i
                if config.useDrawText then
                    if not HasShownText then
                        HasShownText = true
                        lib.showTextUI(Lang:t('text.enter_house'), {position = 'left-center'})
                    end
                else
                    DrawText3D(Lang:t('text.enter_house'), sharedConfig.houses[i].coords)
                end
                if IsControlJustReleased(0, 38) then
                    lib.requestAnimDict('anim@heists@keycard@')
                    TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, false, false, false)
                    TriggerServerEvent('qb-houserobbery:server:enterHouse', i)
                    RemoveAnimDict('anim@heists@keycard@')
                end
            elseif #(PlayerCoords - sharedConfig.houses[i].coords) <= 1.6 and not sharedConfig.houses[i].opened then
                WaitTime = 0
                Nearby = true
                if config.useDrawText then
                    if not HasShownText then
                        HasShownText = true
                        lib.showTextUI(Lang:t('text.enter_requirements'), {position = 'left-center'})
                    end
                else
                    DrawText3D(Lang:t('text.enter_requirements'), sharedConfig.houses[i].coords)
                end
            end
        end
        if not Nearby and HasShownText then HasShownText = false exports['qbx-core']:HideText() end
        Wait(WaitTime)
    end
end)

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        for i = 1, #sharedConfig.interiors do
            local Exit = vector3(sharedConfig.interiors[i].exit.x, sharedConfig.interiors[i].exit.y, sharedConfig.interiors[i].exit.z)
            if #(PlayerCoords - Exit) <= 1.4 then
                WaitTime = 0
                Nearby = true
                if config.useDrawText then
                    if not HasShownText then
                        HasShownText = true
                        lib.showTextUI(Lang:t('text.leave_house'), {position = 'left-center'})
                    end
                else
                    DrawText3D(Lang:t('text.leave_house'), Exit)
                end
                if IsControlJustReleased(0, 38) then
                    lib.requestAnimDict('anim@heists@keycard@')
                    TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, false, false, false)
                    TriggerServerEvent('qb-houserobbery:server:leaveHouse')
                    RemoveAnimDict('anim@heists@keycard@')
                end
            end
        end
        if not Nearby and HasShownText then HasShownText = false exports['qbx-core']:HideText() end
        Wait(WaitTime)
    end
end)

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        if sharedConfig.houses[House].opened and sharedConfig.houses[House].loot[1] then
            for i = 1, #sharedConfig.houses[House].loot do
                if #(PlayerCoords - sharedConfig.houses[House].loot[i].coords) < 0.8 and not sharedConfig.houses[House].loot[i].isOpened then
                    WaitTime = 0
                    Nearby = true
                    if config.useDrawText then
                        if not HasShownText then
                            HasShownText = true
                            lib.showTextUI(Lang:t('text.search'), {position = 'left-center'})
                        end
                    else
                        DrawText3D(Lang:t('text.search'), sharedConfig.houses[House].loot[i].coords)
                    end
                    if IsControlJustReleased(0, 38) then
                        if not IsWearingGloves() then
                            if config.fingerDropChance > math.random(0, 100) then TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped)) end
                        end
                        lib.callback('qb-houserobbery:callback:checkLoot', false, function(CanStart)
                            if not CanStart then return end
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
                                TriggerServerEvent('qb-houserobbery:server:lootFinished', House, i)
                            else
                                TriggerServerEvent('qb-houserobbery:server:lootCancelled', House, i)
                            end
                        end, House, i)
                    end
                end
            end
        end
        if not Nearby and HasShownText then HasShownText = false exports['qbx-core']:HideText() end
        Wait(WaitTime)
    end
end)

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        if sharedConfig.houses[House].opened and sharedConfig.houses[House].pickups[1] then
            for i = 1, #sharedConfig.houses[House].pickups do
                if #(PlayerCoords - sharedConfig.houses[House].pickups[i].coords) < 0.8 and not sharedConfig.houses[House].pickups[i].isOpened then
                    WaitTime = 0
                    Nearby = true
                    if config.useDrawText then
                        if not HasShownText then
                            HasShownText = true
                            lib.showTextUI(Lang:t('text.pickup', {Item = QBCore.Shared.Items[sharedConfig.houses[House].pickups[i].reward]['label']}), {position = 'left-center'})
                        end
                    else
                        DrawText3D(Lang:t('text.pickup', {Item = QBCore.Shared.Items[sharedConfig.houses[House].pickups[i].reward]['label']}), sharedConfig.houses[House].pickups[i].coords)
                    end
                    if IsControlJustReleased(0, 38) then
                        if not IsWearingGloves() then
                            if config.fingerDropChance > math.random(0, 100) then TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped)) end
                        end
                        lib.callback('qb-houserobbery:callback:checkPickup', false, function(CanStart)
                            if not CanStart then return end
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
                                TriggerServerEvent('qb-houserobbery:server:pickupFinished', House, i)
                            else
                                TriggerServerEvent('qb-houserobbery:server:pickupCancelled', House, i)
                            end
                        end, House, i)
                    end
                elseif #(PlayerCoords - sharedConfig.houses[House].pickups[i].coords) < 30.0 and sharedConfig.houses[House].pickups[i].isOpened then
                    local Pickup = sharedConfig.houses[House].pickups[i]
                    local Entity = GetClosestObjectOfType(Pickup.coords.x, Pickup.coords.y, Pickup.coords.z, 3.0, joaat(Pickup.prop), false, false, false)
                    if DoesEntityExist(Entity) then
                        SetEntityVisible(Entity, false, false)
                    end
                end
            end
        end
        if not Nearby and HasShownText then HasShownText = false exports['qbx-core']:HideText() end
        Wait(WaitTime)
    end
end)

lib.callback.register('qb-houserobbery:callback:startSkillcheck', function(Difficulty)
    lib.requestAnimDict('veh@break_in@0h@p_m_one@')
    TaskPlayAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'std_force_entry_rds', 3.0, 3.0, -1, 17, 0, false, false, false)
    local Success = lib.skillCheck(Difficulty)
    ClearPedTasks(cache.ped)
    RemoveAnimDict('veh@break_in@0h@p_m_one@')
    return Success
end)

lib.callback.register('qb-houserobbery:callback:checkTime', function()
    local CurrentHour = GetClockHours()
    if CurrentHour >= config.startHours or CurrentHour <= config.endHours then
        return true
    else
        return false
    end
end)

RegisterNetEvent('qb-houserobbery:client:syncconfig', function(Data, Index)
    if Index then
        sharedConfig.houses[Index] = Data
    else
        sharedConfig.houses = Data
    end
end)
