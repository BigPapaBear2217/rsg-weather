local RSGCore = exports['rsg-core']:GetCoreObject()

-- ==========================================
--              GLOBAL VARIABLES
-- ==========================================
local currentWeather = 'SUNNY'
local currentTemperature = 20
local playerEffects = {}
local currentZone = nil
local lastZone = nil
local weatherTransitioning = false
local nuiVisible = false
local playerData = {}
local clothingWarmth = 0
local inShelter = false
local weatherForecast = {}

-- ==========================================
--              UTILITY FUNCTIONS
-- ==========================================

local function DebugPrint(message)
    if Config.Debug then
        print('^3[RSG-Weather-Client]^7 ' .. tostring(message))
    end
end

local function ConvertTemperature(celsius)
    if Config.UseMetric then
        return celsius, '°C'
    else
        return math.floor((celsius * 9/5) + 32), '°F'
    end
end

local function GetWeatherHash(weatherType)
    return Config.WeatherTypes[weatherType] and Config.WeatherTypes[weatherType].hash or `SUNNY`
end

local function IsPlayerInInterior()
    return GetInteriorFromEntity(PlayerPedId()) ~= 0
end

local function CheckShelterStatus()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Check if in interior
    if IsPlayerInInterior() then
        return true
    end
    
    -- Check if under roof/shelter objects
    if Config.PlayerEffects.shelter.underRoof then
        local raycast = StartShapeTestRay(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z + 10.0, -1, ped, 0)
        local _, hit, _, _, entity = GetShapeTestResult(raycast)
        
        if hit and entity ~= 0 then
            return true
        end
    end
    
    -- Check for shelter objects nearby
    if Config.PlayerEffects.shelter.enabled then
        for _, objectHash in pairs(Config.PlayerEffects.shelter.shelterObjects) do
            local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, Config.PlayerEffects.shelter.shelterRadius, GetHashKey(objectHash), false, false, false)
            if object ~= 0 then
                return true
            end
        end
    end
    
    return false
end

local function CalculateClothingWarmth()
    if not Config.PlayerEffects.clothingSystem.enabled then return 0 end
    
    local ped = PlayerPedId()
    local warmth = 0
    
    -- Verificăm dacă funcția există în RedM
    if GetPedDrawableVariation then
        -- Check hat
        local hat = GetPedDrawableVariation(ped, 0) -- Hat component
        if hat > 0 then
            warmth = warmth + (Config.PlayerEffects.clothingSystem.warmthValues.hats[hat] or 1)
        end
        
        -- Check coat/torso
        local coat = GetPedDrawableVariation(ped, 3) -- Torso component
        if coat > 0 then
            warmth = warmth + (Config.PlayerEffects.clothingSystem.warmthValues.coats[coat] or 3)
        end
        
        -- Check boots
        local boots = GetPedDrawableVariation(ped, 6) -- Foot component
        if boots > 0 then
            warmth = warmth + (Config.PlayerEffects.clothingSystem.warmthValues.boats[boots] or 2)
        end
    else
        -- Folosim o metodă alternativă pentru RedM
        -- În RedM putem folosi GetPedGroupIndex sau alte metode native
        -- Pentru moment, returnăm o valoare implicită
        DebugPrint("GetPedDrawableVariation not available in RedM, using default warmth calculation")
        warmth = 5 -- Valoare implicită
    end
    
    return warmth
end

local function GetCurrentZone()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    for zoneName, zoneData in pairs(Config.WeatherZones) do
        local distance = #(coords - zoneData.center)
        if distance <= zoneData.radius then
            return zoneName, zoneData
        end
    end
    
    return nil, nil
end

-- ==========================================
--              WEATHER FUNCTIONS
-- ==========================================

