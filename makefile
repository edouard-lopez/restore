#!/usr/bin/env make
# DESCRIPTION
# Restore user config
#
# USAGE
# make -f makefile
#
# @author: Édouard Lopez <dev+restore@edouard-lopez.com>

ifneq (,)
This makefile requires GNU Make.
endif

# force use of Bash
SHELL := /bin/bash
user := ed8

settingsDir:=/data/settings
projectsDir:=/data/projects
backupSrcRoot:=/data
backupDest:=/media/ed8/ed-big5/data-backup
distroUbuntu:=trusty
additionRepos:=/etc/apt/sources.list.d/additional-repositories.list

# for SSL certificates
SSL_KEY_NAME:=web
SSL_KEY_PATH:=/etc/ssl/$$USER/${SSL_KEY_NAME}

default:	\
	atom-editor \
	albert-launcher \
	backup \
	browser \
	clean \
	core-utils \
	clipboard-manager \
	docker \
	editor-theme \
	file-management \
	fonts \
	graphic-editor \
	graphic-viewer \
	photo-management \
	kde \
	languages \
	linter \
	monitoring \
	python \
	nodejs yarnpkg \
	utils network security \
	shell bash fish zsh \
	terminal \
	upgrade
	zeal-doc \
	# cfdict

ssl-certificate: ${SSL_KEY_PATH}

brave:
	if ! type brave; then \
		wget -O brave.deb https://laptop-updates.brave.com/latest/mint64;\
		dpkg -i ./brave.deb; \
	fi

chromium:
	apt install --yes chromium-browser

firefox:
	cp config/firefox-next-ppa.pref /etc/apt/preferences.d/
	add-apt-repository --yes ppa:mozillateam/firefox-next
	apt-get update
	apt install --yes firefox

browser: chromium brave firefox

upgrade:
	apt-get update && apt-get --yes upgrade

video:
	apt-get --yes install mplayer smplayer vlc

graphic-editor:
	apt-get --yes install {shutter,libgoo-canvas-perl} inkscape pdfshuffler

graphic-viewer:
	apt-get --yes install \
		okular \
		okular-extra-backends \
		djvulibre-bin \
		pdf2djvu

photo-management:
	add-apt-repository --yes ppa:philip5/extra
	apt-get update
	apt-get install --yes \
		digikam

virtualization:
	apt-get --yes install virtualbox-nonfree virtualbox-guest-utils

monitoring:
	apt-get update
	apt-get --yes install \
		bmon \
		htop \
		nethogs

file-management:
	apt-get update
	add-apt-repository --yes ppa:kubuntu-ppa/backports
	apt-get --yes install \
		dolphin \
		dolphin-plugins \
		kdegraphics-thumbnailers kio-extras kdemultimedia-kio-plugins \
		ncdu \
		tree
	ln -s /usr/lib/x86_64-linux-gnu/plugins/* /usr/lib/x86_64-linux-gnu/qt5/plugins/  # icon bug in KDE

dataviz:
	apt-get --yes install gdal-bin

datamining: nodejs
	npm install --global topojson xml2json-command #json tools
	apt-get --yes install jq gawk jshon visual-regexp

scanner:
	curl --location --silent --output /tmp/scanner.deb https://download.tuxfamily.org/arakhne/ubuntu/pool/universe/libs/libsane-epson-perfection/libsane-epson-perfection-1670_3.0-21arakhne1_all.deb
	dpkg -i /tmp/scanner.deb


scanner-extra:
	apt-get install --yes \
		tesseract-ocr{,-fra} \
		pdfsandwich

audio-encoding:
	apt-get --yes install {libav,opus,vorbis}-tools

network:
	apt-get --yes install \
		whois \
		python-software-properties \
		mosh \
		nmap \
		traceroute

editor-theme:
	if [[ ! -d ${projectsDir}/tomorrow-theme ]]; then git clone --depth 1 https://github.com/chriskempson/tomorrow-theme.git ${projectsDir}/tomorrow-theme; fi
	ln -nfs ${projectsDir}/tomorrow-theme/vim/colors/*.vim $$HOME/.vim/colors/
	if [[ ! -d ${projectsDir}/tomorrow-theme-konsole ]]; then git clone --depth 1 https://github.com/dram/konsole-tomorrow-theme.git ${projectsDir}/tomorrow-theme-konsole; fi
	ln -nfs ${projectsDir}/tomorrow-theme-konsole/*.colorscheme ${settingsDir}/.local/share/konsole/
	ln  -nfs $$HOME/dotfiles/.oh-my-zsh/themes/* $$HOME/.oh-my-zsh/themes/

#@alias: ssl-certificate
# ${SSL_KEY_PATH}.%:
${SSL_KEY_PATH}.%:
	[[ ! -d /etc/ssl/$$USER ]] && mkdir -p "/etc/ssl/$$USER" || true
	openssl req -new -sha256 -x509 -nodes -days 365 -newkey rsa:4096 \
		-keyout $@.key \
		-out 	$@.crt

keepass:
	apt-get --yes install keepass2 mono-dmcs libmono-system-management4.0-cil libmono-system-numerics4.0-cil
	mkdir -p /usr/lib/keepass2/plugins/
	ln -nfs $$HOME/.mozilla/firefox/*201*/extensions/keefox@chris.tomlinson/deps/KeePassRPC.plgx /usr/lib/keepass2/plugins/



security: keepass #ssl-certificate
	apt-get update
	apt-get --yes install \
		gnupg2 \
		gnupg-agent \

