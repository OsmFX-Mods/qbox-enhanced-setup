fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'osm_statebag_bridge'
author 'OsmFX'
version '1.0.0'
description 'Workaround for FiveM for GTAV Enhanced: player state bags never replicate server -> client (citizenfx/rfc#77)'

shared_script 'config.lua'
server_script 'server.lua'
client_script 'client.lua'
