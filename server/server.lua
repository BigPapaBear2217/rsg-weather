local RSGCore = exports['rsg-core']:GetCoreObject()

-- ==========================================
--              GLOBAL VARIABLES
-- ==========================================
local currentWeather = 'SUNNY'
local currentTemperature = 20
local weatherCycleTimer = 0
local zoneWeatherData = {}
local playerWeatherData = {}
local weatherHistory = {}
local currentSeason = 'spring'
local seasonStartTime = 0

-- ==========================================
--              UTILITY FUNCTIONS
-- ==========================================

local function DebugPrint(message)
    if Config.Debug then
        print('^3[RSG-Weather-Debug]^7 ' .. tostring(message))
    end
end

local function GetCurrentSeason()
    local currentTime = os.time()
    local daysSinceStart = math.floor((currentTime - seasonStartTime) / (24 * 60 * 60))
    local seasonIndex = math.floor(daysSinceStart / Config.Seasons.seasonLength) % 4
    
    local seasons = {'spring', 'summer', 'autumn', 'winter'}
    return seasons[seasonIndex + 1]
end

local function GetWeatherProbability(zone, weatherType)
    local baseProbability = zone.weatherProbabilities[weatherType] or 0
    local season = GetCurrentSeason()
    local seasonData = Config.Seasons[season]
    
    if seasonData and seasonData.weatherBias[weatherType] then
        baseProbability = baseProbability * seasonData.weatherBias[weatherType]
    end
    
    return baseProbability
end

local function GetTemperatureForWeather(weatherType, zone)
    local weatherData = Config.WeatherTypes[weatherType]
    if not weatherData then return 20 end
    
    local baseTemp = math.random(weatherData.temp.min, weatherData.temp.max)
    local zoneModifier = zone and zone.tempModifier or 0
    local seasonModifier = Config.Seasons[GetCurrentSeason()].tempModifier or 0
    
    return baseTemp + zoneModifier + seasonModifier
end

local function GetPlayerZone(playerId)
    local player = RSGCore.Functions.GetPlayer(playerId)
    if not player then return nil end
    
    local ped = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(ped)
    
    for zoneName, zoneData in pairs(Config.WeatherZones) do
        local distance = #(playerCoords - zoneData.center)
        if distance <= zoneData.radius then
            return zoneName, zoneData
        end
    end
    
    return nil, nil
end

-- ==========================================
--              DATABASE FUNCTIONS
-- ==========================================

