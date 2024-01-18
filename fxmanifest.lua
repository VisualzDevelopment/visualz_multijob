fx_version "cerulean"
game "gta5"
lua54 "yes"

shared_scripts {
  "@ox_lib/init.lua",
  "@es_extended/imports.lua",

  "shared/*.lua"
}

server_scripts {
  "@oxmysql/lib/MySQL.lua",

  "server/*.lua"
}

client_scripts {
  "client/*.lua"
}
