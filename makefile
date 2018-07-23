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
distroUbuntu:=bionic
additionRepos:=/etc/apt/sources.list.d/additional-repositories.list

# for SSL certificates
SSL_KEY_NAME:=web
SSL_KEY_PATH:=/etc/ssl/$$USER/${SSL_KEY_NAME}

default:  \
	core-utils \
	\
	atom-editor \
	albert-launcher \
	backup \
	browser \
	clipboard-manager \
	docker \
	editor-theme \
	file-management \
	fonts \
	graphic-editor \
	graphic-viewer \
	photo-management \
	icons \
	kde \
	languages \
	linter \
	monitoring \
	python \
	nodejs \
	network security \
	shell \
	slack \
	terminal \
	xrectsel \
	wallpaper \
	zeal-doc \
	upgrade \
	clean

ssl-certificate: ${SSL_KEY_PATH}

chromium:
	apt install --yes chromium-browser

firefox:
	cp config/firefox-next-ppa.pref /etc/apt/preferences.d/
	add-apt-repository --yes ppa:mozillateam/firefox-next
	apt update
	apt install --yes firefox

browser: chromium firefox

upgrade:
	apt update && apt upgrade --yes

video:
	add-apt-repository --yes ppa:rvm/smplayer
	apt update
	apt install --yes \
		mplayer \
		smplayer{,-themes,-skins} \
		pavucontrol

peek:
	add-apt-repository --yes ppa:peek-developers/stable
	apt update && apt install --yes peek

graphic-editor: peek
	apt install --yes \
        shutter \
        inkscape \
        pdfshuffler

graphic-viewer:
	apt install --yes \
		okular \
		okular-extra-backends \
		djvulibre-bin \
		pdf2djvu

icons:
	add-apt-repository --yes ppa:papirus/papirus
	add-apt-repository --yes ppa:andreas-angerer89/sni-qt-patched
	apt update
	apt install --yes \
		papirus-icon-theme \
		sni-qt{,:i386} \
		hardcode-tray
	hardcode-tray --conversion-tool RSVGConvert --size 22 --theme Papirus --apply

hardware:
	apt install --yes \
		imwheel \
		solaar
	curl --location --output ~/apps/imwheel-ui.sh https://goo.gl/49LhhE
	chmod +x ~/apps/imwheel-ui.sh

photo-management:
	apt install --yes \
		digikam

virtualization:
	apt install --yes virtualbox-nonfree virtualbox-guest-utils

monitoring:
	apt update
	apt install --yes \
		bmon \
		htop \
		nethogs

