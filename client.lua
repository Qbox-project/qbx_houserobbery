local House = 1

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        for i = 1, #Config.Houses do
            if #(PlayerCoords - Config.Houses[i].coords) <= 1.4 and Config.Houses[i].opened then
                WaitTime = 0
                Nearby = true
                House = i
                if Config.UseDrawText then
                    if not HasShownText then
                        HasShownText = true
                        lib.showTextUI(Lang:t('text.enter_house'), {position = 'left-center'})
                    end
                else
                    DrawText3D(Lang:t('text.enter_house'), Config.Houses[i].coords)
                end
                if IsControlJustReleased(0, 38) then
                    lib.requestAnimDict('anim@heists@keycard@')
                    TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, false, false, false)
                    TriggerServerEvent('qb-houserobbery:server:enterHouse', i)
                    RemoveAnimDict('anim@heists@keycard@')
                end
            elseif #(PlayerCoords - Config.Houses[i].coords) <= 1.6 and not Config.Houses[i].opened then
                WaitTime = 0
                Nearby = true
                if Config.UseDrawText then
                    if not HasShownText then
                        HasShownText = true
                        lib.showTextUI(Lang:t('text.enter_requirements'), {position = 'left-center'})
                    end
                else
                    DrawText3D(Lang:t('text.enter_requirements'), Config.Houses[i].coords)
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
        for i = 1, #Config.Interiors do
            local Exit = vector3(Config.Interiors[i].exit.x, Config.Interiors[i].exit.y, Config.Interiors[i].exit.z)
            if #(PlayerCoords - Exit) <= 1.4 then
                WaitTime = 0
                Nearby = true
                if Config.UseDrawText then
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
        if Config.Houses[House].opened and Config.Houses[House].loot[1] then
            for i = 1, #Config.Houses[House].loot do
                if #(PlayerCoords - Config.Houses[House].loot[i].coords) < 0.8 and not Config.Houses[House].loot[i].isOpened then
                    WaitTime = 0
                    Nearby = true
                    if Config.UseDrawText then
                        if not HasShownText then
                            HasShownText = true
                            lib.showTextUI(Lang:t('text.search'), {position = 'left-center'})
                        end
                    else
                        DrawText3D(Lang:t('text.search'), Config.Houses[House].loot[i].coords)
                    end
                    if IsControlJustReleased(0, 38) then
                        if not IsWearingGloves() then
                            if Config.FingerDropChance > math.random(0, 100) then TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped)) end
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
        if Config.Houses[House].opened and Config.Houses[House].pickups[1] then
            for i = 1, #Config.Houses[House].pickups do
                if #(PlayerCoords - Config.Houses[House].pickups[i].coords) < 0.8 and not Config.Houses[House].pickups[i].isOpened then
                    WaitTime = 0
                    Nearby = true
                    if Config.UseDrawText then
                        if not HasShownText then
                            HasShownText = true
                            lib.showTextUI(Lang:t('text.pickup', {Item = QBCore.Shared.Items[Config.Houses[House].pickups[i].reward]['label']}), {position = 'left-center'})
                        end
                    else
                        DrawText3D(Lang:t('text.pickup', {Item = QBCore.Shared.Items[Config.Houses[House].pickups[i].reward]['label']}), Config.Houses[House].pickups[i].coords)
                    end
                    if IsControlJustReleased(0, 38) then
                        if not IsWearingGloves() then
                            if Config.FingerDropChance > math.random(0, 100) then TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped)) end
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
                elseif #(PlayerCoords - Config.Houses[House].pickups[i].coords) < 30.0 and Config.Houses[House].pickups[i].isOpened then
                    local Pickup = Config.Houses[House].pickups[i]
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
    if CurrentHour >= Config.Hours.Start or CurrentHour <= Config.Hours.End then
        return true
    else
        return false
    end
end)

RegisterNetEvent('qb-houserobbery:client:syncconfig', function(Data, Index)
    if Index then
        Config.Houses[Index] = Data
    else
        Config.Houses = Data
    end
end)
