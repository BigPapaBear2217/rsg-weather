# RSG Weather System

A comprehensive Dynamic Weather & Atmosphere System for RedM/RSG-Core servers that enhances roleplay immersion through realistic environmental effects, player interactions, and job integration.

## 🌟 Features

### 🌤️ Dynamic Weather System
- **10 Weather Types**: Sunny, Cloudy, Overcast, Rain, Drizzle, Thunderstorm, Fog, Snow, Blizzard, Sandstorm
- **Realistic Transitions**: Smooth weather changes with configurable transition times
- **Seasonal Variations**: 4 seasons with different weather probabilities and temperature modifiers
- **Regional Weather**: Different weather patterns for major towns (Valentine, Strawberry, Saint Denis, Armadillo)

### 🌡️ Temperature Simulation
- **Dynamic Temperature**: Weather-based temperature calculation with regional and seasonal modifiers
- **Clothing System**: Clothing provides warmth bonuses affecting comfort
- **Shelter Detection**: Interior and roof detection for weather protection
- **Player Effects**: Temperature affects hunger/thirst rates, health regeneration, and movement speed

### 👤 Player Interactions
- **Visual Effects**: Breath visibility in cold weather, atmospheric particles
- **Weather Buffs/Debuffs**: Weather-specific bonuses and penalties
- **Customizable Settings**: Per-player temperature unit, notifications, and effect preferences
- **HUD Integration**: Compact weather display with temperature and effect indicators

### 🎣 Job Integration
- **Fishing**: Weather affects success rates (rain = +30%, thunderstorms = -30%)
- **Hunting**: Animal behavior changes, tracking bonuses in fog and snow
- **Farming**: Crop growth rates affected by weather and seasons
- **Travel**: Weather impacts movement speed and horse behavior

### 🎨 Visual & Audio
- **NUI Interface**: Beautiful, responsive weather display with forecast
- **Weather Particles**: Animated rain and snow effects
- **Temperature Colors**: Dynamic color coding for temperature display
- **Notifications**: Contextual weather alerts and status updates

### 🔧 Technical Features
- **Performance Optimized**: <2% CPU overhead target
- **Database Integration**: Persistent weather patterns and player settings
- **Admin Commands**: Weather control and debugging tools
- **Extensive Configuration**: 400+ configuration options
- **RSG-Core Integration**: Native framework compatibility

## 📋 Requirements

- **RedM Server** with latest artifacts
- **RSG-Core Framework** (latest version)
- **oxmysql** resource
- **MySQL/MariaDB** database
- **Basic Lua knowledge** for configuration

## 🚀 Installation

### 1. Download & Extract
```bash
# Download the resource
git clone https://github.com/your-repo/rsg-weather
# or extract the ZIP file to your resources folder
```

### 2. Database Setup
```sql
-- Import the SQL schema
mysql -u username -p database_name < rsg-weather.sql
```

### 3. Server Configuration
Add to your `server.cfg`:
```bash
ensure rsg-weather
```

### 4. Dependencies
Ensure these resources are started BEFORE rsg-weather:
```bash
ensure rsg-core
ensure oxmysql
```

## ⚙️ Configuration

### Basic Setup (config/config.lua)

```lua
Config.Debug = false -- Enable for development
Config.UseMetric = true -- Temperature in Celsius
Config.UpdateInterval = 60000 -- Weather updates every minute
```

### Weather Types
Configure probability for each weather type per region:
```lua
Config.WeatherZones = {
    ['valentine'] = {
        weatherProbabilities = {
            ['SUNNY'] = 30,
            ['RAIN'] = 15,
            ['CLOUDS'] = 25
        }
    }
}
```

### Player Effects
Customize temperature effects on player needs:
```lua
Config.PlayerEffects = {
    temperatureEffects = {
        tooCold = {
            threshold = 5,
            effects = {
                hungerRate = 1.3,
                moveSpeed = 0.9
            }
        }
    }
}
```

### Job Integration
Configure weather impact on jobs:
```lua
Config.JobIntegration = {
    fishing = {
        weatherMultipliers = {
            ['RAIN'] = 1.3,    -- 30% better in rain
            ['THUNDER'] = 0.7   -- 30% worse in storms
        }
    }
}
```

## 🎮 Usage

### Player Commands
- `/weather` - Open weather interface
- **Admin Commands** (require admin permissions):
  - `/setweather <type>` - Set weather type
  - `/settemp <temperature>` - Set temperature
  - `/weatherinfo` - Display current weather info

### Exports (Client)
```lua
-- Get current weather
local weather = exports['rsg-weather']:GetCurrentWeather()

-- Get temperature
local temp = exports['rsg-weather']:GetCurrentTemperature()

-- Check if player is in shelter
local inShelter = exports['rsg-weather']:IsPlayerInShelter()

-- Toggle weather effects for player
exports['rsg-weather']:SetPlayerWeatherEffects(true)
```

### Exports (Server)
```lua
-- Set weather for zone or globally
exports['rsg-weather']:SetWeatherType('RAIN', 'valentine')

-- Get current global weather
local weather = exports['rsg-weather']:GetCurrentWeather()

-- Get weather in specific region
local zoneWeather = exports['rsg-weather']:GetWeatherInRegion('valentine')

-- Get weather history
local history = exports['rsg-weather']:GetWeatherHistory(24) -- 24 hours
```

### Events

