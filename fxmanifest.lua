fx_version 'adamant'

game 'gta5'

------------------------------------------------------------
---------------------- yrp_winemaker -----------------------
------------------------------------------------------------
--------------------- Created by Flap ----------------------
------------------------------------------------------------
----------------- YourRolePlay Development -----------------
--------- Thank you for using this winemaker job -----------
----- Regular updates and lots of interesting scripts ------
--------- discord -> https://discord.gg/hqZEXc8FSE ---------
------------------------------------------------------------

description 'yrp_winemaker from esx_vigneronjob'
author 'YourRolePlay Development'

version '1.1.0'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/czech.lua',
	'locales/english.lua',
	'config/sv_config.lua',
	'server/main.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/czech.lua',
	'locales/english.lua',
	'config/cl_config.lua',
	'client/main.lua'
}

ui_page "html/ui.html"

files {
	"html/ui.html",
	"html/js/index.js",
	"html/css/style.css"
}

dependencies {
	'es_extended',
	'esx_billing',
	'esx_vehicleshop',
	'mythic_progbar'
}