file-management:
	apt update
	add-apt-repository --yes ppa:kubuntu-ppa/backports
	apt install --yes \
		ark \
		dolphin \
		dolphin-plugins \
		ffmpegthumbs \
		kdegraphics-thumbnailers kio-extras kdemultimedia-kio-plugins \
		ncdu \
		tree
	ln -nfs /usr/lib/x86_64-linux-gnu/plugins/* /usr/lib/x86_64-linux-gnu/qt5/plugins/  # icon bug in KDE

dataviz:
	apt install --yes gdal-bin

datamining: nodejs
	npm install --global topojson xml2json-command #json tools
	apt install --yes jq gawk jshon visual-regexp

scanner:
	curl --location --silent --output /tmp/scanner.deb https://download.tuxfamily.org/arakhne/ubuntu/pool/universe/libs/libsane-epson-perfection/libsane-epson-perfection-1670_3.0-21arakhne1_all.deb
	dpkg -i /tmp/scanner.deb
	apt install --yes \
		gscan2pdf

scanner-extra:
	apt install --yes \
		tesseract-ocr{,-fra} \
		pdfsandwich

audio-encoding:
	apt install --yes {libav,opus,vorbis}-tools

network:
	apt install --yes \
		whois \
		python-software-properties \
		mosh \
		nmap \
		traceroute

editor-theme: terminal
	if [[ ! -d ${projectsDir}/tomorrow-theme ]]; then git clone --depth 1 https://github.com/chriskempson/tomorrow-theme.git ${projectsDir}/tomorrow-theme; fi
	ln -nfs ${projectsDir}/tomorrow-theme/vim/colors/*.vim $$HOME/.vim/colors/
	if [[ ! -d ${projectsDir}/tomorrow-theme-konsole ]]; then git clone --depth 1 https://github.com/dram/konsole-tomorrow-theme.git ${projectsDir}/tomorrow-theme-konsole; fi
	ln -nfs ${projectsDir}/tomorrow-theme-konsole/*.colorscheme $$HOME/.local/share/konsole/
	ln -nfs $$HOME/dotfiles/.oh-my-zsh/themes/* $$HOME/.oh-my-zsh/themes/

#@alias: ssl-certificate
# ${SSL_KEY_PATH}.%:
${SSL_KEY_PATH}.%:
	[[ ! -d /etc/ssl/$$USER ]] && mkdir -p "/etc/ssl/$$USER" || true
	openssl req -new -sha256 -x509 -nodes -days 365 -newkey rsa:4096 \
		-keyout $@.key \
		-out   $@.crt

keepass:
	apt install --yes keepassx

security: keepass #ssl-certificate
	apt update
	apt install --yes \
		gnupg2 \
		gnupg-agent \
		kgpg

python:
	apt install --yes \
	python3{,-dev} \
	python3-venv \
	python{,3}-pip \
	python{,3}-setuptools \
	ipython
	pip install wheel
	pip install --upgrade pip


npm:
	curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	apt install --yes nodejs
	npm update --global npm

nodejs-extra:
	echo "skip"

nodejs: npm yarnpkg nodejs-extra

linter:
	apt install --yes shellcheck

fonts:
	apt install --yes \
		fonts-noto{,-cjk} \
		fonts-symbola

core-utils: git terminal shell firefox snap vim

git:
	apt update
	apt install --yes \
		colordiff \
		pinentry-gnome3 \
		git{,k,-gui}; \
	curl --location --silent https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy \
        > "$$HOME"/apps/diff-highlight \
        && chown $$SUDO_USER:$$SUDO_USER "$$HOME"/apps/diff-highlight \
        && chmod u+x "$$HOME"/apps/diff-highlight

terminal: terminal-color terminal-extra
	apt install --yes \
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
		yarn global add tldr

bash:
	apt install libreadline7
	cd /lib/x86_64-linux-gnu && ln -nfs libreadline.so.7.0 libreadline.so.6
	add-apt-repository --yes ppa:ultradvorka/ppa
	apt update
	apt install --yes hh

fish-plugins:
	if [[ ! -d $$HOME/.config/fisherman/ ]]; then \
		fish -c 'fisher install rafaelrinaldi/pure barnybug/docker-fish-completion transfer fnm'; \
	fi
	curl \
		--location \
		--silent \
		--output \
		/tmp/tacklebox https://raw.githubusercontent.com/justinmayer/tacklebox/master/tools/install.fish
	fish /tmp/tacklebox &
	chown $$SUDO_USER:$$SUDO_USER -R $$HOME/tacklebox/

fish:
	add-apt-repository --yes ppa:fish-shell/release-2
	apt update
	apt install --yes fish grc
	curl --location --silent --output  $$HOME/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
	chown $$SUDO_USER:$$SUDO_USER -R $$HOME/.config/fish/

zsh:
	apt install --yes zsh
	curl --location --silent  http://install.ohmyz.sh | sh
	chown $$SUDO_USER:$$SUDO_USER -R $$HOME/.oh-my-zsh

shell: bash fish fish-plugins zsh
	$$HOME/projects/dotfiles/install.sh
	chown $$SUDO_USER:$$SUDO_USER -R $$HOME/

xrectsel:
	if ! type xrectsel &> /dev/null; then \
		apt install --yes libx11-dev dh-autoreconf; \
		git clone https://github.com/lolilolicon/xrectsel.git; \
			cd xrectsel; \
			./bootstrap; \
			./configure --prefix /usr; \
			make; \
			make install; \
	fi

shell-theme:
	mkdir -p ~/.local/share/konsole
	if [[ ! -d ~/.config/base16-shell ]]; then \
		git clone --depth 1 https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell; \
	else \
		pushd  ~/.config/base16-shell; git pull; \
	fi
	if [[ ! -d ~/projects/base16-konsole ]]; then \
		git clone --depth 1 https://github.com/chriskempson/base16-shell.git ~/projects/base16-konsole; \
	else \
		pushd  ~/projects/base16-konsole; git pull; \
		cd base16-konsole/colorscheme/; \
		cp base16-tomorrow* ~/.local/share/konsole/; \
		cp base16-tomorrow* ~/.kde4/apps/konsole/; \
	fi


theme: shell-theme

update-rsync-exclude:
	cp {.,"$$HOME"}/.exclude.rsync;

backup: update-rsync-exclude
	apt install --yes {g,}rsync
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
	wget --no-verbose --output-document=/tmp/Release.key https://build.opensuse.org/projects/home:manuelschneid3r/public_key
	apt-key add - < /tmp/Release.key
	echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_18.04/ /' > /etc/apt/sources.list.d/albert.list
	apt update
	apt install --yes albert

zeal-doc:
	apt update
	apt install --yes zeal

docker-engine:
	apt remove --yes docker docker-engine docker.io
	if ! type docker &> /dev/null; then \
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -; \
		apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8; \
		add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${distroUbuntu} stable"; \
		apt update; \
		apt install --yes \
			apt-transport-https \
			ca-certificates \
			docker-ce; \
	fi


docker-compose: python
	sudo pip install docker-compose

docker: docker-engine docker-compose

atom-editor:
	if ! type atom &> /dev/null; then \
		snap install --classic atom; \
	fi

clipboard-manager:
	apt install --yes clipit

yarnpkg: npm
	apt-key adv --keyserver pgp.mit.edu --recv D101F7899D41F3C3
	echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
	apt update && apt install --yes yarn

languages:
	apt install --yes \
		ibus{,-pinyin,-qt4,-gtk,-gtk3} \
		gucharmap

kde-icons:
	apt install --yes \
		kde-config-gtk-style

kde-thumbnail:
	apt install --yes \
		kde-thumbnailer-deb \
		kffmpegthumbnailer 

kde: kde-icons kde-thumbnail
	apt install --yes \
		kde-runtime \
		kdelibs-bin \
		kdelibs5-data \
		kdelibs5-plugins

slack: snap
	if ! type slack &> /dev/null; then \
		snap install slack --classic; \
	fi

snap:
	apt install --yes snapd

syncthing:
	curl --silent https://syncthing.net/release-key.txt | apt-key add -
	echo "deb http://apt.syncthing.net/ syncthing release" | tee /etc/apt/sources.list.d/syncthing.list
	apt update
	apt install --yes syncthing

sync: syncthing

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
	apt update
	apt install --yes \
		vim \
		vim-nox  # fix https://github.com/Valloric/YouCompleteMe/issues/1907
	if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then \
		git clone --depth 1 https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim; \
	else \
		pushd  ~/.vim/bundle/Vundle.vim; git pull; \
	fi
	vim +PluginInstall +qall  # install plugins

wallpaper:
	add-apt-repository --yes ppa:peterlevi/ppa
	apt update
	apt install --yes variety

clean:
	apt remove --yes \
		hexchat \
		libreoffice-{core,common} \
		orca \
		pidgin \
		transmission \
		thunderbird
	apt autoremove --yes
	apt autoclean
