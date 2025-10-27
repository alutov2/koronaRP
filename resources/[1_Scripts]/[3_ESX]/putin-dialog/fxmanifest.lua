fx_version 'cerulean'
lua54 'yes'
games { 'gta5' }

ui_page 'ui/index.html'

client_scripts {
    'nuimanager/nuimanager.lua'
}

files {
	'ui/index.html',
	'ui/assets/main.js',
	'ui/assets/style.css',
	'ui/assets/sound_open.mp3',
	'ui/assets/sound_close.mp3',
	'ui/assets/sound_submit.mp3',
}

exports {
	'showDialog',
}