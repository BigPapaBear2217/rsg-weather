Config = {}

-- ==========================================
--               GENERAL SETTINGS
-- ==========================================
Config.Debug = false -- Enable debug mode for development
Config.UseMetric = true -- Use metric system for temperatures (Celsius)
Config.UpdateInterval = 60000 -- Weather update interval in milliseconds (1 minute)
Config.SyncInterval = 300000 -- Weather sync interval in milliseconds (5 minutes)

-- ==========================================
--              WEATHER SYSTEM
-- ==========================================

-- Weather Types (RedM Compatible)
Config.WeatherTypes = {
    ['SUNNY'] = { 
        hash = `SUNNY`, 
        name = 'Sunny', 
        temp = {min = 20, max = 35},
        humidity = {min = 20, max = 40},
        windSpeed = {min = 0.1, max = 0.3}
    },
    ['CLOUDS'] = { 
        hash = `CLOUDS`, 
        name = 'Cloudy', 
        temp = {min = 15, max = 25},
        humidity = {min = 40, max = 60},
        windSpeed = {min = 0.2, max = 0.5}
    },
    ['OVERCAST'] = { 
        hash = `OVERCAST`, 
        name = 'Overcast', 
        temp = {min = 10, max = 20},
        humidity = {min = 60, max = 80},
        windSpeed = {min = 0.3, max = 0.6}
    },
    ['RAIN'] = { 
        hash = `RAIN`, 
        name = 'Rainy', 
        temp = {min = 8, max = 18},
        humidity = {min = 80, max = 95},
        windSpeed = {min = 0.4, max = 0.8}
    },
    ['DRIZZLE'] = { 
        hash = `DRIZZLE`, 
        name = 'Light Rain', 
        temp = {min = 12, max = 22},
        humidity = {min = 70, max = 85},
        windSpeed = {min = 0.2, max = 0.4}
    },
    ['THUNDER'] = { 
        hash = `THUNDER`, 
        name = 'Thunderstorm', 
        temp = {min = 5, max = 15},
        humidity = {min = 85, max = 100},
        windSpeed = {min = 0.6, max = 1.0}
    },
    ['FOG'] = { 
        hash = `FOG`, 
        name = 'Foggy', 
        temp = {min = 5, max = 15},
        humidity = {min = 90, max = 100},
        windSpeed = {min = 0.0, max = 0.2}
    },
    ['SNOW'] = { 
        hash = `SNOW`, 
        name = 'Snowy', 
        temp = {min = -10, max = 5},
        humidity = {min = 80, max = 95},
        windSpeed = {min = 0.3, max = 0.7}
    },
    ['BLIZZARD'] = { 
        hash = `BLIZZARD`, 
        name = 'Blizzard', 
        temp = {min = -20, max = -5},
        humidity = {min = 85, max = 100},
        windSpeed = {min = 0.8, max = 1.0}
    },
    ['SANDSTORM'] = { 
        hash = `SANDSTORM`, 
        name = 'Sandstorm', 
        temp = {min = 25, max = 45},
        humidity = {min = 10, max = 30},
        windSpeed = {min = 0.7, max = 1.0}
    }
}

-- Weather Transition Settings
Config.WeatherTransition = {
    enabled = true,
    transitionTime = 30.0, -- Time in seconds for weather transitions
    smoothTransitions = true,
    allowInstantChange = false, -- Admin override
}