local function SetGameWeather(weatherType, transitionTime, instant)
    if not Config.WeatherTypes[weatherType] then return end
    
    local weatherHash = GetWeatherHash(weatherType)
    transitionTime = transitionTime or 30.0
    
    if instant or not Config.WeatherTransition.enabled then
        Citizen.InvokeNative(0x59174F1AFE095B5A, weatherHash, true, true, false, 0.0, false)
    else
        Citizen.InvokeNative(0x59174F1AFE095B5A, weatherHash, true, true, true, transitionTime, false)
    end
    
    -- Set additional weather properties
    local weatherData = Config.WeatherTypes[weatherType]
    if weatherData.windSpeed then
        local windSpeed = (weatherData.windSpeed.min + weatherData.windSpeed.max) / 2
        Citizen.InvokeNative(0xD00C2D82DC04A99F, windSpeed) -- SET_WIND_SPEED
    end
    
    currentWeather = weatherType
    DebugPrint('Weather set to: ' .. weatherType)
end

local function UpdateWeatherEffects()
    if not Config.PlayerEffects.enabled then return end
    
    local ped = PlayerPedId()
    local temp = currentTemperature
    local effectiveTemp = temp + clothingWarmth
    
    -- Adjust for shelter
    if inShelter then
        if temp < 15 then
            effectiveTemp = effectiveTemp + 10 -- Shelter provides warmth
        elseif temp > 30 then
            effectiveTemp = effectiveTemp - 5 -- Shelter provides cooling
        end
    end
    
    -- Apply temperature effects
    if effectiveTemp <= Config.PlayerEffects.temperatureEffects.tooCold.threshold then
        local effects = Config.PlayerEffects.temperatureEffects.tooCold.effects
        
        -- Modify player stats
        if effects.hungerRate then
            TriggerServerEvent('rsg-core:server:updateHunger', -effects.hungerRate * 0.1)
        end
        
        -- Movement speed
        if effects.moveSpeed and effects.moveSpeed < 1.0 then
            SetPedMoveRateOverride(ped, effects.moveSpeed)
        end
        
        -- Visual effects - show breath in cold
        if Config.VisualEffects.atmosphere.temperatureVisuals and effectiveTemp < 0 then
            -- Add breath effect particles here if available
        end
        
        -- Notify player
        if math.random() < 0.01 then -- 1% chance per update
            if Lang and Lang.t then
                -- Use lib.notify instead of RSGCore.Functions.Notify
                lib.notify({ title = Lang:t('feeling_cold'), type = 'inform', duration = 5000 })
            else
                lib.notify({ title = 'You feel cold. Find shelter or warmer clothes.', type = 'inform', duration = 5000 })
            end
        end
        
    elseif effectiveTemp >= Config.PlayerEffects.temperatureEffects.tooHot.threshold then
        local effects = Config.PlayerEffects.temperatureEffects.tooHot.effects
        
        -- Modify player stats
        if effects.thirstRate then
            TriggerServerEvent('rsg-core:server:updateThirst', -effects.thirstRate * 0.1)
        end
        
        -- Movement speed
        if effects.moveSpeed and effects.moveSpeed < 1.0 then
            SetPedMoveRateOverride(ped, effects.moveSpeed)
        end
        
        -- Notify player
        if math.random() < 0.01 then -- 1% chance per update
            if Lang and Lang.t then
                -- Use lib.notify instead of RSGCore.Functions.Notify
                lib.notify({ title = Lang:t('feeling_hot'), type = 'inform', duration = 5000 })
            else
                lib.notify({ title = 'You feel overheated. Seek shade and water.', type = 'inform', duration = 5000 })
            end
        end
    else
        -- Reset movement speed if in comfortable range
        SetPedMoveRateOverride(ped, 1.0)
    end
    
    -- Weather-specific effects
    if Config.WeatherBuffs[currentWeather] then
        local buffs = Config.WeatherBuffs[currentWeather]
        
        -- Apply tracking bonus
        if buffs.trackingBonus then
            -- Could integrate with hunting scripts here
        end
        
        -- Apply fishing bonus
        if buffs.fishingBonus then
            -- Could integrate with fishing scripts here
        end
        
        -- Apply stealth bonus
        if buffs.stealthBonus then
            -- Could modify stealth mechanics here
        end
    end
