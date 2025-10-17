fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

name 'RSG Weather System'
description 'Dynamic Weather & Atmosphere System for RedM/RSG-Core'
version '1.0.0'
author 'Kong Development Team'

dependencies {
    'rsg-core',
    'oxmysql',
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'locales/en.lua',
    'config/config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*.png',
    'html/assets/*.svg'
}

exports {
    'GetCurrentWeather',
    'GetCurrentTemperature',
    'GetWeatherInRegion',
    'SetPlayerWeatherEffects',
    'GetWeatherForecast'
}

server_exports {
    'SetWeatherType',
    'GetGlobalWeather',
    'UpdateWeatherCycle',
    'SetRegionalWeather',
    'GetWeatherHistory'
}