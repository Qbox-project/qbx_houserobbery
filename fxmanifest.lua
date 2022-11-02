fx_version 'cerulean'
game 'gta5'

description 'QB-HouseRobbery'
version '1.0.0'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua'
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'qb-lockpick',
    'qb-skillbar'
}

lua54 'yes'