end

local function UpdateHUD()
    if not Config.VisualEffects.hud.showTemperature then return end
    
    local temp, unit = ConvertTemperature(currentTemperature)
    local hudData = {
        weather = currentWeather,
        weatherName = Config.WeatherTypes[currentWeather] and Config.WeatherTypes[currentWeather].name or currentWeather,
        temperature = temp,
        temperatureUnit = unit,
        zone = currentZone or 'Wilderness',
        inShelter = inShelter,
        clothingWarmth = clothingWarmth,
        forecast = weatherForecast
    }
    
    -- Send to NUI
    SendNUIMessage({
        type = 'updateWeather',
        data = hudData
    })
end

-- ==========================================
--              EVENT HANDLERS
-- ==========================================

RegisterNetEvent('rsg-weather:client:weatherUpdate', function(data)
    if not data then return end
    
    DebugPrint('Received weather update: ' .. data.weather)
    
    if data.transition and Config.WeatherTransition.enabled then
        weatherTransitioning = true
        SetGameWeather(data.weather, Config.WeatherTransition.transitionTime, false)
        
        -- Show transition notification
        if Config.VisualEffects.hud.showWeatherIcon then
            if Lang and Lang.t then
                -- Use lib.notify instead of RSGCore.Functions.Notify
                lib.notify({ title = Lang:t('weather_changing'), type = 'inform', duration = 5000 })
            else
                lib.notify({ title = 'Weather is changing...', type = 'inform', duration = 5000 })
            end
        end
        
        CreateThread(function()
            Wait(Config.WeatherTransition.transitionTime * 1000)
            weatherTransitioning = false
        end)
    else
        SetGameWeather(data.weather, 0, true)
    end
    
    currentWeather = data.weather
    currentTemperature = data.temperature
    
    UpdateHUD()
end)

RegisterNetEvent('rsg-weather:client:zoneWeatherUpdate', function(data)
    if not data then return end
    
    DebugPrint('Zone weather update: ' .. data.zone .. ' -> ' .. data.weather)
    
    if currentZone == data.zone then
        SetGameWeather(data.weather, Config.WeatherTransition.transitionTime, false)
        currentWeather = data.weather
        currentTemperature = data.temperature
        UpdateHUD()
    end
end)

RegisterNetEvent('rsg-weather:client:temperatureUpdate', function(temperature)
    currentTemperature = temperature
    UpdateHUD()
end)

RegisterNetEvent('rsg-weather:client:updatePlayerEffects', function(effects)
    playerEffects = effects
    currentTemperature = effects.temperature or currentTemperature
    currentWeather = effects.weather or currentWeather
    currentZone = effects.zone
    
    UpdateWeatherEffects()
    UpdateHUD()
end)

RegisterNetEvent('rsg-weather:client:forecastUpdate', function(forecast)
    weatherForecast = forecast
    UpdateHUD()
end)

RegisterNetEvent('rsg-weather:client:seasonUpdate', function(season)
    DebugPrint('Season changed to: ' .. season)
    -- Use lib.notify instead of RSGCore.Functions.Notify
    lib.notify({ title = 'Season changed to ' .. season, type = 'inform', duration = 5000 })
end)

RegisterNetEvent('rsg-weather:client:jobWeatherBonus', function(bonus)
    if not bonus or bonus.multiplier == 1.0 then return end
    
    local message = ''
    if bonus.multiplier > 1.0 then
        local percent = math.floor((bonus.multiplier - 1.0) * 100)
        if Lang and Lang.t then
            message = Lang:t(bonus.jobType .. '_weather_bonus', percent)
        else
            message = bonus.jobType .. ' weather bonus: ' .. percent .. '%'
        end
    else
        local percent = math.floor((1.0 - bonus.multiplier) * 100)
        if Lang and Lang.t then
            message = Lang:t(bonus.jobType .. '_weather_penalty', percent)
        else
            message = bonus.jobType .. ' weather penalty: ' .. percent .. '%'
        end
    end
    
    if message ~= '' then
        -- Use lib.notify instead of RSGCore.Functions.Notify
        lib.notify({ title = message, type = 'inform', duration = 5000 })
    end
end)

