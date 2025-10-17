Locale = Locale or {}

Locale['en'] = {
    -- Weather Types
    ['weather_sunny'] = 'Sunny',
    ['weather_cloudy'] = 'Cloudy',
    ['weather_overcast'] = 'Overcast',
    ['weather_rainy'] = 'Rainy',
    ['weather_drizzle'] = 'Light Rain',
    ['weather_thunder'] = 'Thunderstorm',
    ['weather_foggy'] = 'Foggy',
    ['weather_snowy'] = 'Snowy',
    ['weather_blizzard'] = 'Blizzard',
    ['weather_sandstorm'] = 'Sandstorm',

    -- Temperature
    ['temp_cold'] = 'Cold',
    ['temp_cool'] = 'Cool',
    ['temp_mild'] = 'Mild',
    ['temp_warm'] = 'Warm',
    ['temp_hot'] = 'Hot',
    ['temp_very_hot'] = 'Very Hot',
    ['temp_freezing'] = 'Freezing',

    -- Status Messages
    ['feeling_cold'] = 'You feel cold. Find shelter or warmer clothes.',
    ['feeling_hot'] = 'You feel overheated. Seek shade and water.',
    ['seeking_shelter'] = 'You should seek shelter from the weather.',
    ['comfortable_temp'] = 'The temperature feels comfortable.',

    -- Weather Effects
    ['weather_changing'] = 'The weather is changing...',
    ['storm_approaching'] = 'A storm is approaching!',
    ['weather_clearing'] = 'The weather is clearing up.',
    
    -- Forecast
    ['forecast_title'] = 'Weather Forecast',
    ['forecast_next_hour'] = 'Next Hour',
    ['forecast_next_3_hours'] = 'Next 3 Hours',
    ['forecast_next_6_hours'] = 'Next 6 Hours',
    
    -- Admin Commands
    ['weather_set'] = 'Weather set to %s',
    ['temp_set'] = 'Temperature set to %s°%s',
    ['weather_system_enabled'] = 'Weather system enabled',
    ['weather_system_disabled'] = 'Weather system disabled',
    ['weather_info'] = 'Current: %s | Temp: %s°%s | Zone: %s',
    ['invalid_weather'] = 'Invalid weather type. Available: %s',
    ['no_permission'] = 'You don\'t have permission to use this command.',
    
    -- Notifications
    ['weather_sync'] = 'Weather synchronized',
    ['entering_zone'] = 'Entering %s',
    ['weather_effect_active'] = 'Weather effect: %s',
    
    -- Job Integration
    ['fishing_weather_bonus'] = 'Good weather for fishing! (+%s%%)',
    ['fishing_weather_penalty'] = 'Poor weather for fishing. (-%s%%)',
    ['hunting_weather_bonus'] = 'Perfect hunting conditions! (+%s%%)',
    ['hunting_weather_penalty'] = 'Difficult hunting conditions. (-%s%%)',
    ['farming_weather_bonus'] = 'Great weather for crops! (+%s%%)',
    ['farming_weather_penalty'] = 'Poor growing conditions. (-%s%%)',
    
    -- UI Elements
    ['current_weather'] = 'Current Weather',
    ['temperature'] = 'Temperature',
    ['humidity'] = 'Humidity',
    ['wind_speed'] = 'Wind Speed',
    ['forecast'] = 'Forecast',
    ['weather_map'] = 'Weather Map',
    ['settings'] = 'Weather Settings',
    
    -- Player Preferences
    ['weather_notifications'] = 'Weather Notifications',
    ['temperature_unit'] = 'Temperature Unit',
    ['celsius'] = 'Celsius',
    ['fahrenheit'] = 'Fahrenheit',
    ['weather_effects'] = 'Weather Effects',
    ['enabled'] = 'Enabled',
    ['disabled'] = 'Disabled',
    
    -- Error Messages
    ['weather_error'] = 'Weather system error occurred',
    ['database_error'] = 'Database connection error',
    ['sync_error'] = 'Weather synchronization failed',
    ['config_error'] = 'Configuration error detected',
}