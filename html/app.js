/**
 * RSG Weather System NUI Application
 * Uses jQuery from CDN (no build system required)
 */

$(document).ready(function() {
    // ==========================================
    //              GLOBAL VARIABLES
    // ==========================================
    
    let currentWeatherData = {
        weather: 'SUNNY',
        weatherName: 'Sunny',
        temperature: 22,
        temperatureUnit: '°C',
        zone: 'Wilderness',
        inShelter: false,
        clothingWarmth: 0,
        humidity: 45,
        windSpeed: 12,
        forecast: []
    };
    
    let settings = {
        notifications: true,
        temperatureUnit: 'celsius',
        effects: true
    };
    
    let weatherParticles = [];
    
    // Global UI state tracker
    let isUiVisible = false;
    let particleInterval = null;
    const resourceName = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'rsg-weather';
    
    // Weather icon mappings
    const weatherIcons = {
        'SUNNY': 'fas fa-sun sunny',
        'CLOUDS': 'fas fa-cloud cloudy',
        'OVERCAST': 'fas fa-cloud cloudy',
        'RAIN': 'fas fa-cloud-rain rainy',
        'DRIZZLE': 'fas fa-cloud-rain rainy',
        'THUNDER': 'fas fa-bolt stormy',
        'FOG': 'fas fa-smog foggy',
        'SNOW': 'fas fa-snowflake snowy',
        'BLIZZARD': 'fas fa-wind snowy',
        'SANDSTORM': 'fas fa-wind stormy'
    };
    
    // Temperature color mappings
    const temperatureColors = {
        getColor: function(temp) {
            if (temp <= -10) return '#00BFFF';      // Freezing blue
            else if (temp <= 0) return '#87CEEB';   // Cold light blue
            else if (temp <= 10) return '#98FB98';  // Cool green
            else if (temp <= 20) return '#FFD700';  // Mild gold
            else if (temp <= 30) return '#FFA500';  // Warm orange
            else if (temp <= 40) return '#FF6347';  // Hot red
            else return '#DC143C';                  // Very hot crimson
        }
    };
    
    // ==========================================
    //              UTILITY FUNCTIONS
    // ==========================================
    
    function debugLog(message) {
        console.log(`[RSG-Weather-NUI] ${message}`);
    }
    
    function postNUI(action, data = {}) {
        return $.post(`https://${resourceName}/${action}`, JSON.stringify(data));
    }
    
    function showNotification(message, type = 'info', duration = 3000) {
        const notification = $(`
            <div class="notification ${type}">
                <i class="fas ${type === 'success' ? 'fa-check-circle' : 
                               type === 'error' ? 'fa-times-circle' : 
                               type === 'warning' ? 'fa-exclamation-triangle' : 
                               'fa-info-circle'}"></i>
                ${message}
            </div>
        `);
        
        $('#notification-container').append(notification);
        
        setTimeout(() => {
            notification.fadeOut(300, function() {
                $(this).remove();
            });
        }, duration);
    }
    
    function convertTemperature(celsius, unit) {
        if (unit === 'fahrenheit') {
            return {
                value: Math.round((celsius * 9/5) + 32),
                unit: '°F'
            };
        }
        return {
            value: Math.round(celsius),
            unit: '°C'
        };
    }
    
    function getWeatherIcon(weatherType) {
        return weatherIcons[weatherType] || 'fas fa-sun sunny';
    }
    
    function formatTime(hour) {
        const now = new Date();
        const targetTime = new Date(now.getTime() + (hour * 60 * 60 * 1000));
        return targetTime.getHours().toString().padStart(2, '0') + ':00';
    }
    
    // ==========================================
    //              WEATHER PARTICLES
    // ==========================================
    
    function createWeatherParticles(weatherType) {
        const container = $('#weather-particles');
        container.empty();
        
        if (particleInterval) {
            clearInterval(particleInterval);
        }
        
        if (weatherType === 'RAIN' || weatherType === 'DRIZZLE' || weatherType === 'THUNDER') {
            createRainParticles();
        } else if (weatherType === 'SNOW' || weatherType === 'BLIZZARD') {
            createSnowParticles();
        }
    }
    
    function createRainParticles() {
        const container = $('#weather-particles');
        
        particleInterval = setInterval(() => {
            if ($('.rain-particle').length > 100) return; // Limit particles
            
            for (let i = 0; i < 5; i++) {
                const particle = $('<div class="rain-particle"></div>');
                particle.css({
                    left: Math.random() * 100 + '%',
                    animationDelay: Math.random() * 1 + 's'
                });
                container.append(particle);
                
                setTimeout(() => {
                    particle.remove();
                }, 1000);
            }
        }, 200);
    }
    
    function createSnowParticles() {
        const container = $('#weather-particles');
        
        particleInterval = setInterval(() => {
            if ($('.snow-particle').length > 50) return; // Limit particles
            
            for (let i = 0; i < 3; i++) {
                const particle = $('<div class="snow-particle"></div>');
                particle.css({
                    left: Math.random() * 100 + '%',
                    animationDelay: Math.random() * 2 + 's'
                });
                container.append(particle);
                
                setTimeout(() => {
                    particle.remove();
                }, 3000);
            }
        }, 500);
    }
    
    // ==========================================
    //              UI UPDATE FUNCTIONS
    // ==========================================
    
    function updateWeatherDisplay(data) {
        if (!data) return;
        
        // Update main weather icon
        const iconClass = getWeatherIcon(data.weather);
        $('#weather-icon').removeClass().addClass('weather-icon ' + iconClass.split(' ').slice(-1)[0]);
        $('#weather-icon').attr('class', iconClass + ' weather-icon');
        
        // Update temperature with color
        const temp = convertTemperature(data.temperature, settings.temperatureUnit);
        $('#temperature').text(temp.value).css('color', temperatureColors.getColor(data.temperature));
        $('#temp-unit').text(temp.unit);
        
        // Update weather name and zone
        $('#weather-name').text(data.weatherName || data.weather);
        $('#zone-name').text(data.zone || 'Wilderness');
        
        // Update details
        $('#humidity').text(data.humidity ? data.humidity + '%' : '45%');
        $('#wind-speed').text(data.windSpeed ? data.windSpeed + ' km/h' : '12 km/h');
        $('#shelter-status').text(data.inShelter ? 'Yes' : 'No');
        $('#clothing-warmth').text(data.clothingWarmth ? '+' + data.clothingWarmth + temp.unit.slice(-1) : '+0' + temp.unit.slice(-1));
        
        // Update HUD
        $('#hud-weather-icon').removeClass().addClass(iconClass);
        $('#hud-temperature').text(`${temp.value}${temp.unit}`);
        
        // Update HUD effects
        updateHudEffects(data);
        
        // Update particles
        createWeatherParticles(data.weather);
        
        // Store current data
        currentWeatherData = data;
    }
    
    function updateHudEffects(data) {
        const effectsContainer = $('#hud-effects');
        effectsContainer.empty();
        
        // Temperature effects
        const temp = data.temperature + (data.clothingWarmth || 0);
        if (temp <= 5) {
            effectsContainer.append('<div class="hud-effect cold" title="Cold Effect"></div>');
        } else if (temp >= 30) {
            effectsContainer.append('<div class="hud-effect hot" title="Heat Effect"></div>');
        }
        
        // Shelter effect
        if (data.inShelter) {
            effectsContainer.append('<div class="hud-effect shelter" title="In Shelter"></div>');
        }
    }
    
    function updateForecast(forecast) {
        if (!forecast || !Array.isArray(forecast)) return;
        
        debugLog(`Updating forecast with ${forecast.length} items`);
        
        const container = $('#forecast-container');
        container.empty();
        
        forecast.forEach((item, index) => {
            const temp = convertTemperature(item.temperature, settings.temperatureUnit);
            const iconClass = getWeatherIcon(item.weather);
            
            const forecastItem = $(`
                <div class="forecast-item">
                    <div class="forecast-time">${formatTime(item.hour)}</div>
                    <i class="${iconClass} forecast-icon"></i>
                    <div class="forecast-temp">${temp.value}${temp.unit}</div>
                    <div class="forecast-desc">${item.weather}</div>
                </div>
            `);
            
            container.append(forecastItem);
        });
    }
    
    function updateZoneWeather(zones) {
        if (!zones) return;
        
        Object.keys(zones).forEach(zoneName => {
            const zoneData = zones[zoneName];
            const zoneElement = $(`.zone-item[data-zone="${zoneName}"]`);
            
            if (zoneElement.length > 0) {
                const temp = convertTemperature(zoneData.temperature, settings.temperatureUnit);
                const iconClass = getWeatherIcon(zoneData.weather);
                
                zoneElement.find('.zone-weather-icon').removeClass().addClass(iconClass);
                zoneElement.find('.zone-temp').text(`${temp.value}${temp.unit}`);
            }
        });
    }
    
    // ==========================================
    //              EVENT HANDLERS
    // ==========================================
    
    // Close button
    $('#close-btn').click(function() {
        exitEditMode();
    });
    
    // Settings toggles
    $('#notifications-toggle').change(function() {
        settings.notifications = $(this).is(':checked');
        if (settings.notifications) {
            showNotification('Weather notifications enabled', 'success');
        }
    });
    
    $('#effects-toggle').change(function() {
        settings.effects = $(this).is(':checked');
        if (settings.effects) {
            showNotification('Weather effects enabled', 'success');
        }
    });
    
    $('#temp-unit-select').change(function() {
        settings.temperatureUnit = $(this).val();
        // Re-update display with new unit
        updateWeatherDisplay(currentWeatherData);
        showNotification(`Temperature unit changed to ${settings.temperatureUnit}`, 'success');
    });
    
    // Action buttons
    $('#refresh-btn').click(function() {
        postNUI('requestWeatherUpdate');
        showNotification('Refreshing weather data...', 'info');
        
        // Add loading animation
        const btn = $(this);
        const icon = btn.find('i');
        icon.addClass('fa-spin');
        
        setTimeout(() => {
            icon.removeClass('fa-spin');
        }, 1000);
    });
    
    $('#forecast-btn').click(function() {
        postNUI('requestForecast', { hours: 12 });
        showNotification('Loading extended forecast...', 'info');
    });
    
    $('#save-settings-btn').click(function() {
        postNUI('saveSettings', settings);
        showNotification('Settings saved successfully!', 'success');
    });
    
    // Zone clicks
    $('.zone-item').click(function() {
        const zoneName = $(this).data('zone');
        showNotification(`Selected zone: ${zoneName}`, 'info');
        // Could trigger zone-specific weather request
    });
    
    // ESC key to close
    $(document).keyup(function(e) {
        if (e.keyCode === 27 && isUiVisible) { // ESC
            console.log('[RSG-Weather-NUI] ESC key pressed, calling exitEditMode');
            exitEditMode();
        }
    });
    
    // Click outside to close
    $(document).mouseup(function(e) {
        if (!isUiVisible) return;
        
        var container = $("#weather-app");
        if (!container.is(e.target) && container.has(e.target).length === 0) {
            exitEditMode();
        }
    });
    
    
    // ==========================================
    //              NUI MESSAGE HANDLERS
    // ==========================================
    
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        switch (data.type) {
            case 'toggleVisibility':
                isUiVisible = data.visible;
                if (data.visible) {
                    // Show the app
                    $('#loading-screen').fadeOut(300);
                    $('#weather-app').removeClass('hidden').hide().fadeIn(300);
                    
                    // Request fresh data when opening
                    postNUI('requestWeatherUpdate');
                    postNUI('requestForecast', { hours: 6 });
                    postNUI('requestZoneWeather');
                } else {
                    // Hide the app
                    $('#weather-app').fadeOut(300, function() {
                        $(this).addClass('hidden').hide();
                    });
                }
                break;
                
            case 'updateWeather':
                updateWeatherDisplay(data.data);
                break;
                
            case 'updateForecast':
                updateForecast(data.forecast);
                break;
                
            case 'updateZones':
                updateZoneWeather(data.zones);
                break;
                
            case 'showNotification':
                showNotification(data.message, data.notificationType || 'info', data.duration);
                break;
                
            case 'updateSettings':
                settings = { ...settings, ...data.settings };
                applySettings();
                break;
                
            default:
                debugLog(`Unknown message type: ${data.type}`);
        }
    });
    
    // ==========================================
    //              APP FUNCTIONS
    // ==========================================
    
    function showWeatherApp() {
        $('#loading-screen').fadeOut(300);
        $('#weather-app').removeClass('hidden').hide().fadeIn(300);
        
        // Update UI state tracker
        isUiVisible = true;
        
        // Request fresh data when opening
        postNUI('requestWeatherUpdate');
        postNUI('requestForecast', { hours: 6 });
    }
    
    // Function to exit edit mode properly (like RSG HUD)
    function exitEditMode() {
        console.log('[RSG-Weather-NUI] exitEditMode called');
        isUiVisible = false;
        
        // Hide the UI completely
        $('#weather-app').fadeOut(300, function() {
            $(this).addClass('hidden').hide();
        });
        
        // Notify client to close UI using closeUI callback
        console.log('[RSG-Weather-NUI] Sending closeUI to client');
        
        // Send multiple events to ensure one works
        // First try closeUI (our primary method)
        const resName = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'rsg-weather';
        fetch(`https://${resName}/closeUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ closed: true })
        }).then((resp) => {
            if (resp.ok) {
                console.log('[RSG-Weather-NUI] closeUI sent successfully');
            } else {
                console.warn('[RSG-Weather-NUI] closeUI responded with status', resp.status);
            }
        }).catch((error) => {
            console.warn('[RSG-Weather-NUI] Error sending closeUI:', error);
            
            // If closeUI fails, try uiClosed as backup
            fetch(`https://${resName}/uiClosed`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ closed: true })
            }).catch(err => console.warn('[RSG-Weather-NUI] Backup uiClosed failed:', err));
        });
    }
    
    function applySettings() {
        // Apply notification setting
        $('#notifications-toggle').prop('checked', settings.notifications);
        
        // Apply temperature unit
        $('#temp-unit-select').val(settings.temperatureUnit);
        
        // Apply effects setting
        $('#effects-toggle').prop('checked', settings.effects);
        
        // Re-update display if needed
        if (currentWeatherData) {
            updateWeatherDisplay(currentWeatherData);
        }
    }
    
    // ==========================================
    //              INITIALIZATION
    // ==========================================
    
    function initializeApp() {
        // Hide loading screen after initialization
        setTimeout(() => {
            $('#loading-screen').fadeOut(500);
        }, 1000);
        
        // Apply initial settings
        applySettings();
        
        // Set up periodic updates for HUD
        setInterval(() => {
            if (currentWeatherData && isUiVisible && !$('#weather-app').hasClass('hidden')) {
                // Subtle updates can go here
            }
        }, 30000); // Every 30 seconds
    }
    
    // ==========================================
    //              ANIMATION HELPERS
    // ==========================================
    
    function animateTemperatureChange(oldTemp, newTemp) {
        const tempElement = $('#temperature');
        const duration = 1000;
        const steps = 20;
        const stepValue = (newTemp - oldTemp) / steps;
        let currentStep = 0;
        
        const interval = setInterval(() => {
            currentStep++;
            const currentTemp = oldTemp + (stepValue * currentStep);
            const temp = convertTemperature(currentTemp, settings.temperatureUnit);
            
            tempElement.text(temp.value);
            tempElement.css('color', temperatureColors.getColor(currentTemp));
            
            if (currentStep >= steps) {
                clearInterval(interval);
            }
        }, duration / steps);
    }
    
    function createWeatherTransition(fromWeather, toWeather) {
        // Add transition effects between weather types
        const container = $('#weather-animation');
        container.addClass('weather-transition');
        
        setTimeout(() => {
            container.removeClass('weather-transition');
        }, 2000);
    }
    
    // ==========================================
    //              STARTUP
    // ==========================================
    
    // Initialize the application
    initializeApp();
});