-- ==========================================
--              NUI CALLBACKS
-- ==========================================

RegisterNUICallback('toggleWeatherUI', function(data, cb)
    nuiVisible = not nuiVisible
    SetNuiFocus(nuiVisible, nuiVisible)
    
    -- Debug print
    print("RSG-Weather: Menu toggled - Visible: " .. tostring(nuiVisible))
    
    SendNUIMessage({
        type = 'toggleVisibility',
        visible = nuiVisible
    })
    
    cb('ok')
end)

RegisterNUICallback('requestForecast', function(data, cb)
    TriggerServerEvent('rsg-weather:server:requestForecast', data.hours or 6)
    cb('ok')
end)

RegisterNUICallback('saveSettings', function(data, cb)
    TriggerServerEvent('rsg-weather:server:savePlayerSettings', data)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    nuiVisible = false
    SetNuiFocus(false, false)
    
    -- Unfreeze player character
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    
    -- Debug print
    print("RSG-Weather: Menu closed and player unfrozen")
    
    -- Additional safety measures
    Citizen.InvokeNative(0xF4F2C0D4EE209E20, true) -- ENABLE_CONTROL_ACTION for all controls
    Citizen.InvokeNative(0x9086DFD5D03B1FC6, 1) -- SET_CURSOR_SPRITE to normal
    
    SendNUIMessage({
        type = 'toggleVisibility',
        visible = false
    })
    
    cb('ok')
end)

RegisterNUICallback('releaseCursor', function(data, cb)
    -- Additional cursor release
    Citizen.InvokeNative(0x9086DFD5D03B1FC6, 1) -- SET_CURSOR_SPRITE to normal
    Citizen.InvokeNative(0xF2CA003F167E21D2, false) -- SET_MOUSE_CURSOR_ACTIVE to false
    
    -- Ensure player control is restored
    Citizen.InvokeNative(0xF4F2C0D4EE209E20, true) -- ENABLE_CONTROL_ACTION for all controls
    
    cb('ok')
end)

-- ==========================================
--              COMMANDS
-- ==========================================

RegisterCommand('weather', function()
    nuiVisible = not nuiVisible
    SetNuiFocus(nuiVisible, nuiVisible)
    
    -- Debug print
    print("RSG-Weather: Command executed - Menu visible: " .. tostring(nuiVisible))
    
    SendNUIMessage({
        type = 'toggleVisibility',
        visible = nuiVisible
    })
    
    if nuiVisible then
        TriggerServerEvent('rsg-weather:server:requestForecast', 6)
    end
end, false)

-- Admin commands
if Config.AdminCommands.enabled then
    RegisterCommand(Config.AdminCommands.commands.setWeather, function(source, args)
        if #args < 1 then
            RSGCore.Functions.Notify('Usage: /' .. Config.AdminCommands.commands.setWeather .. ' <weather_type>', 'error')
            return
        end
        
        TriggerServerEvent('rsg-weather:server:setWeather', string.upper(args[1]))
    end)
    
    RegisterCommand(Config.AdminCommands.commands.setTemp, function(source, args)
        if #args < 1 then
            RSGCore.Functions.Notify('Usage: /' .. Config.AdminCommands.commands.setTemp .. ' <temperature>', 'error')
            return
        end
        
        TriggerServerEvent('rsg-weather:server:setTemperature', tonumber(args[1]))
    end)
    
    RegisterCommand(Config.AdminCommands.commands.weatherInfo, function()
        local temp, unit = ConvertTemperature(currentTemperature)
        local message = 'Current: ' .. currentWeather .. ' | Temp: ' .. temp .. '°' .. unit .. ' | Zone: ' .. (currentZone or 'Wilderness')
        if Lang and Lang.t then
            message = Lang:t('weather_info', currentWeather, temp, unit, currentZone or 'Wilderness')
        end
        -- Use lib.notify instead of RSGCore.Functions.Notify
        lib.notify({ title = message, type = 'inform', duration = 5000 })
    end)