**Client Events:**
```lua
-- Weather updated
RegisterNetEvent('rsg-weather:client:weatherUpdate')

-- Player effects updated
RegisterNetEvent('rsg-weather:client:updatePlayerEffects')

-- Forecast received
RegisterNetEvent('rsg-weather:client:forecastUpdate')
```

**Server Events:**
```lua
-- Request weather update
TriggerServerEvent('rsg-weather:server:requestWeatherUpdate')

-- Get job weather bonus
TriggerServerEvent('rsg-weather:server:getJobWeatherBonus', 'fishing')
```

## 🔗 Integration Examples

### Fishing Script Integration
```lua
-- In your fishing script
RegisterNetEvent('rsg-weather:client:jobWeatherBonus', function(bonus)
    if bonus.jobType == 'fishing' then
        local successRate = baseSuccessRate * bonus.multiplier
        -- Apply the weather bonus to fishing success rate
    end
end)

-- Request weather bonus before fishing
TriggerServerEvent('rsg-weather:server:getJobWeatherBonus', 'fishing')
```

### HUD Integration
```lua
-- Listen for weather updates in your HUD
RegisterNetEvent('rsg-weather:client:weatherUpdate', function(data)
    -- Update your HUD with weather data
    UpdateHUDWeather(data.weather, data.temperature)
end)
```

## 🎯 Weather Types & Effects

| Weather Type | Temperature Range | Effects | Jobs Impact |
|-------------|------------------|---------|-------------|
| **Sunny** | 20-35°C | Mood boost, faster energy regen | Normal rates |
| **Cloudy** | 15-25°C | Neutral effects | Slight fishing boost |
| **Rain** | 8-18°C | Better tracking, fishing bonus | +30% fishing, -20% hunting |
| **Thunderstorm** | 5-15°C | Animals spooked, visibility reduced | -30% fishing, -40% hunting |
| **Snow** | -10-5°C | Better tracking, slower movement | +30% hunting, farming penalty |
| **Fog** | 5-15°C | Stealth bonus, reduced visibility | +40% stealth, -10% fishing |

## 🌡️ Temperature Effects

| Temperature | Status | Player Effects |
|------------|--------|----------------|
| < 0°C | Freezing | 30% faster hunger drain, 20% slower regen |
| 0-10°C | Cold | Need warm clothing, seek shelter |
| 10-20°C | Cool | Comfortable with light clothing |
| 20-30°C | Warm | Optimal temperature range |
| 30-40°C | Hot | 50% faster thirst drain, seek shade |
| > 40°C | Very Hot | Rapid thirst drain, health penalties |

## 🗄️ Database Schema

The system creates several tables:

- **rsg_weather_cycles** - Active weather patterns
- **rsg_weather_zones** - Regional weather data
- **rsg_weather_history** - Historical weather records
- **rsg_player_weather_settings** - Player preferences
- **rsg_weather_events** - Special weather events
- **rsg_weather_statistics** - Analytics data

## 📊 Performance

- **CPU Usage**: <2% target (typically 0.5-1.5%)
- **Memory Usage**: ~50-100MB
- **Network**: Minimal sync data
- **Database**: Automatic cleanup of old records

### Performance Optimization
```lua
Config.Performance = {
    playerUpdateInterval = 5000,  -- Player effects every 5s
    zoneCheckInterval = 10000,    -- Zone checks every 10s
    maxConcurrentEffects = 10,    -- Limit particle effects
    enableLOD = true,             -- Distance-based optimization
}
```

## 🐛 Troubleshooting

### Common Issues

1. **Weather not changing**
   - Check `Config.UpdateInterval` setting
   - Verify database connection
   - Enable debug mode: `Config.Debug = true`

2. **Player effects not working**
   - Ensure RSG-Core player data is loaded
   - Check `Config.PlayerEffects.enabled = true`
   - Verify exports are working

3. **NUI not displaying**
   - Check browser console for JavaScript errors
   - Verify CDN library loading
   - Ensure resource files are properly configured

4. **Database errors**
   - Import the SQL schema completely
   - Check MySQL connection in oxmysql
   - Verify table permissions

### Debug Commands
```lua
-- Enable debug mode
Config.Debug = true

-- Check weather system status
/weatherinfo

-- View current exports
print(exports['rsg-weather']:GetCurrentWeather())
```

## 🤝 Support & Contributing

### Getting Help
1. Check this documentation thoroughly
2. Enable debug mode for detailed logging
3. Check server console for error messages
4. Verify all dependencies are correctly installed

### Contributing
1. Fork the repository
2. Create a feature branch
3. Follow the existing code style
4. Test thoroughly before submitting
5. Create detailed pull request

## 📄 License

This project is licensed under the MIT License. See LICENSE file for details.

## 🙏 Credits

- **RSG-Core Team** - Framework foundation
- **RedM Community** - Native function discoveries
- **Weather Data** - Based on real-world climate patterns
- **UI Design** - Inspired by modern weather applications

---

## 📝 Changelog

### v1.0.0 (Initial Release)
- Complete weather system implementation
- 10 weather types with realistic effects
- Regional weather variations
- Player interaction system
- Job integration framework
- Database persistence
- NUI interface
- Admin controls
- Performance optimization
- Full RSG-Core integration

---

**Enjoy realistic weather in your RedM server! 🌦️**

For questions, support, or updates, contact the development team or check the repository for the latest information.