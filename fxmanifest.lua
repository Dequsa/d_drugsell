fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Dequsa'
description 'Player driven shops.'
version '1.0.0'

dependencies {'ox_lib', 'ox_target'}
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'localization/*.lua'
}
client_script 'client/*.lua'
server_script 'server/*.lua'
