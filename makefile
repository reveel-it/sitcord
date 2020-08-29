.PHONY: all clean uninstall
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))

DISCORD_PATH := /Applications/Discord.app/Contents/MacOS/Discord
ifdef PTB
	DISCORD_PATH := /Applications/Discord\\ PTB.app/Contents/MacOS/Discord\\ PTB
endif

ifdef CHANNEL_NAME
	DISCORD_CHANNEL_NAME := DISCORD_CHANNEL_NAME="$(CHANNEL_NAME)" 
endif

all: Sitcord.app/Contents/document.wflow bin/sitcord

Sitcord.app/Contents/document.wflow: Sitcord.app/Contents/document.template.wflow
	(if [ -e $(shell echo "$(DISCORD_PATH)" | sed 's|\\|\\|g') ]; then \
		sed 's|echo|$(DISCORD_PATH) --remote-debugging-port=54321 \&gt; $(current_dir)bin/discord.log 2\&gt; $(current_dir)bin/discord.err \&amp;\|DISCORD_SERVER_NAME="$(SERVER)" DISCORD_DEBUG_PORT=54321 $(DISCORD_CHANNEL_NAME)PATH=$(PATH) $(current_dir)bin/sitcord $$(pgrep -o Discord) \&gt; $(current_dir)bin/sitcord.log 2\&gt; $(current_dir)bin/sitcord.err \&amp;\||g' Sitcord.app/Contents/document.template.wflow | tr '|' '\n' > Sitcord.app/Contents/document.wflow; \
	fi)

bin/sitcord: sitcord/main.swift bin/automateDiscord.js node_modules Package.swift
	swift build -c release
	cp .build/x86_64-apple-macosx/release/sitcord ./bin/sitcord

node_modules: package-lock.json
	npm i
	touch node_modules

~/Applications/Sitcord.app: Sitcord.app/Contents/document.wflow
	cp -r Sitcord.app ~/Applications/Sitcord.app

install: ~/Applications/Sitcord.app

clean:
	rm -f Sitcord.app/Contents/document.wflow

uninstall:
	rm -rf ~/Applications/Sitcord.app
