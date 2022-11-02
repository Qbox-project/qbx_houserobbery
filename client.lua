local QBCore = exports['qb-core']:GetCoreObject()
local House = 1

local function DrawText3D(coords, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function LoadAnimDict(dict) while not HasAnimDictLoaded(dict) do RequestAnimDict(dict) Wait(0) end end

CreateThread(function()
    local HasShownText
    local HasShownItems
    local RequiredItems = {
        { name = QBCore.Shared.Items[Config.RequiredItems[1]]['name'], image = QBCore.Shared.Items[Config.RequiredItems[1]]['image'] },
        { name = QBCore.Shared.Items[Config.RequiredItems[2]]['name'], image = QBCore.Shared.Items[Config.RequiredItems[2]]['image'] }
    }
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        for i = 1, #Config.Houses do
            if #(PlayerCoords - Config.Houses[i].coords) <= 1.4 and Config.Houses[i].opened then
                WaitTime = 0
                Nearby = true
                if Config.UseDrawText then
                    if not HasShownText then HasShownText = true exports['qb-core']:DrawText(Lang:t('text.enter_house')) end
                else
                    DrawText3D(Config.Houses[i].coords, Lang:t('text.enter_house'))
                end
                if IsControlJustReleased(0, 38) then
                    LoadAnimDict('anim@heists@keycard@')
                    TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, false, false, false)
                    TriggerServerEvent('qb-houserobbery:server:enterHouse', i)
                    House = i
                    RemoveAnimDict('anim@heists@keycard@')
                end
            elseif #(PlayerCoords - Config.Houses[i].coords) <= 1.6 and not Config.Houses[i].opened then
                WaitTime = 300
                Nearby = true
                if not HasShownItems then HasShownItems = true TriggerEvent('inventory:client:requiredItems', RequiredItems, true) end
            end
        end
        if not Nearby and HasShownItems then HasShownItems = false TriggerEvent('inventory:client:requiredItems', RequiredItems, false) end
        if not Nearby and HasShownText then HasShownText = false exports['qb-core']:HideText() end
        Wait(WaitTime)
    end
end)

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        for i = 1, #Config.Houses do
            local Exit = vector3(Config.Interiors[Config.Houses[i].interior].exit.x, Config.Interiors[Config.Houses[i].interior].exit.y, Config.Interiors[Config.Houses[i].interior].exit.z)
            if #(PlayerCoords - Exit) <= 1.4 then
                WaitTime = 0
                Nearby = true
                if Config.UseDrawText then
                    if not HasShownText then HasShownText = true exports['qb-core']:DrawText(Lang:t('text.leave_house')) end
                else
                    DrawText3D(Exit, Lang:t('text.leave_house'))
                end
                if IsControlJustReleased(0, 38) then
                    LoadAnimDict('anim@heists@keycard@')
                    TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, false, false, false)
                    TriggerServerEvent('qb-houserobbery:server:leaveHouse', i)
                    RemoveAnimDict('anim@heists@keycard@')
                end
            end
        end
        if not Nearby and HasShownText then HasShownText = false exports['qb-core']:HideText() end
        Wait(WaitTime)
    end
end)

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        if Config.Houses[House].opened and Config.Houses[House].loot[1] then
            for i = 1, #Config.Houses[House].loot do
                if #(PlayerCoords - Config.Houses[House].loot[i].coords) < 0.8 and not Config.Houses[House].loot[i].isOpened then
                    WaitTime = 0
                    Nearby = true
                    if Config.UseDrawText then
                        if not HasShownText then HasShownText = true exports['qb-core']:DrawText(Lang:t('text.search')) end
                    else
                        DrawText3D(Config.Houses[House].loot[i].coords, Lang:t('text.search'))
                    end
                    if IsControlJustReleased(0, 38) then
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
        if not Nearby and HasShownText then HasShownText = false exports['qb-core']:HideText() end
        Wait(WaitTime)
    end
end)

CreateThread(function()
    local HasShownText
    local HasHidEntity
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        if Config.Houses[House].opened and Config.Houses[House].pickups[1] then
            for i = 1, #Config.Houses[House].pickups do
                if #(PlayerCoords - Config.Houses[House].pickups[i].coords) < 0.8 and not Config.Houses[House].pickups[i].isOpened then
                    WaitTime = 0
                    Nearby = true
                    if Config.UseDrawText then
                        if not HasShownText then HasShownText = true exports['qb-core']:DrawText(Lang:t('text.pickup', { Item = QBCore.Shared.Items[Config.Houses[House].pickups[i].reward]['label'] })) end
                    else
                        DrawText3D(Config.Houses[House].pickups[i].coords, Lang:t('text.pickup', { Item = QBCore.Shared.Items[Config.Houses[House].pickups[i].reward]['label'] }))
                    end
                    if IsControlJustReleased(0, 38) then
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
                elseif #(PlayerCoords - Config.Houses[House].pickups[i].coords) < 30.0 and Config.Houses[House].pickups[i].isOpened then
                    local Pickup = Config.Houses[House].pickups[i]
                    local Entity = GetClosestObjectOfType(Pickup.coords.x, Pickup.coords.y, Pickup.coords.z, 3.0, joaat(Pickup.prop), false, false, false)
                    if DoesEntityExist(Entity) then
                        SetEntityVisible(Entity, false, false)
                    end
                end
            end
        end
        if not Nearby and HasShownText then HasShownText = false exports['qb-core']:HideText() end
        Wait(WaitTime)
    end
end)

lib.callback.register('qb-houserobbery:callback:startSkillcheck', function(Difficulty)
    LoadAnimDict('veh@break_in@0h@p_m_one@')
    TaskPlayAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'std_force_entry_rds', 3.0, 3.0, -1, 17, 0, false, false, false)
    local Success = lib.skillCheck(Difficulty)
    ClearPedTasks(cache.ped)
    RemoveAnimDict('veh@break_in@0h@p_m_one@')
    return Success
end)

RegisterNetEvent('qb-houserobbery:client:syncconfig', function(Data, Index)
    if Index then
        Config.Houses[Index] = Data
    else
        Config.Houses = Data
    end
end)