-- ==========================================
--           REGIONAL WEATHER ZONES
-- ==========================================
Config.WeatherZones = {
    ['valentine'] = {
        name = 'Valentine',
        center = vector3(-298.0, 791.0, 118.0),
        radius = 500.0,
        climate = 'temperate',
        weatherProbabilities = {
            ['SUNNY'] = 30,
            ['CLOUDS'] = 25,
            ['OVERCAST'] = 20,
            ['RAIN'] = 15,
            ['DRIZZLE'] = 10
        },
        tempModifier = 0.0 -- Temperature adjustment for this zone
    },
    ['strawberry'] = {
        name = 'Strawberry',
        center = vector3(-1759.0, -388.0, 157.0),
        radius = 400.0,
        climate = 'mountain',
        weatherProbabilities = {
            ['SUNNY'] = 20,
            ['CLOUDS'] = 25,
            ['OVERCAST'] = 25,
            ['RAIN'] = 15,
            ['SNOW'] = 10,
            ['FOG'] = 5
        },
        tempModifier = -5.0 -- Colder in mountains
    },
    ['saint_denis'] = {
        name = 'Saint Denis',
        center = vector3(2635.0, -1225.0, 53.0),
        radius = 600.0,
        climate = 'swamp',
        weatherProbabilities = {
            ['SUNNY'] = 15,
            ['CLOUDS'] = 20,
            ['OVERCAST'] = 25,
            ['RAIN'] = 20,
            ['DRIZZLE'] = 15,
            ['FOG'] = 5
        },
        tempModifier = 2.0 -- Warmer and humid
    },
    ['armadillo'] = {
        name = 'Armadillo',
        center = vector3(-3685.0, -2623.0, -14.0),
        radius = 450.0,
        climate = 'desert',
        weatherProbabilities = {
            ['SUNNY'] = 50,
            ['CLOUDS'] = 20,
            ['OVERCAST'] = 15,
            ['SANDSTORM'] = 10,
            ['RAIN'] = 5
        },
        tempModifier = 8.0 -- Much hotter in desert
    }
}

-- ==========================================
--           SEASONAL VARIATIONS
-- ==========================================
Config.Seasons = {
    enabled = true,
    -- Season lengths in real-world days
    seasonLength = 7, -- Each season lasts 7 days
    
    ['spring'] = {
        tempModifier = 0.0,
        weatherBias = {
            ['RAIN'] = 1.5, -- 50% more likely
            ['DRIZZLE'] = 1.3,
            ['SUNNY'] = 1.2
        }
    },
    ['summer'] = {
        tempModifier = 5.0,
        weatherBias = {
            ['SUNNY'] = 2.0, -- Double the chance
            ['CLOUDS'] = 1.2,
            ['RAIN'] = 0.7 -- 30% less likely
        }
    },
    ['autumn'] = {
        tempModifier = -2.0,
        weatherBias = {
            ['OVERCAST'] = 1.4,
            ['FOG'] = 1.6,
            ['RAIN'] = 1.2
        }
    },
    ['winter'] = {
        tempModifier = -8.0,
        weatherBias = {
            ['SNOW'] = 2.5,
            ['BLIZZARD'] = 1.8,
            ['FOG'] = 1.4,
            ['SUNNY'] = 0.5
        }
    }
}

-- ==========================================
--           PLAYER INTERACTIONS
-- ==========================================

-- Temperature Effects on Player Needs
Config.PlayerEffects = {
    enabled = true,
    temperatureEffects = {
        -- Effects when too cold (below 10°C)
        tooHot = {
            threshold = 30, -- Temperature threshold
            effects = {
                thirstRate = 1.5, -- 50% faster thirst drain
                healthRegen = 0.8, -- 20% slower health regen
                staminaRegen = 0.9, -- 10% slower stamina regen
                moveSpeed = 0.95 -- 5% slower movement
            }
        },
        tooCold = {
            threshold = 5, -- Temperature threshold  
            effects = {
                hungerRate = 1.3, -- 30% faster hunger drain
                healthRegen = 0.7, -- 30% slower health regen
                staminaRegen = 0.8, -- 20% slower stamina regen
                moveSpeed = 0.9 -- 10% slower movement
            }
        }
    },
    
    -- Clothing System Integration
    clothingSystem = {
        enabled = true,
        warmthValues = {
            -- Hat warmth values
            hats = {
                [1] = 2, -- Light hat
                [2] = 4, -- Medium hat
                [3] = 6  -- Warm hat
            },
            -- Coat warmth values
            coats = {
                [1] = 5,  -- Light coat
                [2] = 10, -- Medium coat
                [3] = 15  -- Heavy coat
            },
            -- Boot warmth values
            boots = {
                [1] = 2, -- Light boots
                [2] = 4, -- Medium boots
                [3] = 6  -- Heavy boots
            }
        }
    },
    
    -- Shelter Detection
    shelter = {
        enabled = true,
        interiors = true, -- Count interiors as shelter
        underRoof = true, -- Detect if under roof structure
        shelterRadius = 10.0, -- Radius to check for shelter objects
        shelterObjects = {
            'p_tent01x', 'p_campfire09x', 'p_cabin_b_01x'
        }
    }
}

