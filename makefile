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
distroUbuntu:=xenial
additionRepos:=/etc/apt/sources.list.d/additional-repositories.list

# for SSL certificates
SSL_KEY_NAME:=web
SSL_KEY_PATH:=/etc/ssl/$$USER/${SSL_KEY_NAME}

default:  \
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
	nodejs \
	network security \
	shell \
	terminal \
	xrectsel \
	wallpaper \
	zeal-doc \
	upgrade

ssl-certificate: ${SSL_KEY_PATH}

chromium:
	apt install --yes chromium-browser

firefox:
	cp config/firefox-next-ppa.pref /etc/apt/preferences.d/
	add-apt-repository --yes ppa:mozillateam/firefox-next
	apt-get update
	apt install --yes firefox

browser: chromium firefox

upgrade:
	apt-get update && apt-get --yes upgrade

video:
	apt-get --yes install mplayer smplayer vlc pavucontrol

peek:
	add-apt-repository --yes ppa:peek-developers/stable
	apt update && apt install peek

graphic-editor: peek
	apt-get --yes install {shutter,libgoo-canvas-perl} inkscape pdfshuffler

graphic-viewer:
	apt-get --yes install \
		okular \
		okular-extra-backends \
		djvulibre-bin \
		pdf2djvu

hardware:
	apt-get --yes install \
		imwheel \
		solaar
	curl --location --output ~/apps/imwheel-ui.sh https://goo.gl/49LhhE
	chmod +x ~/apps/imwheel-ui.sh

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
	ln -nfs /usr/lib/x86_64-linux-gnu/plugins/* /usr/lib/x86_64-linux-gnu/qt5/plugins/  # icon bug in KDE

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

editor-theme: terminal
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
		-out   $@.crt

keepass:
	apt-get --yes install keepassx

security: keepass #ssl-certificate
	apt-get update
	apt-get --yes install \
		gnupg2 \
		gnupg-agent \
		kgpg

python:
	apt-get install --yes \
	python3{,-dev} \
	python3-venv \
	python{,3}-pip \
	python{,3}-setuptools \
	ipython
	pip install wheel
	pip install --upgrade pip


npm:
	curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	apt-get install --yes nodejs
	npm update --global npm

nodejs-extra:
	echo "skip"

nodejs: npm yarnpkg nodejs-extra

linter:
	apt-get install shellcheck

fonts:
	apt-get install --yes \
		fonts-noto{,-cjk} \
		fonts-symbola

core-utils: git terminal shell firefox vim

git:
	apt-get update
	apt-get --yes install \
		colordiff \
		pinentry-curses \
		git{,k,-gui}
	curl --location --silent https://raw.githubusercontent.com/git/git/master/contrib/diff-highlight/diff-highlight > "$$HOME"/apps/diff-highlight

terminal: terminal-color terminal-extra
	apt-get --yes install \
		curl \
		konsole \
		tmux \
		yakuake

terminal-color:
	mkdir -p ~/.local/share/konsole
	rm --force --recursive ~/.config/base16-shell
	git clone --depth 1 https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell;

	rm --force --recursive ~/.kde4/apps/konsole/base16-konsole
	git clone --depth 1 https://github.com/cskeeters/base16-konsole.git ~/.kde4/apps/konsole/base16-konsole
	cp ~/.kde4/apps/konsole/base16-konsole/colorscheme/* ~/.local/share/konsole/
	cp ~/.kde4/apps/konsole/base16-konsole/colorscheme/* ~/.kde4/apps/konsole/
	chown $$SUDO_USER:$$SUDO_USER -R ~/.kde4/apps/konsole/

terminal-extra: nodejs
		yarn global add tldr && tldr --update

bash:
	echo

fish-plugins:
	curl --location --silent https://raw.githubusercontent.com/justinmayer/tacklebox/master/tools/install.fish | fish
	fish -c 'fisher install  rafaelrinaldi/pure barnybug/docker-fish-completion transfer fnm'

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

xrectsel:
	if ! type xrectsel; then \
		apt install libx11-dev dh-autoreconf
		git clone https://github.com/lolilolicon/xrectsel.git; \
			cd xrectsel; \
			./bootstrap; \
			./configure --prefix /usr; \
			make; \
			make install; \
	fi

shell-theme:
	mkdir -p ~/.local/share/konsole
	if ! -d ~/.config/base16-shell; then \
		git clone --depth 1 https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell; \
	else \
		pushd  ~/.config/base16-shell; git pull; \
	fi
	if ! -d ~/projects/base16-konsole; then \
		git clone --depth 1 https://github.com/chriskempson/base16-shell.git ~/projects/base16-konsole; \
	else \
		pushd  ~/projects/base16-konsole; git pull; \
		cd base16-konsole/colorscheme/
		cp base16-tomorrow* ~/.local/share/konsole/
		cp base16-tomorrow* ~/.kde4/apps/konsole/
	fi


theme: shell-theme

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
	apt-get remove docker docker-engine docker.io
	if ! type docker; then \
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
 		apt-key fingerprint 0EBFCD88 \
		add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $distroUbuntu stable" \
		apt-get update; \
		apt-get install --yes \
			apt-transport-https \
			ca-certificates \
			docker-ce; \
	fi


docker-compose: python
	sudo pip install docker-compose

docker: docker-engine docker-compose

atom-editor:
	if ! type atom; then \
		curl --continue-at - --location --output $$HOME/Downloads/atom-amd64.deb https://github.com/atom/atom/releases/download/v1.15.0/atom-amd64.deb \
		&& dpkg --install $$HOME/Downloads/atom-amd64.deb \
	; fi

clipboard-manager:
	apt install clipit

yarnpkg: npm
	apt-key adv --keyserver pgp.mit.edu --recv D101F7899D41F3C3
	echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
	apt-get update && apt-get install yarn

languages:
	apt-get install --yes \
		ibus{,-pinyin,-qt4,-gtk,-gtk3} \
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
		curl --location --silent --output /tmp/tribler.deb https://github.com/Tribler/tribler/releases/download/v7.0.0-rc2/tribler_7.0.0-rc2_all.deb \
		&& dpkg --install /tmp/tribler.deb \
	; fi

torrent: tribler
	apt install --yes \
		deluge{,d,-gtk,-torrent}

vim:  # install vim8
	add-apt-repository --yes ppa:jonathonf/vim
	apt-get update
	apt install --yes \
		vim \
		vim-nox  # fix https://github.com/Valloric/YouCompleteMe/issues/1907
	vim +PluginInstall +qall  # install plugins

wallpaper:
	add-apt-repository --yes ppa:peterlevi/ppa
	apt-get update
	apt-get install --yes variety

clean:
	apt remove \
		hexchat \
		libreoffice-{core,common} \
		orca \
		pidgin \
		transmission \
		thunderbird
	apt autoremove
	apt autoclean