end

-- ==========================================
--                EXPORTS
-- ==========================================

exports('GetCurrentWeather', function()
    return currentWeather
end)

exports('GetCurrentTemperature', function()
    return currentTemperature
end)

exports('GetWeatherInRegion', function(zoneName)
    -- This would need server callback
    return {weather = currentWeather, temperature = currentTemperature}
end)

exports('SetPlayerWeatherEffects', function(enabled)
    Config.PlayerEffects.enabled = enabled
    if not enabled then
        SetPedMoveRateOverride(PlayerPedId(), 1.0)
    end
end)

exports('GetWeatherForecast', function()
    return weatherForecast
end)

exports('IsPlayerInShelter', function()
    return inShelter
end)

-- ==========================================
--              MAIN LOOPS
-- ==========================================

-- Zone monitoring thread
CreateThread(function()
    while true do
        local zoneName, zoneData = GetCurrentZone()
        
        if zoneName ~= currentZone then
            lastZone = currentZone
            currentZone = zoneName
            
            if currentZone then
                DebugPrint('Entered zone: ' .. currentZone)
                local zoneMessage = 'Entering ' .. Config.WeatherZones[currentZone].name
                if Lang and Lang.t then
                    zoneMessage = Lang:t('entering_zone', Config.WeatherZones[currentZone].name)
                end
                -- Use lib.notify instead of RSGCore.Functions.Notify
                lib.notify({ title = zoneMessage, type = 'inform', duration = 5000 })
                TriggerServerEvent('rsg-weather:server:playerZoneChange', currentZone)
            end
        end
        
        Wait(Config.Performance.zoneCheckInterval)
    end
end)

-- Player effects update thread
CreateThread(function()
    while true do
        -- Update clothing warmth
        clothingWarmth = CalculateClothingWarmth()
        
        -- Check shelter status
        inShelter = CheckShelterStatus()
        
        -- Update weather effects
        UpdateWeatherEffects()
        
        -- Update HUD
        if Config.VisualEffects.hud.updateFrequency > 0 then
            UpdateHUD()
        end
        
        Wait(Config.Performance.playerUpdateInterval)
    end
end)

-- HUD update thread
CreateThread(function()
    while true do
        if Config.VisualEffects.hud.updateFrequency > 0 then
            UpdateHUD()
            Wait(Config.VisualEffects.hud.updateFrequency)
        else
            Wait(30000) -- Default 30 second update if disabled
        end
    end
end)

-- ==========================================
--              INITIALIZATION
-- ==========================================

CreateThread(function()
    -- Wait for RSG-Core to load
    while not RSGCore do
        Wait(100)
    end
    
    -- Wait for player to spawn
    while not NetworkIsSessionStarted() do
        Wait(100)
    end
    
    -- Initialize player data
    playerData = RSGCore.Functions.GetPlayerData()
    
    -- Request initial weather update
    TriggerServerEvent('rsg-weather:server:requestWeatherUpdate')
    
    -- Initialize HUD
    UpdateHUD()
    
    DebugPrint('Client weather system initialized')
end)

-- Player data update handler
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    playerData = RSGCore.Functions.GetPlayerData()
    TriggerServerEvent('rsg-weather:server:requestWeatherUpdate')
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    playerData = {}
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if nuiVisible then
            SetNuiFocus(false, false)
        end
        SetPedMoveRateOverride(PlayerPedId(), 1.0)
        -- Ensure cursor is released
        Citizen.InvokeNative(0x9086DFD5D03B1FC6, 1) -- SET_CURSOR_SPRITE to normal
        Citizen.InvokeNative(0xF2CA003F167E21D2, false) -- SET_MOUSE_CURSOR_ACTIVE to false
        -- Ensure player controls are restored
        Citizen.InvokeNative(0xF4F2C0D4EE209E20, true) -- ENABLE_CONTROL_ACTION for all controls
    end
end)