-- Weather-based Buffs and Debuffs
Config.WeatherBuffs = {
    ['RAIN'] = {
        trackingBonus = 1.2, -- 20% better tracking in rain
        fishingBonus = 1.3   -- 30% better fishing
    },
    ['FOG'] = {
        stealthBonus = 1.4,  -- 40% better stealth
        visibilityReduction = 0.6 -- 40% reduced visibility
    },
    ['SUNNY'] = {
        moodBonus = 1.1,     -- 10% mood improvement
        energyRegen = 1.15   -- 15% faster energy regen
    },
    ['THUNDER'] = {
        fearEffect = true,   -- Animals more easily spooked
        fishingPenalty = 0.7 -- 30% fishing penalty
    }
}

-- ==========================================
--             JOB INTEGRATION
-- ==========================================
Config.JobIntegration = {
    enabled = true,
    
    -- Fishing Integration
    fishing = {
        enabled = true,
        weatherMultipliers = {
            ['RAIN'] = 1.3,      -- 30% better in rain
            ['DRIZZLE'] = 1.2,   -- 20% better in light rain
            ['OVERCAST'] = 1.1,  -- 10% better when overcast
            ['THUNDER'] = 0.7,   -- 30% worse during storms
            ['FOG'] = 0.9,       -- 10% worse in fog
            ['SUNNY'] = 1.0      -- Normal in sunny weather
        },
        temperatureEffects = {
            optimal = {min = 15, max = 25}, -- Optimal fishing temperature range
            bonus = 1.2 -- 20% bonus in optimal conditions
        }
    },
    
    -- Hunting Integration
    hunting = {
        enabled = true,
        weatherMultipliers = {
            ['FOG'] = 1.4,       -- 40% better tracking in fog
            ['OVERCAST'] = 1.2,  -- 20% better when overcast
            ['RAIN'] = 0.8,      -- 20% worse in rain
            ['THUNDER'] = 0.6,   -- 40% worse during storms
            ['SNOW'] = 1.3       -- 30% better tracking in snow
        },
        animalBehavior = {
            ['THUNDER'] = {scared = true, spawn_rate = 0.5},
            ['RAIN'] = {seeking_shelter = true, spawn_rate = 0.8},
            ['FOG'] = {easier_approach = true, spawn_rate = 1.2}
        }
    },
    
    -- Farming Integration
    farming = {
        enabled = true,
        weatherMultipliers = {
            ['RAIN'] = 1.5,      -- 50% better growth in rain
            ['DRIZZLE'] = 1.3,   -- 30% better in light rain
            ['SUNNY'] = 1.2,     -- 20% better in sunny weather
            ['DROUGHT'] = 0.5,   -- 50% worse in drought conditions
            ['THUNDER'] = 0.8    -- 20% damage risk from storms
        },
        seasonalEffects = {
            ['spring'] = 1.3,    -- 30% better growth
            ['summer'] = 1.1,    -- 10% better growth
            ['autumn'] = 0.9,    -- 10% slower growth
            ['winter'] = 0.3     -- 70% slower growth
        }
    },
    
    -- Travel and Transportation
    travel = {
        enabled = true,
        weatherMultipliers = {
            ['RAIN'] = 0.9,      -- 10% slower travel
            ['THUNDER'] = 0.8,   -- 20% slower travel
            ['FOG'] = 0.85,      -- 15% slower travel
            ['SNOW'] = 0.8,      -- 20% slower travel
            ['BLIZZARD'] = 0.6   -- 40% slower travel
        },
        horseBehavior = {
            ['THUNDER'] = {spookChance = 0.3, speed = 0.7},
            ['BLIZZARD'] = {stamina_drain = 1.5, speed = 0.6}
        }
    }
}