cfdict: apache2 nodejs ruby
	apt-get install --yes jshon
	cd $$HOME/.marks/cfdict-client/

python:
	apt-get install --yes \
	python3{,-dev} \
	python3-venv \
	python{,3}-pip \
	python{,3}-setuptools \
	ipython
	pip install wheel
	pip install --upgrade pip

nodejs: yarnpkg
	curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
	apt-get install --yes nodejs
	npm update --global npm
	npm cache clean

linter:
	apt-get install shellcheck

fonts:
	apt-get install --yes \
		fonts-noto{,-cjk} \
		fonts-symbola

core-utils: git terminal shell firefox
	apt-get install --yes \
		vim

git:
	apt-get update
	apt-get --yes install colordiff git{,k,-gui}
	curl --location --silent https://raw.githubusercontent.com/git/git/master/contrib/diff-highlight/diff-highlight > "$$HOME"/apps/diff-highlight

terminal:
	apt-get --yes install \
		curl \
		konsole \
		tmux \
		yakuake

bash:
	echo

fish-plugins:
	curl --location --silent https://raw.githubusercontent.com/justinmayer/tacklebox/master/tools/install.fish | fish
	fish -c 'fisher install  rafaelrinaldi/pure barnybug/docker-fish-completion'

fish:
	add-apt-repository --yes ppa:fish-shell/release-2
	apt-get update
	apt-get install --yes fish grc
	curl --location --silent --output  $$HOME/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
	chown $$SUDO_USER:$$SUDO_USER -R $$HOME/.config/fish/

zsh:
	apt-get install --yes zsh
	curl --location --silent  http://install.ohmyz.sh | sh
	chown $$SUDO_USER:$$SUDO_USER -R $$HOME/.oh-my-zsh

shell: bash fish zsh fish-plugins
	$$HOME/projects/dotfiles/install.sh
	chown $$SUDO_USER:$$SUDO_USER -R $$HOME/
	apt install xrectsel

update-rsync-exclude:
	cp {.,"$$HOME"}/.exclude.rsync;

backup: update-rsync-exclude
	apt-get --yes install {g,}rsync
	update-rc.d rsync defaults
	@backupSrc="${backupSrcRoot}"; \
	backupDest="${backupDest}"; \
	backupList=( "paperwork" "Pictures" "projects" "settings" ); \
	for backupDir in $${backupList[@]}; do \
		(crontab -u ${user} -l ; \
			echo "@daily rsync -r -t -p -o -g -v --progress --size-only -l -H --numeric-ids -s $${backupSrc}/$${backupDir} $${backupDest} --log-file \"$$HOME/rsync.log\" --exclude-from=\"$$HOME/.exclude.rsync\" "; \
		) | crontab -u ${user} - ; \
	done

albert-launcher:
	add-apt-repository --yes ppa:nilarimogard/webupd8
	apt-get update
	apt-get install albert

zeal-doc:
	add-apt-repository --yes ppa:zeal-developers/ppa
	apt-get update
	apt-get install zeal


docker-engine:
	if ! type docker; then \
		apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D; \
		echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list; \
		apt-get update; \
		apt-get install --yes \
			apt-transport-https \
			ca-certificates \
			docker-engine; \
		service docker start; \
		groupadd docker || true; \
		usermod -aG docker $$SUDO_USER; \
	fi


docker-compose:
	curl --location --silent "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" --output /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose

docker: docker-engine docker-compose

atom-editor:
	if ! type atom; then \
		curl --continue-at - --location --output $$HOME/Downloads/atom-amd64.deb https://github.com/atom/atom/releases/download/v1.15.0/atom-amd64.deb \
		&& dpkg --install $$HOME/Downloads/atom-amd64.deb \
	; fi

clipboard-manager:
	apt install clipit

yarnpkg:
	apt-key adv --keyserver pgp.mit.edu --recv D101F7899D41F3C3
	echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
	apt-get update && apt-get install yarn

languages:
	apt-get install --yes \
		ibus{,-pinyin,-qt4} \
		gucharmap

kde-icons:
	apt install --yes \
		breeze \
		gtk3-engines-breeze libreoffice-style-breeze \
		libqt5libqgtk2 \
		systemsettings \
		kde-config-gtk-style \

kde-thumbnail:
	apt install --yes \
		kde-thumbnailer-deb \
		kffmpegthumbnailer \
		thumbnailer-service

kde: kde-icons kde-thumbnail
	apt install --yes \
		kde-runtime \
		kdelibs-bin \
		kdelibs5-data \
		kdelibs5-plugins \

seafile:
	add-apt-repository --yes ppa:seafile/seafile-client
	apt-get update
	apt-get install --yes seafile-gui

syncthing:
	curl --silent https://syncthing.net/release-key.txt | apt-key add -
	echo "deb http://apt.syncthing.net/ syncthing release" | tee /etc/apt/sources.list.d/syncthing.list
	apt-get update
	apt-get install --yes syncthing

sync: seafile syncthing

tribler:
	if ! type tribler &> /dev/null; then \
		curl --location --silent --output /tmp/tribler.deb https://github.com/Tribler/tribler/releases/download/v7.0.0-beta/tribler_7.0.0-beta_all.deb \
		&& dpkg --install /tmp/tribler.deb \
	; fi

torrent: tribler
	apt install --yes \
		deluge{,d,-gtk,-torrent}

clean:
	apt remove \
		pidgin \
		transmission \
		orca \
		hexchat \
		thunderbird
	apt autoremove
	apt autoclean
