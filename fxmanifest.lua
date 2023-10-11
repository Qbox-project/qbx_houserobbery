fx_version 'cerulean'
game 'gta5'

description 'QBX-Houserobbery'
repository 'https://github.com/Qbox-project/qbx_houserobbery'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/shared/locale.lua',
    '@qbx_core/import.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua'
}

modules {'qbx_core:utils'}

client_script 'client.lua'
server_script 'server.lua'

lua54 'yes'