-- ==========================================
--             VISUAL & AUDIO
-- ==========================================
Config.VisualEffects = {
    enabled = true,
    
    -- HUD Integration
    hud = {
        showTemperature = true,
        showWeatherIcon = true,
        showForecast = true,
        position = 'top-right', -- Position on screen
        updateFrequency = 30000 -- Update every 30 seconds
    },
    
    -- Weather Forecast
    forecast = {
        enabled = true,
        hoursAhead = 6, -- Show forecast 6 hours ahead
        accuracy = 0.8  -- 80% forecast accuracy
    },
    
    -- Atmospheric Effects
    atmosphere = {
        temperatureVisuals = true, -- Show breath in cold weather
        weatherParticles = true,   -- Enhanced weather particles
        lightingEffects = true,    -- Dynamic lighting based on weather
        soundEffects = true        -- Weather-appropriate sounds
    }
}

-- ==========================================
--           PERFORMANCE SETTINGS
-- ==========================================
Config.Performance = {
    -- Update intervals (milliseconds)
    playerUpdateInterval = 5000,  -- Update player effects every 5 seconds
    weatherUpdateInterval = 60000, -- Update weather every minute
    zoneCheckInterval = 10000,    -- Check player zones every 10 seconds
    
    -- Maximum distances
    maxWeatherSyncDistance = 1000.0, -- Max distance for weather sync
    maxEffectDistance = 500.0,       -- Max distance for weather effects
    
    -- Optimization settings
    enableLOD = true,              -- Level of detail optimization
    maxConcurrentEffects = 10,     -- Max concurrent weather effects
    useAsyncUpdates = true,        -- Use async updates where possible
    
    -- Debug and monitoring
    enablePerfMonitoring = true,   -- Enable performance monitoring
    logPerformanceStats = false,   -- Log performance statistics
    maxCPUUsage = 2.0             -- Target max CPU usage percentage
}

-- ==========================================
--           DATABASE SETTINGS
-- ==========================================
Config.Database = {
    enabled = true,
    saveInterval = 300000,        -- Save weather data every 5 minutes
    historyDuration = 7 * 24 * 60, -- Keep 7 days of weather history (minutes)
    
    -- Tables
    tables = {
        weather_cycles = 'rsg_weather_cycles',
        weather_zones = 'rsg_weather_zones', 
        weather_history = 'rsg_weather_history',
        player_weather_settings = 'rsg_player_weather_settings'
    }
}

-- ==========================================
--                LOCALES
-- ==========================================
Config.Locale = GetConvar('rsg_locale', 'en')

-- ==========================================
--            ADMIN COMMANDS
-- ==========================================
Config.AdminCommands = {
    enabled = true,
    requiredGrade = 'admin', -- Required RSG-Core job grade
    commands = {
        setWeather = 'setweather',      -- /setweather sunny
        setTemp = 'settemp',            -- /settemp 25
        toggleWeather = 'toggleweather', -- /toggleweather
        weatherInfo = 'weatherinfo'     -- /weatherinfo
    }
}

-- ==========================================
--           INTEGRATION HOOKS
-- ==========================================
Config.Integrations = {
    -- RSG-Core Integration
    rsgcore = {
        enabled = true,
        usePlayerData = true,
        savePlayerSettings = true
    },
    
    -- Other resource integrations
    resources = {
        ['rsg-fishing'] = {enabled = true, events = {'rsg-fishing:client:StartFishing'}},
        ['rsg-hunting'] = {enabled = true, events = {'rsg-hunting:client:StartHunting'}},
        ['rsg-farming'] = {enabled = true, events = {'rsg-farming:client:StartFarming'}},
        ['rsg-menu'] = {enabled = true, menuIntegration = true}
    }
}