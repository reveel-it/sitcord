bin/sitcord: sitcord/main.swift bin/automateDiscord.js node_modules Package.swift
	swift build
	cp .build/x86_64-apple-macosx/debug/sitcord ./bin/sitcord

node_modules: package-lock.json
	npm i