// ==========================================
//              ADDITIONAL FEATURES
// ==========================================

// Weather sound effects (if needed)
function playWeatherSound(weatherType) {
    // Could integrate with RedM audio systems
    // For now, just log the intent
    console.log(`Playing weather sound for: ${weatherType}`);
}

// Performance monitoring
let performanceMetrics = {
    updateCount: 0,
    lastUpdateTime: Date.now()
};

function trackPerformance() {
    performanceMetrics.updateCount++;
    const now = Date.now();
    const timeDiff = now - performanceMetrics.lastUpdateTime;
    
    if (timeDiff > 1000) { // Every second
        console.log(`Weather UI Updates: ${performanceMetrics.updateCount}/s`);
        performanceMetrics.updateCount = 0;
        performanceMetrics.lastUpdateTime = now;
    }
}

// Error handling
window.addEventListener('error', function(e) {
    console.error('[RSG-Weather-NUI Error]', e.error);
    
    // Could send error report to server
    $.post(`https://${resourceName}/reportError`, JSON.stringify({
        message: e.error.message,
        stack: e.error.stack,
        timestamp: Date.now()
    })).catch(() => {
        // Ignore if server is not responding
    });
});

// Cleanup on page unload
window.addEventListener('beforeunload', function() {
    if (window.particleInterval) {
        clearInterval(window.particleInterval);
    }
});