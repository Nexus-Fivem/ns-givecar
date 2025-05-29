fx_version "adamant"
game "gta5"

author 'berxt.ogg & torpak.'
description 'Give Car by Nexus Dev. | discord.gg/nexusdev | https://nexusdev.online - ESX Version'
version '1.0.0'

ui_page "ui/index.html"
files {
    "ui/**/**",
}

shared_scripts {
	'@es_extended/imports.lua',
	'config.lua'
}

client_scripts {
	"cl.lua"
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	"sv.lua"
}

dependencies {
	'es_extended'
}
