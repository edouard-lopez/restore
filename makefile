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
	core-utils \
	clipboard-manager \
	docker \
	editor-theme \
	file-management \
	fonts \
	graphic-editor \
	graphic-viewer \
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


upgrade:
	apt-get update && apt-get --yes upgrade

video:
	apt-get --yes install smplayer vlc

graphic-editor:
	apt-get --yes install {shutter,libgoo-canvas-perl} inkscape pdfshuffler
	
graphic-viewer:
	apt-get --yes install okular djvulibre-bin

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
		ncdu \
		tree 
	
dataviz:
	apt-get --yes install gdal-bin

datamining:
	npm install --global topojson xml2json-command underscore-cli #json tools
	apt-get --yes install jq awk jshon visual-regexp

scanner:
	[[ ! -f ${additionRepos} ]] && touch ${additionRepos} || true
	grep "${distroUbuntu}-arakhne" ${additionRepos} \
		&& echo "deb http://download.tuxfamily.org/arakhne/ubuntu ${distroUbuntu}-arakhne universe" >> ${additionRepos} \
		|| true
	wget -q http://download.tuxfamily.org/arakhne/public2.key -O- | apt-key add -
	apt-get update
	apt-get install --yes libsane-epson-perfection-1670

scanner-extra:
	apt-get install --yes tesseract-ocr{,-fra}

audio-encoding:
	apt-get --yes install {libav,opus,vorbis}-tools

network:
	apt-get --yes install whois python-software-properties mosh nmap

editor-theme:
	if [[ ! -d ${projectsDir}/tomorrow-theme ]]; then git clone --depth 1 https://github.com/chriskempson/tomorrow-theme.git ${projectsDir}/tomorrow-theme; fi
	ln -nfs ${projectsDir}/tomorrow-theme/vim/colors/*.vim $$HOME/.vim/colors/
	if [[ ! -d ${projectsDir}/tomorrow-theme-konsole ]]; then git clone --depth 1 https://github.com/dram/konsole-tomorrow-theme.git ${projectsDir}/tomorrow-theme-konsole; fi
	ln -nfs ${projectsDir}/tomorrow-theme-konsole/*.colorscheme $$HOME/.kde/share/apps/konsole/
	ln  -nfs $$HOME/dotfiles/.oh-my-zsh/themes/* $$HOME/.oh-my-zsh/themes/
	@printf "You need to \n"

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
	wget -c https://raw.github.com/pfn/keepasshttp/master/KeePassHttp.plgx \
		&& cp KeePassHttp.plgx /usr/lib/keepass2/plugins/
	cp "$$HOME"/.mozilla/firefox/*.default/extensions/keefox@chris.tomlinson/deps/KeePassRPC.plgx /usr/lib/keepass2/plugins/

security: keepass #ssl-certificate
	apt-get update
	apt-get --yes install \
		gnupg2 \
		gnupg-agent \

cfdict: apache2 nodejs ruby
	apt-get install --yes jshon
	cd $HOME/.marks/cfdict-client/

# meta task
server-web: php mysql postgres apache2 python nodejs ruby

apache2:
		apt-get --yes install apache2 apache2-utils
		rm /etc/apache2/{sites-available,sites-enabled} -rf
		ln -nfs "${settingsDir}"/apache2/* /etc/apache2/
		mkdir /etc/apache2/sites-enabled
		ln -nfs /etc/apache2/sites-available/* /etc/apache2/sites-enabled/
		a2enmod alias autoindex deflate expires headers include php5 rewrite vhost_alias
		service apache2 restart

python:
	apt-get install --yes ipython python3{,-dev}

nodejs:
	curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
	apt-get install --yes nodejs
	npm update --global npm
	npm cache clean

linter:
	apt-get install shellcheck

fonts:
	apt-get install fonts-noto{,-cjk} fonts-roboto

core-utils: git terminal shell
	add-apt-repository --yes ppa:mozillateam/firefox-next
	apt-get update
	apt-get install --yes firefox

git: 
	apt-get update
	apt-get --yes install colordiff git{,k,-gui}
	curl -Ls https://raw.githubusercontent.com/git/git/master/contrib/diff-highlight/diff-highlight > "$$HOME"/apps/diff-highlight	

terminal: 
	apt-get install \
		curl \
		konsole \
		tmux \
		yakuake
	
bash:
	echo

fish:
	add-apt-repository --yes ppa:fish-shell/release-2
	apt-get update
	apt-get install fish grc
	curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
	fish -c 'fisher install  rafaelrinaldi/pure barnybug/docker-fish-completion'
	curl -L https://raw.githubusercontent.com/justinmayer/tacklebox/master/tools/install.fish | fish

zsh:
	apt-get install zsh
	curl -L http://install.ohmyz.sh | sh

shell: bash fish zsh
	cd $HOME/projects/dotfiles && install.sh

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
	
docker:
	apt-get update
	apt-get install --yes apt-transport-https ca-certificates
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get install docker-engine
	service docker start
	groupadd docker
	usermod -aG docker $SUDO_USER
	curl -L https://github.com/docker/compose/releases/download/1.8.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	
atom-editor:
	curl --location --output ~/Downloads/atom-amd64.deb https://github.com/atom/atom/releases/download/v1.11.2/atom-amd64.deb
	dpkg --install ~/Downloads/atom-amd64.deb
	
clipboard-manager:
	git clone https://github.com/CristianHenzel/ClipIt.git ~/projects/clip-it
	cd clip-it
	./autogen.sh
	./configure
	make
	make install
	
yarnpkg:
	apt-key adv --keyserver pgp.mit.edu --recv D101F7899D41F3C3
	echo "deb http://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
	apt-get update && apt-get install yarn