local function InitializeDatabase()
    if not Config.Database.enabled then return end
    
    -- Create weather_cycles table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. Config.Database.tables.weather_cycles .. [[` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `weather_type` varchar(50) NOT NULL,
            `temperature` decimal(5,2) NOT NULL,
            `zone` varchar(50) DEFAULT NULL,
            `start_time` timestamp DEFAULT CURRENT_TIMESTAMP,
            `duration` int(11) NOT NULL DEFAULT 3600,
            PRIMARY KEY (`id`),
            KEY `weather_type` (`weather_type`),
            KEY `zone` (`zone`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Create weather_zones table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. Config.Database.tables.weather_zones .. [[` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `zone_name` varchar(50) NOT NULL,
            `current_weather` varchar(50) NOT NULL,
            `temperature` decimal(5,2) NOT NULL,
            `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `zone_name` (`zone_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Create weather_history table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. Config.Database.tables.weather_history .. [[` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `weather_type` varchar(50) NOT NULL,
            `temperature` decimal(5,2) NOT NULL,
            `zone` varchar(50) DEFAULT NULL,
            `recorded_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `recorded_at` (`recorded_at`),
            KEY `zone` (`zone`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Create player_weather_settings table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. Config.Database.tables.player_weather_settings .. [[` (
            `citizenid` varchar(50) NOT NULL,
            `notifications_enabled` tinyint(1) DEFAULT 1,
            `temperature_unit` enum('celsius','fahrenheit') DEFAULT 'celsius',
            `effects_enabled` tinyint(1) DEFAULT 1,
            `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    DebugPrint('Database tables initialized')
end

local function SaveWeatherData(weatherType, temperature, zone)
    if not Config.Database.enabled then return end
    
    MySQL.insert('INSERT INTO `' .. Config.Database.tables.weather_history .. '` (weather_type, temperature, zone) VALUES (?, ?, ?)', {
        weatherType, temperature, zone
    })
end

local function LoadPlayerWeatherSettings(citizenid)
    if not Config.Database.enabled then return {} end
    
    local result = MySQL.scalar.await('SELECT * FROM `' .. Config.Database.tables.player_weather_settings .. '` WHERE citizenid = ?', {citizenid})
    return result or {}
end

-- ==========================================
--            WEATHER LOGIC FUNCTIONS
-- ==========================================

local function GenerateNewWeather(zoneName)
    local zone = Config.WeatherZones[zoneName]
    if not zone then
        -- Global weather if no zone specified
        local weatherTypes = {}
        for weatherType, _ in pairs(Config.WeatherTypes) do
            table.insert(weatherTypes, weatherType)
        end
        return weatherTypes[math.random(#weatherTypes)]
    end
    
    local totalWeight = 0
    for weatherType, probability in pairs(zone.weatherProbabilities) do
        totalWeight = totalWeight + GetWeatherProbability(zone, weatherType)
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for weatherType, probability in pairs(zone.weatherProbabilities) do
        currentWeight = currentWeight + GetWeatherProbability(zone, weatherType)
        if random <= currentWeight then
            return weatherType
        end
    end
    
    return 'SUNNY' -- Fallback
end

local function UpdateWeatherCycle()
    weatherCycleTimer = weatherCycleTimer + Config.UpdateInterval
    
    if weatherCycleTimer >= Config.SyncInterval then
        weatherCycleTimer = 0
        
        -- Update global weather
        local newWeather = GenerateNewWeather()
        if newWeather ~= currentWeather then
            currentWeather = newWeather
            currentTemperature = GetTemperatureForWeather(newWeather)
            
            DebugPrint('Weather changed to: ' .. newWeather .. ' (Temp: ' .. currentTemperature .. '°C)')
            
            -- Notify all clients
            TriggerClientEvent('rsg-weather:client:weatherUpdate', -1, {
                weather = currentWeather,
                temperature = currentTemperature,
                transition = Config.WeatherTransition.enabled
            })
            
            -- Save to database
            SaveWeatherData(currentWeather, currentTemperature, 'global')
        end
        
        -- Update zone weather
        for zoneName, zoneData in pairs(Config.WeatherZones) do
            local zoneWeather = GenerateNewWeather(zoneName)
            local zoneTemp = GetTemperatureForWeather(zoneWeather, zoneData)
            
            if not zoneWeatherData[zoneName] or zoneWeatherData[zoneName].weather ~= zoneWeather then
                zoneWeatherData[zoneName] = {
                    weather = zoneWeather,
                    temperature = zoneTemp,
                    lastUpdate = os.time()
                }
                
                DebugPrint('Zone ' .. zoneName .. ' weather: ' .. zoneWeather .. ' (Temp: ' .. zoneTemp .. '°C)')
                
                -- Save zone weather to database
                SaveWeatherData(zoneWeather, zoneTemp, zoneName)
                
                -- Update players in this zone
                for playerId, _ in pairs(playerWeatherData) do
                    local playerZone, _ = GetPlayerZone(playerId)
                    if playerZone == zoneName then
                        TriggerClientEvent('rsg-weather:client:zoneWeatherUpdate', playerId, {
                            zone = zoneName,
                            weather = zoneWeather,
                            temperature = zoneTemp
                        })
                    end
                end
            end
        end
        
        -- Update season if needed
        local newSeason = GetCurrentSeason()
        if newSeason ~= currentSeason then
            currentSeason = newSeason
            TriggerClientEvent('rsg-weather:client:seasonUpdate', -1, currentSeason)
            DebugPrint('Season changed to: ' .. currentSeason)
        end
    end
end

local function GetWeatherForecast(hours)
    hours = hours or 6
    local forecast = {}
    
    for i = 1, hours do
        -- Simple forecast algorithm - can be improved
        local forecastWeather = GenerateNewWeather()
        local forecastTemp = GetTemperatureForWeather(forecastWeather)
        
        table.insert(forecast, {
            hour = i,
            weather = forecastWeather,
            temperature = forecastTemp,
            accuracy = Config.VisualEffects.forecast.accuracy
        })
    end
    
    return forecast
end

-- ==========================================
--              PLAYER FUNCTIONS
-- ==========================================

local function UpdatePlayerWeatherEffects(playerId)
    local player = RSGCore.Functions.GetPlayer(playerId)
    if not player then return end
    
    local zoneName, zoneData = GetPlayerZone(playerId)
    local weatherData = zoneWeatherData[zoneName] or {weather = currentWeather, temperature = currentTemperature}
    
    -- Calculate player weather effects
    local effects = {
        temperature = weatherData.temperature,
        weather = weatherData.weather,
        zone = zoneName or 'wilderness',
        effects = {}
    }
    
    -- Temperature effects
    if Config.PlayerEffects.enabled then
        if weatherData.temperature <= Config.PlayerEffects.temperatureEffects.tooCold.threshold then
            effects.effects.cold = Config.PlayerEffects.temperatureEffects.tooCold.effects
        elseif weatherData.temperature >= Config.PlayerEffects.temperatureEffects.tooHot.threshold then
            effects.effects.hot = Config.PlayerEffects.temperatureEffects.tooHot.effects
        end
    end
    
    -- Weather buffs/debuffs
    if Config.WeatherBuffs[weatherData.weather] then
        effects.effects.weather = Config.WeatherBuffs[weatherData.weather]
    end
    
    -- Send to client
    TriggerClientEvent('rsg-weather:client:updatePlayerEffects', playerId, effects)
    
    -- Update player data
    playerWeatherData[playerId] = effects
end

-- ==========================================
--              EVENT HANDLERS
-- ==========================================

RegisterNetEvent('rsg-weather:server:requestWeatherUpdate', function()
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end
    
    UpdatePlayerWeatherEffects(src)
end)

RegisterNetEvent('rsg-weather:server:requestForecast', function(hours)
    local src = source
    local forecast = GetWeatherForecast(hours)
    TriggerClientEvent('rsg-weather:client:forecastUpdate', src, forecast)
end)

RegisterNetEvent('rsg-weather:server:requestZoneWeather', function()
    local src = source
    TriggerClientEvent('rsg-weather:client:updateZones', src, zoneWeatherData)
end)

RegisterNetEvent('rsg-weather:server:playerZoneChange', function(zoneName)
    local src = source
    UpdatePlayerWeatherEffects(src)
end)

RegisterNetEvent('rsg-weather:server:savePlayerSettings', function(settings)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end
    
    if Config.Database.enabled then
        MySQL.insert('INSERT INTO `' .. Config.Database.tables.player_weather_settings .. '` (citizenid, notifications_enabled, temperature_unit, effects_enabled) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE notifications_enabled = VALUES(notifications_enabled), temperature_unit = VALUES(temperature_unit), effects_enabled = VALUES(effects_enabled)', {
            player.PlayerData.citizenid,
            settings.notifications and 1 or 0,
            settings.temperatureUnit or 'celsius',
            settings.effects and 1 or 0
        })
    end
end)

-- Job Integration Events
RegisterNetEvent('rsg-weather:server:getJobWeatherBonus', function(jobType)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end
    
    local zoneName, _ = GetPlayerZone(src)
    local weatherData = zoneWeatherData[zoneName] or {weather = currentWeather, temperature = currentTemperature}
    
    local multiplier = 1.0
    local bonus = {}
    
    if Config.JobIntegration.enabled and Config.JobIntegration[jobType] and Config.JobIntegration[jobType].enabled then
        local jobConfig = Config.JobIntegration[jobType]
        
        if jobConfig.weatherMultipliers[weatherData.weather] then
            multiplier = jobConfig.weatherMultipliers[weatherData.weather]
        end
        
        if jobConfig.temperatureEffects then
            local temp = weatherData.temperature
            local optimal = jobConfig.temperatureEffects.optimal
            if temp >= optimal.min and temp <= optimal.max then
                multiplier = multiplier * (jobConfig.temperatureEffects.bonus or 1.0)
            end
        end
        
        bonus = {
            multiplier = multiplier,
            weather = weatherData.weather,
            temperature = weatherData.temperature,
            jobType = jobType
        }
    end
    
    TriggerClientEvent('rsg-weather:client:jobWeatherBonus', src, bonus)
end)

-- ==========================================
--              ADMIN COMMANDS
-- ==========================================

local function IsPlayerAdmin(playerId)
    local player = RSGCore.Functions.GetPlayer(playerId)
    if not player then return false end
    
    return RSGCore.Functions.HasPermission(playerId, Config.AdminCommands.requiredGrade) or false
end

RegisterNetEvent('rsg-weather:server:setWeather', function(weatherType)
    local src = source
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('no_permission'), 'error')
        return
    end
    
    if Config.WeatherTypes[weatherType] then
        currentWeather = weatherType
        currentTemperature = GetTemperatureForWeather(weatherType)
        
        TriggerClientEvent('rsg-weather:client:weatherUpdate', -1, {
            weather = currentWeather,
            temperature = currentTemperature,
            transition = false -- Instant admin change
        })
        
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('weather_set', weatherType), 'success')
        DebugPrint('Admin ' .. GetPlayerName(src) .. ' set weather to: ' .. weatherType)
    else
        local availableWeather = {}
        for weather, _ in pairs(Config.WeatherTypes) do
            table.insert(availableWeather, weather)
        end
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('invalid_weather', table.concat(availableWeather, ', ')), 'error')
    end
end)

RegisterNetEvent('rsg-weather:server:setTemperature', function(temperature)
    local src = source
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('no_permission'), 'error')
        return
    end
    
    local temp = tonumber(temperature)
    if temp and temp >= -50 and temp <= 60 then
        currentTemperature = temp
        
        TriggerClientEvent('rsg-weather:client:temperatureUpdate', -1, currentTemperature)
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('temp_set', temp, Config.UseMetric and 'C' or 'F'), 'success')
    else
        TriggerClientEvent('RSGCore:Notify', src, 'Invalid temperature range (-50 to 60)', 'error')
    end
end)

-- ==========================================
--                 EXPORTS
-- ==========================================

exports('GetCurrentWeather', function()
    return currentWeather
end)

exports('GetCurrentTemperature', function()
    return currentTemperature
end)

exports('GetWeatherInRegion', function(zoneName)
    return zoneWeatherData[zoneName] or {weather = currentWeather, temperature = currentTemperature}
end)

exports('SetWeatherType', function(weatherType, zone)
    if Config.WeatherTypes[weatherType] then
        if zone and Config.WeatherZones[zone] then
            zoneWeatherData[zone] = {
                weather = weatherType,
                temperature = GetTemperatureForWeather(weatherType, Config.WeatherZones[zone]),
                lastUpdate = os.time()
            }
        else
            currentWeather = weatherType
            currentTemperature = GetTemperatureForWeather(weatherType)
            
            TriggerClientEvent('rsg-weather:client:weatherUpdate', -1, {
                weather = currentWeather,
                temperature = currentTemperature,
                transition = Config.WeatherTransition.enabled
            })
        end
        return true
    end
    return false
end)

exports('GetWeatherHistory', function(hours)
    if not Config.Database.enabled then return {} end
    
    local result = MySQL.query.await('SELECT * FROM `' .. Config.Database.tables.weather_history .. '` WHERE recorded_at >= DATE_SUB(NOW(), INTERVAL ? HOUR) ORDER BY recorded_at DESC', {hours or 24})
    return result or {}
end)

-- ==========================================
--              INITIALIZATION
-- ==========================================

CreateThread(function()
    -- Initialize database
    InitializeDatabase()
    
    -- Initialize season system
    seasonStartTime = os.time()
    currentSeason = GetCurrentSeason()
    
    -- Initialize zone weather
    for zoneName, zoneData in pairs(Config.WeatherZones) do
        local weather = GenerateNewWeather(zoneName)
        zoneWeatherData[zoneName] = {
            weather = weather,
            temperature = GetTemperatureForWeather(weather, zoneData),
            lastUpdate = os.time()
        }
    end
    
    DebugPrint('Weather system initialized')
    
    -- Main weather update loop
    while true do
        UpdateWeatherCycle()
        Wait(Config.UpdateInterval)
    end
end)

-- Player management
CreateThread(function()
    while true do
        for playerId, _ in pairs(RSGCore.Functions.GetPlayers()) do
            UpdatePlayerWeatherEffects(tonumber(playerId))
        end
        Wait(Config.Performance.playerUpdateInterval)
    end
end)

-- Cleanup disconnected players
AddEventHandler('playerDropped', function()
    local src = source
    if playerWeatherData[src] then
        playerWeatherData[src] = nil
    end
end)