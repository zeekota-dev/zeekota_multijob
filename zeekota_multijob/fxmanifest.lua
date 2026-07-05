fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'zeekota_multijob'
author 'ZeeKota'
description 'ZeeKota Multi Job - secure multi-job storage, duty management, and administrator tooling'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/api.js',
    'web/js/player.js',
    'web/js/admin.js',
    'web/js/app.js',
    'web/assets/*.png',
    'web/assets/*.svg',
    'web/assets/icons/*.svg'
}

shared_scripts {
    'shared/constants.lua',
    'config.lua',
    'shared/utils.lua',
    'locales/*.lua',
    'shared/locale.lua',
    'shared/init.lua'
}

client_scripts {
    'bridge/client/esx.lua',
    'bridge/client/qb.lua',
    'bridge/client/ox.lua',
    'client/state.lua',
    'client/restrictions.lua',
    'client/nui.lua',
    'client/admin.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/esx.lua',
    'bridge/server/qb.lua',
    'bridge/server/ox.lua',
    'server/database.lua',
    'server/logging.lua',
    'server/rate_limits.lua',
    'server/security.lua',
    'server/cache.lua',
    'server/limits.lua',
    'server/history.lua',
    'server/duty.lua',
    'server/jobs.lua',
    'server/sync.lua',
    'server/admin/sessions.lua',
    'server/admin/players.lua',
    'server/admin/offline.lua',
    'server/admin/actions.lua',
    'server/admin/dashboard.lua',
    'server/callbacks.lua',
    'server/commands.lua',
    'server/main.lua'
}

dependencies {
    'oxmysql'
}

escrow_ignore {
    'config.lua',
    'locales/*.lua',
    'bridge/**/*.lua',
    'docs/*.md',
    'sql/*.sql'
}

provides {
    'zeekota_multijob'
}
